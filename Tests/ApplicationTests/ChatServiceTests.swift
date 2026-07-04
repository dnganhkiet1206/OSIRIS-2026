import XCTest
@testable import OsirisApplication
import OsirisCore
import OsirisInfrastructure

final class ChatServiceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-chatservice-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    /// Collects updates thread-safely for assertions.
    private final class UpdateCollector: @unchecked Sendable {
        private let lock = NSLock()
        private var _updates: [TaskUpdate] = []
        var updates: [TaskUpdate] {
            lock.lock(); defer { lock.unlock() }
            return _updates
        }
        func append(_ update: TaskUpdate) {
            lock.lock(); defer { lock.unlock() }
            _updates.append(update)
        }
    }

    private func makeConfiguredService() throws -> ChatService {
        let service = ChatService()
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "m1",
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
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { [weak service] event in service?.relay(event) }
        )
        service.configure(kernel: kernel)
        return service
    }

    // Full flow: activities stream in, then a terminal completed update.
    func testSubmitReportsActivitiesThenCompletion() async throws {
        let service = try makeConfiguredService()
        let collector = UpdateCollector()

        await service.submit(goal: "Draft a plan", projectID: "p1", onUpdate: { collector.append($0) })

        let updates = collector.updates
        let activities = updates.filter { if case .activity = $0.kind { return true }; return false }
        XCTAssertFalse(activities.isEmpty, "UI must see progress activity")
        guard case .completed(let result) = updates.last?.kind else {
            return XCTFail("Last update must be terminal completed, got \(String(describing: updates.last))")
        }
        XCTAssertFalse(result.isEmpty)
    }

    // Vague goal becomes a friendly question — never an error dump.
    func testVagueGoalBecomesClarificationQuestion() async throws {
        let service = try makeConfiguredService()
        let collector = UpdateCollector()

        await service.submit(goal: "   ", projectID: "p1", onUpdate: { collector.append($0) })

        guard case .needsClarification(let question) = collector.updates.last?.kind else {
            return XCTFail("Expected needsClarification, got \(String(describing: collector.updates.last))")
        }
        XCTAssertFalse(question.isEmpty)
        XCTAssertFalse(question.contains("Error"), "Question must be user-facing, not a raw error")
    }

    // Gateway errors are translated per the UI contract — no type names leak.
    func testGatewayErrorsTranslateToFriendlyMessages() {
        let message = ChatService.translate(AIGatewayError.tokenBudgetExceeded(estimated: 9000, limit: 8000))
        XCTAssertFalse(message.contains("AIGatewayError"))
        XCTAssertFalse(message.contains("tokenBudgetExceeded"))
        XCTAssertTrue(message.lowercased().contains("try"), "Message must include a next step")

        let providerMessage = ChatService.translate(AIGatewayError.providerFailed(attempts: 2, lastError: "boom"))
        XCTAssertFalse(providerMessage.contains("boom"), "Internal error strings never reach the UI")
    }

    // Project Isolation holds at the Application boundary: goals land in
    // the project the UI selected, never in each other's state.
    func testGoalsLandInTheirOwnProjects() async throws {
        let service = try makeConfiguredService()
        let store = FileBackedStore(storage: try FileStorage(baseDirectory: directory))

        await service.submit(goal: "goal for alpha", projectID: "alpha", onUpdate: { _ in })
        await service.submit(goal: "goal for beta", projectID: "beta", onUpdate: { _ in })

        let alpha = try await store.projectState(for: ProjectID("alpha"))
        let beta = try await store.projectState(for: ProjectID("beta"))
        XCTAssertEqual(alpha?.completedTasks, ["goal for alpha"])
        XCTAssertEqual(beta?.completedTasks, ["goal for beta"])
    }

    // Terminal events from Core are not double-reported as activities.
    func testTerminalEventsProduceNoActivityText() {
        XCTAssertNil(ChatService.activityText(for: .completed))
        XCTAssertNil(ChatService.activityText(for: .failed("x")))
        XCTAssertNotNil(ChatService.activityText(for: .planning))
    }
}
