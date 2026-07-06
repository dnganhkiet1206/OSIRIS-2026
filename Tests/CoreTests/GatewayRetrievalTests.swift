import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M1-2: the Gateway retrieves relevant context through the Store and
/// assembles it into structured sections under a budget (AD-24). Proven by
/// capturing the exact prompt reaching the provider.
final class GatewayRetrievalTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-retrieval-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private final class PromptCapture: @unchecked Sendable {
        private let lock = NSLock()
        private var _prompts: [String] = []
        var prompts: [String] {
            lock.lock(); defer { lock.unlock() }
            return _prompts
        }
        func record(_ prompt: String) {
            lock.lock(); defer { lock.unlock() }
            _prompts.append(prompt)
        }
    }

    private struct CapturingProvider: AIProvider {
        let id = "capturing"
        let capture: PromptCapture

        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            capture.record(prompt)
            return ProviderResponse(text: "answer", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    private func makeGateway(
        store: FileBackedStore?,
        capture: PromptCapture,
        contextBudgetTokens: Int = 4000
    ) throws -> DefaultAIGateway {
        DefaultAIGateway(
            provider: CapturingProvider(capture: capture),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "m1",
                budget: BudgetPolicy(
                    maxTokensPerRequest: 8000,
                    maxCostPerRequestUSD: 1,
                    contextBudgetTokens: contextBudgetTokens,
                    maxContextSnippets: 3
                ),
                retry: .none,
                preamble: "You are OSIRIS.",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            store: store,
            logger: ConsoleLogger()
        )
    }

    // Relevant knowledge lands in a structured section, full body included.
    func testRelevantKnowledgeEntersPromptAsSection() async throws {
        let store = try makeStore()
        try await store.save(KnowledgeRecord(
            id: "k1",
            topic: "Thumbnail guidelines",
            body: "Thumbnails must use high contrast and at most four words."
        ))
        let capture = PromptCapture()
        let gateway = try makeGateway(store: store, capture: capture)

        let response = try await gateway.complete(
            AIRequest(task: "Design a thumbnail concept", projectID: ProjectID("p1"))
        )

        let prompt = try XCTUnwrap(capture.prompts.first)
        XCTAssertTrue(prompt.contains("## Relevant context"))
        XCTAssertTrue(prompt.contains("### Knowledge"))
        XCTAssertTrue(prompt.contains("high contrast"), "Knowledge BODY (not just topic) must be included")
        XCTAssertTrue(prompt.contains("## Task\nDesign a thumbnail concept"))
        XCTAssertTrue(prompt.hasPrefix("You are OSIRIS."), "Preamble stays first — critical, never trimmed")
        XCTAssertEqual(response.metrics.contextSnippetCount, 1)
    }

    // Context isolation: another project's working context never leaks in.
    func testOtherProjectsContextDoesNotLeak() async throws {
        let store = try makeStore()
        try await store.save(WorkingContextRecord(
            id: "wc-b", projectID: ProjectID("projectB"),
            content: "Secret projectB thumbnail notes",
            expiresAt: Date().addingTimeInterval(3600)
        ))
        let capture = PromptCapture()
        let gateway = try makeGateway(store: store, capture: capture)

        _ = try await gateway.complete(
            AIRequest(task: "Design a thumbnail concept", projectID: ProjectID("projectA"))
        )

        let prompt = try XCTUnwrap(capture.prompts.first)
        XCTAssertFalse(prompt.contains("Secret projectB"), "Project isolation must hold in retrieval")
    }

    // No store / no matches → prompt is exactly the pre-M1-2 shape.
    func testNoContextKeepsPlainPromptShape() async throws {
        let capture = PromptCapture()
        let gateway = try makeGateway(store: nil, capture: capture)

        _ = try await gateway.complete(AIRequest(task: "Plain task", projectID: ProjectID("p1")))

        XCTAssertEqual(capture.prompts.first, "You are OSIRIS.\n\nPlain task")
    }

    // Over budget: whole snippets drop lowest-priority-first; critical parts stay.
    func testBudgetTrimsLowestPriorityFirstAndNeverCritical() async throws {
        let store = try makeStore()
        // Helpful (knowledge) — long; Important (working context) — short.
        try await store.save(KnowledgeRecord(
            id: "k-long", topic: "Thumbnail history",
            body: String(repeating: "thumbnail detail ", count: 60)
        ))
        try await store.save(WorkingContextRecord(
            id: "wc-now", projectID: ProjectID("p1"),
            content: "Currently designing thumbnail for video 7",
            expiresAt: Date().addingTimeInterval(3600)
        ))
        let capture = PromptCapture()
        // Budget fits preamble + task + the short important snippet only.
        let gateway = try makeGateway(store: store, capture: capture, contextBudgetTokens: 60)

        let response = try await gateway.complete(
            AIRequest(task: "Design a thumbnail concept", projectID: ProjectID("p1"))
        )

        let prompt = try XCTUnwrap(capture.prompts.first)
        XCTAssertTrue(prompt.hasPrefix("You are OSIRIS."))
        XCTAssertTrue(prompt.contains("Design a thumbnail concept"), "Task is critical — never trimmed")
        XCTAssertTrue(prompt.contains("video 7"), "Important (working context) survives")
        XCTAssertFalse(prompt.contains("Thumbnail history"), "Helpful (knowledge) is dropped first")
        XCTAssertEqual(response.metrics.contextSnippetCount, 1)
    }

    // Cache safety: changed context must not serve the stale cached answer.
    func testChangedContextInvalidatesCache() async throws {
        let store = try makeStore()
        let capture = PromptCapture()
        let gateway = try makeGateway(store: store, capture: capture)
        let request = AIRequest(task: "Design a thumbnail concept", projectID: ProjectID("p1"))

        let first = try await gateway.complete(request)
        XCTAssertFalse(first.metrics.cacheHit)

        // Same request, same context → cache hit, provider untouched.
        let second = try await gateway.complete(request)
        XCTAssertTrue(second.metrics.cacheHit)
        XCTAssertEqual(capture.prompts.count, 1)

        // Context changes → new key → real call again.
        try await store.save(KnowledgeRecord(
            id: "k-new", topic: "Thumbnail guidelines", body: "New thumbnail rule: bold colors."
        ))
        let third = try await gateway.complete(request)
        XCTAssertFalse(third.metrics.cacheHit, "Changed context must never serve a stale cache entry")
        XCTAssertEqual(capture.prompts.count, 2)
        XCTAssertTrue(try XCTUnwrap(capture.prompts.last).contains("bold colors"))
    }
}
