import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// M5-0: TikTok is the second module, built from MODULE_GUIDE.md alone.
/// These tests are the guide's mandatory set (§7): manifest shape,
/// end-to-end through the unchanged lifecycle, precedence, a registry-wide
/// keyword sweep across BOTH modules, and the cross-namespace composition.
final class TikTokModuleTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-tiktok-test-\(UUID().uuidString)")
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

    /// The composition-root recipe: built-ins + BOTH modules, one registry.
    private var allSkills: [SkillDefinition] {
        GenericSkills.all + YouTubeModule.manifest.skills + TikTokModule.manifest.skills
    }

    private func makeKernel(capture: PromptCapture) throws -> Kernel {
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
            skills: InMemorySkillRegistry(registering: allSkills),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            approvalGate: RequireUserApprovalGate(),
            publish: { _ in }
        )
    }

    // §7.1 Manifest shape
    func testManifestSkillsAreNamespacedData() {
        let manifest = TikTokModule.manifest
        XCTAssertEqual(manifest.id.rawValue, "tiktok")
        XCTAssertFalse(manifest.skills.isEmpty)
        for skill in manifest.skills {
            XCTAssertTrue(skill.id.rawValue.hasPrefix("tiktok."), skill.id.rawValue)
            XCTAssertTrue(
                skill.promptTemplate != nil || !(skill.compositionSteps ?? []).isEmpty,
                "A skill is prompt-driven or a composition — \(skill.id.rawValue)"
            )
            XCTAssertNotNil(skill.triggerKeywords)
        }
    }

    // §7.2 End-to-end through the unchanged lifecycle
    func testHookIdeasRunsEndToEnd() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Give me tiktok hooks for a coffee brand"
        ))

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(prompt.contains("Generate 5 scroll-stopping TikTok hook ideas"))
    }

    // §7.3 Precedence: installing TikTok must not disturb YouTube or generics.
    func testTikTokDoesNotHijackYouTubeOrGenericGoals() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Give me video ideas for a cooking channel"
        ))
        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Summarize this earnings report"
        ))

        let prompts = capture.prompts
        XCTAssertTrue(prompts[0].contains("Generate 5 concrete YouTube video ideas"),
                      "YouTube keeps its domain")
        XCTAssertTrue(prompts[1].contains("Summarize the following request"),
                      "Generic skill keeps its domain")
    }

    // §7.3 Pasted trend data drives the trend brief; no fetch, no state.
    func testTrendBriefUsesPastedData() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "tiktok trend analysis: sound A - 2M uses, sound B - 500k uses, #baking rising"
        ))

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(prompt.contains("Analyze the TikTok trend data"))
        XCTAssertTrue(prompt.contains("sound A - 2M uses"), "Pasted data reaches the prompt verbatim")
    }

    // §7.5 Cross-namespace composition: research (built-in) → plan (module).
    func testResearchToPlanChainsBuiltInThenModuleSkill() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Research morning routines and plan tiktok content around them"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2, "Two steps, two Gateway calls")
        XCTAssertTrue(prompts[0].contains("Produce a structured research outline"),
                      "Step 1 is the BUILT-IN research skill, resolved across the namespace")
        XCTAssertTrue(prompts[1].contains("Plan one week of TikTok content"))
        XCTAssertTrue(prompts[1].contains("Result of the previous step:\nstep-output-1"))
    }

    // §7.3 Curated union: a plan-only goal stays on the single skill.
    func testPlanOnlyGoalStaysSingleCall() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "plan tiktok content for next week"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1, "A single-domain goal costs one AI call")
        XCTAssertTrue(prompts[0].contains("Plan one week of TikTok content"))
    }

    // §7.4 Sweep — the ecosystem invariant a NEW module must guarantee: none
    // of its single-skill keywords is a substring of, or contains, any OTHER
    // single skill's or the tool's keywords (across every namespace). This
    // proves TikTok neither hijacks an existing goal nor is hijacked. It does
    // NOT re-police intentional intra-module overlaps that predate TikTok
    // (e.g. YouTube's shared "script"), which that module pins with its own
    // precedence tests. Compositions are exempt — shared keywords ARE their
    // mechanism (MODULE_GUIDE §6).
    func testTikTokSingleSkillKeywordsCollideWithNothing() {
        let isSingle: (SkillDefinition) -> Bool = { ($0.compositionSteps ?? []).isEmpty }
        let mine = TikTokModule.manifest.skills.filter(isSingle)
        let everyoneElse: [(id: String, keywords: [String])] =
            allSkills.filter(isSingle).map { ($0.id.rawValue, $0.triggerKeywords ?? []) }
            + [("tool.current-datetime", CurrentDateTimeTool().triggerKeywords)]

        for skill in mine {
            for keyword in skill.triggerKeywords ?? [] {
                for other in everyoneElse where other.id != skill.id.rawValue {
                    for otherKeyword in other.keywords {
                        XCTAssertFalse(
                            keyword.contains(otherKeyword) || otherKeyword.contains(keyword),
                            "Keyword '\(keyword)' (\(skill.id.rawValue)) overlaps '\(otherKeyword)' (\(other.id)) — precedence must be re-examined"
                        )
                    }
                }
            }
        }
    }
}
