import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M0-4A: the Decide phase really decides — reuse before AI, ask when vague.
final class KernelDecideTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-decide-test-\(UUID().uuidString)")
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
            return ProviderResponse(text: "ai answer", tokensIn: 1, tokensOut: 1)
        }
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

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    // Reuse hit: existing knowledge answers the goal — zero AI calls.
    func testReuseHitCallsNoProvider() async throws {
        let store = try makeStore()
        try await store.save(KnowledgeRecord(
            id: "k1",
            topic: "Publishing checklist",
            body: "The publishing checklist covers thumbnail, title and SEO."
        ))
        let counter = CallCounter()
        let kernel = try makeKernel(counter: counter, store: store)

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "publishing checklist")
        )

        XCTAssertFalse(deliverable.content.isEmpty)
        let calls = await counter.count
        XCTAssertEqual(calls, 0, "Reuse Before Create: found result must cost zero AI calls")
    }

    // Reuse miss: nothing stored matches — exactly one AI call.
    func testReuseMissCallsProviderOnce() async throws {
        let counter = CallCounter()
        let kernel = try makeKernel(counter: counter, store: try makeStore())

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "something entirely new")
        )

        XCTAssertEqual(deliverable.content, "ai answer")
        let calls = await counter.count
        XCTAssertEqual(calls, 1)
    }

    // Low confidence: vague goal → clarification, never a guess, no AI call.
    func testEmptyGoalAsksForClarification() async throws {
        let counter = CallCounter()
        let kernel = try makeKernel(counter: counter, store: try makeStore())

        do {
            _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "   "))
            XCTFail("Expected needsClarification")
        } catch let error as KernelError {
            guard case .needsClarification = error else {
                return XCTFail("Wrong error: \(error)")
            }
        }
        let calls = await counter.count
        XCTAssertEqual(calls, 0)
    }
}
