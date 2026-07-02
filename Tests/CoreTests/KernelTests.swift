import XCTest
@testable import OsirisCore
import OsirisInfrastructure

final class KernelTests: XCTestCase {
    func testGoalRunsThroughLifecycleAndPersistsState() async throws {
        let store = InMemoryStore()
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            preamble: "",
            defaultModelID: "placeholder-local",
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
