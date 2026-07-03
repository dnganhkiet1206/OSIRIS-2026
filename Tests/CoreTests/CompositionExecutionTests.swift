import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M1-3: compositions are data (SkillDefinition.compositionSteps, AD-36);
/// the Kernel resolves and decides, the Execution Engine runs the steps
/// sequentially and mechanically. Proven via captured prompts and
/// sequence-numbered provider outputs.
final class CompositionExecutionTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-composition-test-\(UUID().uuidString)")
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
        func record(_ prompt: String) -> Int {
            lock.lock(); defer { lock.unlock() }
            _prompts.append(prompt)
            return _prompts.count
        }
    }

    /// Returns "step-output-N" so chaining order is provable.
    private struct SequencedProvider: AIProvider {
        let id = "sequenced"
        let capture: PromptCapture

        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            let n = capture.record(prompt)
            return ProviderResponse(text: "step-output-\(n)", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeKernel(capture: PromptCapture, skills: [SkillDefinition]) throws -> Kernel {
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
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            approvalGate: RequireUserApprovalGate(),
            publish: { _ in }
        )
    }

    // Multi-keyword goal selects the composition; steps run in declared
    // order; step 1's output feeds step 2; deliverable = last output.
    func testCompositionChainsStepsInDeclaredOrder() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: GenericSkills.all)

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Research morning routines and draft a post")
        )

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2, "Two steps, two measured Gateway calls")
        XCTAssertTrue(prompts[0].contains("structured research outline"), "Step 1 uses the research template")
        XCTAssertTrue(prompts[0].contains("Research morning routines and draft a post"))
        XCTAssertTrue(prompts[1].contains("Draft the following"), "Step 2 uses the draft template")
        XCTAssertTrue(prompts[1].contains("Result of the previous step:\nstep-output-1"), "Step 1 output feeds step 2")
        XCTAssertEqual(deliverable.content, "step-output-2", "Deliverable is the LAST step's output")
        XCTAssertNotNil(deliverable.filePath, "Composition results persist like any deliverable")
    }

    // Single-keyword goal still prefers the single skill (tie-break by id).
    func testSingleKeywordGoalPrefersSingleSkill() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: GenericSkills.all)

        _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "research quantum computing"))

        XCTAssertEqual(capture.prompts.count, 1, "No composition — exactly one call")
        XCTAssertTrue(capture.prompts[0].contains("structured research outline"))
    }

    // A composition with an unresolvable step degrades to plain AI.
    func testUnresolvableStepDegradesToPlainAI() async throws {
        let broken = SkillDefinition(
            id: SkillID("core.broken-chain"),
            version: "1.0.0",
            capabilityTags: [CapabilityTag("x")],
            purpose: "Chain with a missing step",
            inputs: ["goal"],
            outputs: ["out"],
            compositionSteps: [SkillID("does.not.exist")],
            triggerKeywords: ["chainword"]
        )
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: [broken])

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "do the chainword thing")
        )

        XCTAssertEqual(capture.prompts.count, 1)
        XCTAssertEqual(capture.prompts[0], "do the chainword thing", "Degrades to the plain prompt — goal still completes")
        XCTAssertFalse(deliverable.content.isEmpty)
    }
}
