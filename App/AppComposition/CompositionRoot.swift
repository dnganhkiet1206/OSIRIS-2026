import Foundation
import OsirisCore
import OsirisInfrastructure

/// The single place where the object graph is wired (composition root).
/// Nothing else constructs Core components directly. Behavior comes from
/// Config/ (Configuration First) — no model IDs, prompts or limits in code.
///
/// Missing or invalid bundled Config resources mean a broken install; this
/// layer fails fast with a clear message rather than running misconfigured.
enum CompositionRoot {
    static func makeKernel() -> Kernel {
        let logger = ConsoleLogger()
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: makeGatewayConfiguration(),
            logger: logger
        )
        // Kernel is pure (AD-33): it publishes progress through a closure;
        // the bus stays an infrastructure detail wired here. The UI
        // subscribes to this bus in M0-5.
        let events = EventBus<ExecutionEvent>()
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: makeStore(),
            approvalGate: RequireUserApprovalGate(),
            publish: { await events.publish($0) }
        )
    }

    // MARK: Configuration

    private struct ModelsFile: Decodable {
        let models: [ModelInfo]
    }

    private struct RoutingFile: Decodable {
        let defaultModelID: String
    }

    private struct BudgetsFile: Decodable {
        let preambleMaxTokens: Int
        let maxTokensPerRequest: Int
        let maxCostPerRequestUSD: Double
    }

    private struct FeaturesFile: Decodable {
        let aiDryRun: Bool
    }

    private struct PoliciesFile: Decodable {
        struct AIRetry: Decodable { let maxAttempts: Int }
        let aiRetry: AIRetry
    }

    private static func makeGatewayConfiguration() -> GatewayConfiguration {
        do {
            let config = makeConfigurationLoader()
            let models = try config.loadJSON(ModelsFile.self, file: "models.json")
            let routing = try config.loadJSON(RoutingFile.self, file: "routing.json")
            let budgets = try config.loadJSON(BudgetsFile.self, file: "budgets.json")
            let features = try config.loadJSON(FeaturesFile.self, file: "features.json")
            let policies = try config.loadJSON(PoliciesFile.self, file: "policies.json")
            return try GatewayConfiguration(
                models: models.models,
                defaultModelID: routing.defaultModelID,
                budget: BudgetPolicy(
                    maxTokensPerRequest: budgets.maxTokensPerRequest,
                    maxCostPerRequestUSD: budgets.maxCostPerRequestUSD
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
