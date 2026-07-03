import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M3-3: Executive Summary is not a component — it is a declared output
/// structure (Config data) the Execution Engine appends mechanically to
/// AI deliverables. Proven via captured prompts: every AI path receives
/// the scaffold, intermediate composition steps never do, and no scaffold
/// means byte-identical prompts to pre-M3-3.
final class DeliverableTemplateTests: XCTestCase {
    private var directory: URL!

    private let scaffold = """
    Structure the deliverable exactly as:
    ## Executive Summary
    ## Next Steps
    """

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-template-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: Assembly (pure, mechanical)

    func testAssembleWithoutScaffoldIsUnchanged() {
        XCTAssertEqual(
            DefaultExecutionEngine.assembleTask(template: nil, goal: "goal text", previous: nil),
            "goal text",
            "No scaffold declared, no prompt change — zero regression by construction"
        )
    }

    func testAssembleAppendsScaffoldLast() {
        let task = DefaultExecutionEngine.assembleTask(
            template: "Do: {goal}", goal: "write intro", previous: "earlier", scaffold: scaffold
        )
        XCTAssertTrue(task.hasSuffix(scaffold), "Scaffold is the final section of the task")
        XCTAssertTrue(task.contains("Do: write intro"))
        XCTAssertTrue(task.contains("Result of the previous step:\nearlier"))
    }

    // MARK: Captured prompts through the real pipeline

    private final class PromptCapture: @unchecked Sendable {
        private let lock = NSLock()
        private var _prompts: [String] = []
        var prompts: [String] {
            lock.lock(); defer { lock.unlock() }
            return _prompts
        }
        func record(_ prompt: String) -> Int {
            lock.lock(); defer { lock.unlock() }
            _prompts.append(prompt)
            return _prompts.count
        }
    }

    private struct SequencedProvider: AIProvider {
        let id = "sequenced"
        let capture: PromptCapture

        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            let n = capture.record(prompt)
            return ProviderResponse(text: "step-output-\(n)", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeKernel(
        capture: PromptCapture, skills: [SkillDefinition], scaffold: String?
    ) throws -> Kernel {
        let gateway = DefaultAIGateway(
            provider: SequencedProvider(capture: capture),
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
            skills: InMemorySkillRegistry(registering: skills),
            engine: DefaultExecutionEngine(gateway: gateway, deliverableScaffold: scaffold),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            approvalGate: RequireUserApprovalGate(),
            publish: { _ in }
        )
    }

    // Plain AI path (no skill): the user never needs to know skills exist
    // to get a structured deliverable.
    func testPlainAIPathReceivesScaffold() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: [], scaffold: scaffold)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Plan the next channel milestone")
        )

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(prompt.contains("## Executive Summary"))
        XCTAssertTrue(prompt.contains("## Next Steps"))
    }

    // Skill path: declared template AND declared scaffold — both are data,
    // both reach the prompt.
    func testSkillPathReceivesTemplateAndScaffold() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(
            capture: capture, skills: [GenericSkills.summarize], scaffold: scaffold
        )

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Summarize the retention report findings")
        )

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(prompt.contains("Summarize the following request"), "Skill template present")
        XCTAssertTrue(prompt.contains("## Executive Summary"), "Scaffold present")
    }

    // Composition: intermediate output is raw material, not a deliverable —
    // only the final step is scaffolded.
    func testCompositionScaffoldsOnlyFinalStep() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: GenericSkills.all, scaffold: scaffold)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Research morning routines and draft a post")
        )

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2, "Two steps, two Gateway calls")
        XCTAssertFalse(prompts[0].contains("## Executive Summary"),
                       "Intermediate step must stay unscaffolded")
        XCTAssertTrue(prompts[1].contains("## Executive Summary"),
                      "Final step produces the deliverable — scaffolded")
        XCTAssertTrue(prompts[1].hasSuffix(scaffold), "Scaffold comes after the chained result")
    }

    // Reuse path: stored content is returned verbatim — never re-formatted,
    // never re-sent to AI.
    func testReusePathReturnsStoredContentVerbatim() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: [], scaffold: scaffold)
        let store = FileBackedStore(storage: try FileStorage(baseDirectory: directory))
        try await store.save(KnowledgeRecord(
            id: "k1", topic: "Publishing checklist",
            body: "The publishing checklist covers thumbnail, title and SEO."
        ))

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "publishing checklist")
        )

        XCTAssertEqual(deliverable.content, "The publishing checklist covers thumbnail, title and SEO.")
        XCTAssertTrue(capture.prompts.isEmpty, "Reuse costs zero AI calls — nothing to scaffold")
    }
}
