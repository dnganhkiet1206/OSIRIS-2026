import Foundation
import OsirisCore
import OsirisInfrastructure

/// The single place where the object graph is wired (composition root).
/// Nothing else constructs Core components directly.
enum CompositionRoot {
    static func makeKernel() -> Kernel {
        let logger = ConsoleLogger()
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            preamble: loadPreamble(),
            defaultModelID: "placeholder-local",
            logger: logger
        )
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: InMemoryStore(),
            approvalGate: RequireUserApprovalGate(),
            events: EventBus<ExecutionEvent>()
        )
    }

    private static func loadPreamble() -> String {
        guard let url = Bundle.main.url(forResource: "preamble", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return ""
        }
        return text
    }
}
