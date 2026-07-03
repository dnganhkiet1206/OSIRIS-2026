import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// M4-1: the Idea → Script pipeline proves the Module Contract in a real
/// workflow. Everything runs through the UNCHANGED Kernel/Execution/
/// Gateway lifecycle: compositions are data, steps resolve through the
/// one shared registry — including a built-in step referenced across the
/// namespace boundary by nothing but its ID.
final class YouTubePipelineTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-pipeline-test-\(UUID().uuidString)")
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

    private struct SequencedProvider: AIProvider {
        let id = "sequenced"
        let capture: PromptCapture

        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            let n = capture.record(prompt)
            return ProviderResponse(text: "step-output-\(n)", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeKernel(
        capture: PromptCapture,
        skills: [SkillDefinition],
        scaffold: String? = nil
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

    /// The composition-root recipe: built-ins + module skills, one registry.
    private var allSkills: [SkillDefinition] {
        GenericSkills.all + YouTubeModule.manifest.skills
    }

    // Idea → Script: both steps run in declared order, step 1's ideas feed
    // step 2's script.
    func testIdeaToScriptRunsBothStepsInOrder() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: allSkills)

        let deliverable = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Give me video ideas and write the full script about sourdough baking"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2, "Two steps, two measured Gateway calls")
        XCTAssertTrue(prompts[0].contains("Generate 5 concrete YouTube video ideas"))
        XCTAssertTrue(prompts[1].contains("Write the complete, ready-to-record YouTube script"))
        XCTAssertTrue(prompts[1].contains("Result of the previous step:\nstep-output-1"),
                      "Step 1's ideas must ground step 2's script")
        XCTAssertEqual(deliverable.content, "step-output-2", "The deliverable is the final step's output")
    }

    // Cross-namespace (AD-44): a module composition resolves a BUILT-IN
    // step through the shared registry — by ID alone, no special API.
    func testCrossNamespaceCompositionResolvesBuiltInStep() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: allSkills)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Research sourdough trends and investigate what works, then write the full script"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2)
        XCTAssertTrue(prompts[0].contains("Produce a structured research outline"),
                      "Step 1 must be the BUILT-IN research skill, resolved across the namespace")
        XCTAssertTrue(prompts[1].contains("Write the complete, ready-to-record YouTube script"))
    }

    // Curated unions: a pure script goal must NOT be hijacked into the
    // two-step pipeline — single skill, single AI call.
    func testPureScriptGoalStaysOnSingleSkill() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: allSkills)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Write the full script for a video about sourdough starters"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1, "A single-domain goal costs a single AI call")
        XCTAssertTrue(prompts[0].contains("Write the complete, ready-to-record YouTube script"))
        XCTAssertFalse(prompts[0].contains("video ideas"), "No idea step for a script-only goal")
    }

    func testPureIdeaGoalTieBreaksToSingleSkill() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: allSkills)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Suggest video ideas for my baking channel"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1)
        XCTAssertTrue(prompts[0].contains("Generate 5 concrete YouTube video ideas"))
    }

    // M3-3 scaffold applies to the module pipeline exactly as to built-ins:
    // intermediate step raw, final step structured.
    func testModulePipelineFinalStepGetsScaffold() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(
            capture: capture, skills: allSkills,
            scaffold: "## Executive Summary\n## Next Steps"
        )

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Give me video ideas and write the full script about sourdough baking"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2)
        XCTAssertFalse(prompts[0].contains("## Executive Summary"),
                       "Intermediate module output is raw material")
        XCTAssertTrue(prompts[1].contains("## Executive Summary"),
                      "The module deliverable is scaffolded like any other")
    }

    // A module installed WITHOUT the built-in its composition references:
    // the M1-3 degrade rule holds unchanged — plain AI, goal still done.
    func testCompositionMissingBuiltInStepDegradesToPlainAI() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: YouTubeModule.manifest.skills)

        let deliverable = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Research sourdough trends and investigate what works, then write the full script"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1, "Unresolvable composition degrades to one plain AI call")
        XCTAssertFalse(prompts[0].contains("Produce a structured research outline"))
        XCTAssertFalse(deliverable.content.isEmpty, "The goal still completes")
    }
}
