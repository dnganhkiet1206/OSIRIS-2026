import Foundation
import OsirisApplication
import OsirisCore
import OsirisInfrastructure

/// The single place where the object graph is wired (composition root).
/// Nothing else constructs Core components directly. Behavior comes from
/// Config/ (Configuration First) — no model IDs, prompts or limits in code.
///
/// Missing or invalid bundled Config resources mean a broken install; this
/// layer fails fast with a clear message rather than running misconfigured.
enum CompositionRoot {
    /// Wires the whole graph behind the Application layer (AD-35). The
    /// Kernel publishes progress straight into the service (AD-33); the
    /// Event Bus joins when multiple consumers exist (Dashboard, M2).
    ///
    /// Provider selection is graceful (M0-6): an Anthropic key in the vault
    /// selects the real provider; without one the app keeps working fully
    /// on the offline placeholder. Missing a key is never a crash.
    static func makeChatService() -> ChatService {
        let service = ChatService()
        let logger = ConsoleLogger()
        // ONE store instance shared by Kernel (state/reuse) and Gateway
        // (context retrieval, AD-24) — a second instance would be a second
        // source of truth.
        let store = makeStore()
        let gateway = DefaultAIGateway(
            provider: selectedProvider.provider,
            configuration: makeGatewayConfiguration(defaultModelID: selectedProvider.modelID),
            store: store,
            logger: logger
        )
        let kernel = Kernel(
            skills: InMemorySkillRegistry(registering: GenericSkills.all),
            tools: [CurrentDateTimeTool()],
            engine: DefaultExecutionEngine(gateway: gateway, logger: logger),
            store: store,
            approvalGate: RequireUserApprovalGate(),
            publish: { [weak service] event in service?.relay(event) }
        )
        service.configure(kernel: kernel)
        return service
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
        let aiRetry: AIRetry
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
