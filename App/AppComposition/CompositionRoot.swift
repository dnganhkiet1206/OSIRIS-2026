import Foundation
import OsirisApplication
import OsirisCore
import OsirisInfrastructure
import OsirisModules

/// The single place where the object graph is wired (composition root).
/// Nothing else constructs Core components directly. Behavior comes from
/// Config/ (Configuration First) — no model IDs, prompts or limits in code.
///
/// Missing or invalid bundled Config resources mean a broken install; this
/// layer fails fast with a clear message rather than running misconfigured.
/// Everything the app shell needs, wired exactly once.
struct AppDependencies {
    let chat: ChatService
    let projects: ProjectDirectory
    let settings: ProviderSettings
    let dashboard: DashboardModel
    /// Read-only skill inventory for the Advanced panel (M2-5).
    let skillList: @Sendable () async -> [SkillInfo]
}

enum CompositionRoot {
    /// Wires the whole graph behind the Application layer (AD-35). The
    /// Kernel publishes progress through its injected closure (AD-33),
    /// fanned out here directly to the two consumers (AD-46).
    ///
    /// Provider selection is graceful (M0-6): an Anthropic key in the vault
    /// selects the real provider; without one the app keeps working fully
    /// on the offline placeholder. Missing a key is never a crash.
    static func makeDependencies() -> AppDependencies {
        let service = ChatService()
        let logger = ConsoleLogger()
        // ONE store instance shared by Kernel (state/reuse), Gateway
        // (context retrieval, AD-24) and the project directory (AD-38) —
        // a second instance would be a second source of truth.
        let store = makeStore()
        let settings = makeProviderSettings()
        let dashboard = DashboardModel(
            stateFor: { try await store.projectState(for: ProjectID($0)) },
            providerConnected: { settings.currentStatus() == .connected }
        )
        let gateway = DefaultAIGateway(
            provider: selectedProvider.provider,
            configuration: makeGatewayConfiguration(defaultModelID: selectedProvider.modelID),
            store: store,
            logger: logger,
            onMetrics: { dashboard.recordMetrics($0) }
        )
        // Modules contribute skills as data through their manifests
        // (AD-44); one registry, one matching algorithm — module skills
        // and built-ins are indistinguishable to the Kernel. This list is
        // the ONLY place that knows which modules are installed.
        let installedModules: [ModuleManifest] = [YouTubeModule.manifest]
        let skillRegistry = InMemorySkillRegistry(
            registering: GenericSkills.all + installedModules.flatMap(\.skills)
        )
        let kernel = Kernel(
            skills: skillRegistry,
            tools: [CurrentDateTimeTool()],
            engine: DefaultExecutionEngine(
                gateway: gateway,
                logger: logger,
                deliverableScaffold: loadDeliverableScaffold()
            ),
            store: store,
            approvalGate: RequireUserApprovalGate(),
            writeGate: WriteGate(policy: makeWritePolicy()),
            // Direct fan-out to the two real consumers (AD-46): the
            // EventBus met its M4 deadline with zero module subscribers —
            // an actor indirection between one producer and two static
            // closures was pure overhead. A future DYNAMIC audience
            // re-earns a bus with evidence, through this same seam.
            publish: { [weak service] event in
                service?.relay(event)
                dashboard.recordEvent(event)
            }
        )
        service.configure(kernel: kernel)
        return AppDependencies(
            chat: service,
            projects: makeProjectDirectory(store: store),
            settings: settings,
            dashboard: dashboard,
            skillList: { await skillRegistry.allSkills().map(SkillInfo.from) }
        )
    }

    /// Project management port (AD-38): state management, not goal
    /// execution — straight onto the Store, the single persister.
    private static func makeProjectDirectory(store: any Store) -> ProjectDirectory {
        ProjectDirectory(
            list: {
                try await store.listProjectStates().map {
                    ProjectSummary(id: $0.projectID.rawValue, name: $0.name)
                }
            },
            create: { name in
                let state = ProjectState(projectID: ProjectID(UUID().uuidString), name: name)
                try await store.save(state)
                return ProjectSummary(id: state.projectID.rawValue, name: state.name)
            },
            overview: { projectID in
                guard let state = try await store.projectState(for: ProjectID(projectID)) else {
                    return nil
                }
                return try await ProjectOverview.assemble(from: state) {
                    try await store.deliverableContent(at: $0)
                }
            },
            deliverableContent: { path in
                try await store.deliverableContent(at: path)
            },
            search: { query in
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return [] }
                let projects = try await store.listProjectStates().map {
                    ProjectSummary(id: $0.projectID.rawValue, name: $0.name)
                }
                let results = try await store.search(StoreQuery(
                    text: trimmed, projectID: nil, limit: 15, matchMode: .anyWord
                ))
                return SearchHit.assemble(query: trimmed, projects: projects, storeResults: results)
            }
        )
    }

    /// Port for the Settings screen (AD-35): closures over the Keychain
    /// vault so neither Presentation nor Application touch Infrastructure.
    static func makeProviderSettings() -> ProviderSettings {
        let vault = KeychainSecretsVault()
        let keyName = anthropicKeyName
        return ProviderSettings(
            currentStatus: {
                let key = (try? vault.secret(for: keyName)) ?? nil
                return (key?.isEmpty == false) ? .connected : .offline
            },
            setKey: { try vault.setSecret($0, for: keyName) },
            removeKey: { try vault.removeSecret(for: keyName) }
        )
    }

    // MARK: Provider selection (AD-31: adapters plug in; the Gateway never changes)

    private static let anthropicKeyName = "anthropic-api-key"

    private static var selectedProvider: (provider: any AIProvider, modelID: String) {
        let config = makeConfigurationLoader()
        let routing = loadRouting(from: config)
        let budgets = loadBudgets(from: config)
        let vault: any SecretsVault = KeychainSecretsVault()
        if let key = try? vault.secret(for: anthropicKeyName), !key.isEmpty {
            return (
                AnthropicProvider(apiKey: key, maxOutputTokens: budgets.perRequestMaxOutputTokens),
                routing.defaultModelID
            )
        }
        return (PlaceholderAIProvider(), routing.offlineModelID)
    }

    // MARK: Configuration

    private struct ModelsFile: Decodable {
        let models: [ModelInfo]
    }

    private struct RoutingFile: Decodable {
        let defaultModelID: String
        let offlineModelID: String
    }

    private struct BudgetsFile: Decodable {
        let preambleMaxTokens: Int
        let maxTokensPerRequest: Int
        let maxCostPerRequestUSD: Double
        let perRequestMaxOutputTokens: Int
        let contextBudgetTokens: Int
        let maxContextSnippets: Int
    }

    private struct FeaturesFile: Decodable {
        let aiDryRun: Bool
    }

    private struct PoliciesFile: Decodable {
        struct AIRetry: Decodable { let maxAttempts: Int }
        struct StoreWriteGate: Decodable { let requiresAnyOf: [String] }
        let aiRetry: AIRetry
        let storeWriteGate: StoreWriteGate
        let workingContextDefaultTTLHours: Double
    }

    /// Write policy from Config (AD-20/41). An unknown justification in the
    /// config is a broken install — fail fast, never silently drop rules.
    private static func makeWritePolicy() -> WritePolicy {
        do {
            let policies = try makeConfigurationLoader().loadJSON(PoliciesFile.self, file: "policies.json")
            let mapped = policies.storeWriteGate.requiresAnyOf.compactMap(WriteJustification.init(rawValue:))
            guard mapped.count == policies.storeWriteGate.requiresAnyOf.count else {
                fatalError("Config/policies.json contains unknown write-gate justifications")
            }
            return WritePolicy(
                requiresAnyOf: mapped,
                workingContextTTLHours: policies.workingContextDefaultTTLHours
            )
        } catch {
            fatalError("Config/policies.json missing or invalid: \(error)")
        }
    }

    /// Deliverable output structure (M3-3) is Config data, like the
    /// preamble — never authored in Core. Editing the shipped file changes
    /// every AI deliverable's shape without touching code.
    private static func loadDeliverableScaffold() -> String {
        do {
            return try makeConfigurationLoader().loadText(file: "deliverable-scaffold.md")
        } catch {
            fatalError("Config/deliverable-scaffold.md missing or invalid: \(error)")
        }
    }

    private static func loadRouting(from config: ConfigurationLoader) -> RoutingFile {
        do {
            return try config.loadJSON(RoutingFile.self, file: "routing.json")
        } catch {
            fatalError("Config/routing.json missing or invalid: \(error)")
        }
    }

    private static func loadBudgets(from config: ConfigurationLoader) -> BudgetsFile {
        do {
            return try config.loadJSON(BudgetsFile.self, file: "budgets.json")
        } catch {
            fatalError("Config/budgets.json missing or invalid: \(error)")
        }
    }

    private static func makeGatewayConfiguration(defaultModelID: String) -> GatewayConfiguration {
        do {
            let config = makeConfigurationLoader()
            let models = try config.loadJSON(ModelsFile.self, file: "models.json")
            let budgets = loadBudgets(from: config)
            let features = try config.loadJSON(FeaturesFile.self, file: "features.json")
            let policies = try config.loadJSON(PoliciesFile.self, file: "policies.json")
            return try GatewayConfiguration(
                models: models.models,
                defaultModelID: defaultModelID,
                budget: BudgetPolicy(
                    maxTokensPerRequest: budgets.maxTokensPerRequest,
                    maxCostPerRequestUSD: budgets.maxCostPerRequestUSD,
                    contextBudgetTokens: budgets.contextBudgetTokens,
                    maxContextSnippets: budgets.maxContextSnippets
                ),
                retry: RetryPolicy(maxAttempts: policies.aiRetry.maxAttempts),
                preamble: try config.loadText(file: "preamble.md"),
                preambleMaxTokens: budgets.preambleMaxTokens,
                dryRun: features.aiDryRun
            )
        } catch {
            fatalError("Config/ missing or invalid: \(error)")
        }
    }

    private static func makeConfigurationLoader() -> ConfigurationLoader {
        guard let resourceURL = Bundle.main.resourceURL else {
            fatalError("App bundle has no resource directory")
        }
        return ConfigurationLoader(directory: resourceURL.appendingPathComponent("Config", isDirectory: true))
    }

    // MARK: Store

    private static func makeStore() -> any Store {
        do {
            let appSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let storage = try FileStorage(
                baseDirectory: appSupport.appendingPathComponent("OsirisStore", isDirectory: true)
            )
            return FileBackedStore(storage: storage)
        } catch {
            fatalError("Cannot initialize local store: \(error)")
        }
    }
}
