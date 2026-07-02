import XCTest
@testable import OsirisCore
import OsirisInfrastructure

final class KernelTests: XCTestCase {
    func testGoalRunsThroughLifecycleAndPersistsState() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-kernel-test-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = FileBackedStore(storage: try FileStorage(baseDirectory: directory))
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "placeholder-local", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "placeholder-local",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 1),
                retry: .none,
                preamble: "",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            logger: ConsoleLogger()
        )
        let kernel = Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: store,
            approvalGate: RequireUserApprovalGate(),
            events: EventBus<ExecutionEvent>()
        )

        let goal = Goal(projectID: ProjectID("p1"), text: "Say hello")
        let deliverable = try await kernel.handle(goal)

        XCTAssertFalse(deliverable.content.isEmpty)

        let state = try await store.projectState(for: ProjectID("p1"))
        XCTAssertEqual(state?.completedTasks, ["Say hello"])
    }
}
