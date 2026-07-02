import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M0-4B: the reuse loop closes — the system remembers and reuses its own
/// results. Deliverables are files written only by the Store (AD-32),
/// indexed in ProjectState (AD-10).
final class DeliverablePersistenceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-deliverable-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private actor CallCounter {
        private(set) var count = 0
        func increment() { count += 1 }
    }

    private struct CountingProvider: AIProvider {
        let id = "counting"
        let counter: CallCounter

        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            await counter.increment()
            return ProviderResponse(text: "generated answer", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    private func makeKernel(counter: CallCounter, store: FileBackedStore) throws -> Kernel {
        let gateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
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
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: store,
            approvalGate: RequireUserApprovalGate(),
            publish: { _ in }
        )
    }

    // (a) A fresh goal produces a deliverable file on disk, indexed in state.
    func testDeliverableIsPersistedAndIndexed() async throws {
        let store = try makeStore()
        let kernel = try makeKernel(counter: CallCounter(), store: store)
        let projectID = ProjectID("p1")

        let deliverable = try await kernel.handle(Goal(projectID: projectID, text: "research topic X"))

        let path = try XCTUnwrap(deliverable.filePath)
        let state = try await store.projectState(for: projectID)
        XCTAssertEqual(state?.deliverablePaths, [path])

        let stored = try await store.deliverableContent(at: path)
        XCTAssertEqual(stored, "generated answer", "Front matter must be stripped from reused content")
    }

    // (b) The reuse loop: the same goal a second time costs zero AI calls.
    func testRepeatedGoalIsReusedWithZeroAICalls() async throws {
        let store = try makeStore()
        let counter = CallCounter()
        let kernel = try makeKernel(counter: counter, store: store)
        let goal = Goal(projectID: ProjectID("p1"), text: "research topic X")

        let first = try await kernel.handle(goal)
        let second = try await kernel.handle(goal)

        let calls = await counter.count
        XCTAssertEqual(calls, 1, "Second run must reuse the stored deliverable — zero new AI calls")
        XCTAssertEqual(second.content, first.content)
        XCTAssertNil(second.filePath, "Reuse must not write a duplicate deliverable file")

        let state = try await store.projectState(for: goal.projectID)
        XCTAssertEqual(state?.deliverablePaths.count, 1)
    }

    // (c) Unusual project IDs map to safe file paths.
    func testUnusualProjectIDsProduceSafeDeliverablePaths() async throws {
        let store = try makeStore()
        let weirdID = ProjectID("p/1 ../x")

        let path = try await store.saveDeliverable("content", goal: "goal", for: weirdID)
        let loaded = try await store.deliverableContent(at: path)

        XCTAssertEqual(loaded, "content")
        XCTAssertFalse(path.contains(".."), "Path traversal characters must be encoded")
    }
}
