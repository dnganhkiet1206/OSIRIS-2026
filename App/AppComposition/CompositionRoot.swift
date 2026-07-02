import Foundation
import OsirisCore
import OsirisInfrastructure

/// The single place where the object graph is wired (composition root).
/// Nothing else constructs Core components directly. Behavior comes from
/// Config/ (Configuration First) — no model IDs or prompts in code.
///
/// Missing bundled Config resources mean a broken install; this layer fails
/// fast with a clear message rather than running misconfigured.
enum CompositionRoot {
    static func makeKernel() -> Kernel {
        let logger = ConsoleLogger()
        let config = makeConfigurationLoader()
        let routing = loadRouting(from: config)
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            preamble: loadPreamble(from: config),
            defaultModelID: routing.defaultModelID,
            logger: logger
        )
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: makeStore(),
            approvalGate: RequireUserApprovalGate(),
            events: EventBus<ExecutionEvent>()
        )
    }

    // MARK: Configuration

    /// Local mirror of Config/routing.json. Promoted into Core when the
    /// Gateway consumes routing directly (M0-3).
    private struct RoutingConfiguration: Decodable {
        let defaultModelID: String
    }

    private static func makeConfigurationLoader() -> ConfigurationLoader {
        guard let resourceURL = Bundle.main.resourceURL else {
            fatalError("App bundle has no resource directory")
        }
        return ConfigurationLoader(directory: resourceURL.appendingPathComponent("Config", isDirectory: true))
    }

    private static func loadRouting(from config: ConfigurationLoader) -> RoutingConfiguration {
        do {
            return try config.loadJSON(RoutingConfiguration.self, file: "routing.json")
        } catch {
            fatalError("Config/routing.json missing or invalid: \(error)")
        }
    }

    private static func loadPreamble(from config: ConfigurationLoader) -> String {
        do {
            return try config.loadText(file: "preamble.md")
        } catch {
            fatalError("Config/preamble.md missing or invalid: \(error)")
        }
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
