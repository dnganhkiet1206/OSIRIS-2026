import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M3-2: Smart Planning v1 (AD-42). Complexity is estimated
/// deterministically, tier is earned instead of hardcoded, and Medium
/// confidence gains its first consumer — an assumption written through
/// the SAME Write Gate as every other memory write. No second path.
final class SmartPlanningTests: XCTestCase {
    private var directory: URL!

    private let fullPolicy = WritePolicy(
        requiresAnyOf: [.reusableLater, .affectsArchitecture, .reducesFutureTokens],
        workingContextTTLHours: 24
    )

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-planning-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: Complexity estimate (pure, deterministic)

    func testShortSingleClauseGoalIsSimple() {
        XCTAssertEqual(ComplexityEstimate.estimate(for: "publishing checklist"), .simple)
        XCTAssertEqual(ComplexityEstimate.estimate(for: "Tóm tắt video hôm qua"), .simple)
    }

    func testMediumLengthGoalIsStandard() {
        XCTAssertEqual(ComplexityEstimate.estimate(
            for: "Write a short intro paragraph about our new cooking series launch"
        ), .standard)
    }

    func testBreadthSignalOrManyClausesIsComplex() {
        XCTAssertEqual(ComplexityEstimate.estimate(
            for: "Write a detailed launch plan"
        ), .complex, "Explicit breadth signal wins regardless of length")
        XCTAssertEqual(ComplexityEstimate.estimate(
            for: "Lập kế hoạch toàn diện cho kênh"
        ), .complex, "Vietnamese breadth signal counts too")
        XCTAssertEqual(ComplexityEstimate.estimate(
            for: "Research the topic, draft an outline, then write the script"
        ), .complex, "Three clauses signal a multi-part goal")
    }

    func testEstimateIsDeterministic() {
        let goal = "Draft a launch plan for the channel and schedule the first video"
        let first = ComplexityEstimate.estimate(for: goal)
        for _ in 0..<10 {
            XCTAssertEqual(ComplexityEstimate.estimate(for: goal), first,
                           "Same input must always yield the same estimate")
        }
    }

    func testTierMapping() {
        XCTAssertEqual(ComplexityEstimate.simple.preferredTier, .light)
        XCTAssertEqual(ComplexityEstimate.standard.preferredTier, .light)
        XCTAssertEqual(ComplexityEstimate.complex.preferredTier, .standard)
    }

    // MARK: Plan capture — tier reaches the ExecutionPlan

    /// Test-only engine that records the plan the Kernel hands over. Tests
    /// observe the Kernel's decision at its real boundary instead of
    /// re-deriving it (the only-Kernel-constructs-plans rule scans
    /// production sources; tests only READ plans here).
    private actor RecordingEngine: ExecutionEngine {
        private(set) var plans: [ExecutionPlan] = []

        func run(_ plan: ExecutionPlan) async throws -> ExecutionResult {
            plans.append(plan)
            return ExecutionResult(deliverable: Deliverable(content: "recorded answer"))
        }

        var lastPlan: ExecutionPlan? { plans.last }
    }

    private func makeKernel(
        engine: RecordingEngine,
        store: FileBackedStore,
        skills: [SkillDefinition] = [],
        policy: WritePolicy? = nil
    ) -> Kernel {
        Kernel(
            skills: InMemorySkillRegistry(registering: skills),
            engine: engine,
            store: store,
            approvalGate: RequireUserApprovalGate(),
            writeGate: WriteGate(policy: policy ?? .disabled),
            publish: { _ in }
        )
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    func testComplexGoalEarnsStandardTierOnAIPath() async throws {
        let engine = RecordingEngine()
        let kernel = makeKernel(engine: engine, store: try makeStore())

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Write a detailed content strategy for the cooking channel"
        ))

        let recorded = await engine.lastPlan
        let plan = try XCTUnwrap(recorded)
        XCTAssertEqual(plan.preferredTier, .standard, "Complex estimate must earn the standard tier")
        guard case .ai = plan.strategy else { return XCTFail("Expected the AI path") }
    }

    func testSimpleGoalStaysOnLightTier() async throws {
        let engine = RecordingEngine()
        let kernel = makeKernel(engine: engine, store: try makeStore())

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Suggest one video title"
        ))

        let recorded = await engine.lastPlan
        let plan = try XCTUnwrap(recorded)
        XCTAssertEqual(plan.preferredTier, .light)
    }

    func testSkillDeclaredTierOutranksEstimate() async throws {
        let skill = SkillDefinition(
            id: SkillID("deep-analysis"),
            version: "1.0",
            capabilityTags: [CapabilityTag("analysis")],
            purpose: "Deep analysis",
            inputs: ["topic"],
            outputs: ["analysis"],
            promptTemplate: "Analyze: {{goal}}",
            preferredModelTier: .advanced,
            triggerKeywords: ["analyze"]
        )
        let engine = RecordingEngine()
        let kernel = makeKernel(engine: engine, store: try makeStore(), skills: [skill])

        // A short goal (simple → .light by estimate) matching a skill that
        // declares .advanced: the skill knows its work best.
        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "analyze retention"
        ))

        let recorded = await engine.lastPlan
        let plan = try XCTUnwrap(recorded)
        XCTAssertEqual(plan.preferredTier, .advanced,
                       "A skill's declared tier outranks the estimate")
    }

    func testToolPathIgnoresTier() async throws {
        let engine = RecordingEngine()
        let store = try makeStore()
        let kernel = Kernel(
            skills: InMemorySkillRegistry(),
            tools: [CurrentDateTimeTool()],
            engine: engine,
            store: store,
            approvalGate: RequireUserApprovalGate(),
            publish: { _ in }
        )

        // "detailed" would estimate complex, but the tool path is chosen
        // first — tier stays at its default because no AI runs.
        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "detailed current date please"
        ))

        let recorded = await engine.lastPlan
        let plan = try XCTUnwrap(recorded)
        guard case .tool = plan.strategy else { return XCTFail("Expected the tool path") }
        XCTAssertEqual(plan.preferredTier, .light, "Tier only matters on AI paths")
    }

    // MARK: Confidence Medium — first consumer (assumption via the gate)

    func testVagueGoalWritesAssumptionThroughGate() async throws {
        let engine = RecordingEngine()
        let store = try makeStore()
        let kernel = makeKernel(engine: engine, store: store, policy: fullPolicy)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Improve the channel branding somehow"
        ))

        let records = try await store.workingContext(for: ProjectID("p1"))
        let assumption = try XCTUnwrap(
            records.first { $0.content.hasPrefix("Assumption (medium confidence)") },
            "A vague goal must leave a documented assumption"
        )
        XCTAssertTrue(assumption.content.contains("Improve the channel branding somehow"))
    }

    func testNormalGoalWritesNoAssumption() async throws {
        let engine = RecordingEngine()
        let store = try makeStore()
        let kernel = makeKernel(engine: engine, store: store, policy: fullPolicy)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Suggest one video title"
        ))

        let records = try await store.workingContext(for: ProjectID("p1"))
        XCTAssertFalse(
            records.contains { $0.content.hasPrefix("Assumption") },
            "High confidence must never spam assumptions"
        )
    }

    func testDisabledGateBlocksAssumptionToo() async throws {
        let engine = RecordingEngine()
        let store = try makeStore()
        let kernel = makeKernel(engine: engine, store: store, policy: .disabled)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Improve the channel branding somehow"
        ))

        let records = try await store.workingContext(for: ProjectID("p1"))
        XCTAssertTrue(records.isEmpty,
                      "Assumptions obey the same gate as every write — no bypass")
    }

    /// The value loop: the documented assumption reaches the NEXT related
    /// goal's context through normal Gateway retrieval — zero new seams.
    func testAssumptionFeedsNextGoalContext() async throws {
        let capture = PromptCapture()
        let store = try makeStore()
        let gateway = DefaultAIGateway(
            provider: CapturingProvider(capture: capture),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "m1",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 1),
                retry: .none,
                preamble: "",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            store: store,
            logger: ConsoleLogger()
        )
        let kernel = Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: store,
            approvalGate: RequireUserApprovalGate(),
            writeGate: WriteGate(policy: fullPolicy),
            publish: { _ in }
        )

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Improve the channel branding somehow"
        ))
        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Design a new channel branding banner"
        ))

        let secondPrompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(
            secondPrompt.contains("Assumption (medium confidence)"),
            "The documented assumption must reach the related goal's context"
        )
    }

    // MARK: Test doubles (shared with the value-loop test)

    private final class PromptCapture: @unchecked Sendable {
        private let lock = NSLock()
        private var _prompts: [String] = []
        var prompts: [String] {
            lock.lock(); defer { lock.unlock() }
            return _prompts
        }
        func record(_ p: String) {
            lock.lock(); defer { lock.unlock() }
            _prompts.append(p)
        }
    }

    private struct CapturingProvider: AIProvider {
        let id = "capturing"
        let capture: PromptCapture

        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            capture.record(prompt)
            return ProviderResponse(text: "fresh answer", tokensIn: 1, tokensOut: 1)
        }
    }
}
