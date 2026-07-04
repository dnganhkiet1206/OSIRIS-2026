import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// M5-1: Shopify is the third module and the second guide validation — an
/// e-commerce domain unlike the content-creation modules. Built from
/// MODULE_GUIDE.md alone. The mandatory test set (guide §7): manifest,
/// end-to-end, precedence, a registry-wide sweep across THREE modules, and
/// the cross-namespace composition.
final class ShopifyModuleTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-shopify-test-\(UUID().uuidString)")
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

    /// The composition-root recipe: built-ins + ALL THREE modules.
    private var allSkills: [SkillDefinition] {
        GenericSkills.all
            + YouTubeModule.manifest.skills
            + TikTokModule.manifest.skills
            + ShopifyModule.manifest.skills
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
            publish: { _ in }
        )
    }

    // §7.1 Manifest shape
    func testManifestSkillsAreNamespacedData() {
        let manifest = ShopifyModule.manifest
        XCTAssertEqual(manifest.id.rawValue, "shopify")
        XCTAssertFalse(manifest.skills.isEmpty)
        for skill in manifest.skills {
            XCTAssertTrue(skill.id.rawValue.hasPrefix("shopify."), skill.id.rawValue)
            XCTAssertTrue(
                skill.promptTemplate != nil || !(skill.compositionSteps ?? []).isEmpty,
                "A skill is prompt-driven or a composition — \(skill.id.rawValue)"
            )
            XCTAssertNotNil(skill.triggerKeywords)
        }
    }

    // §7.2 End-to-end through the unchanged lifecycle
    func testListingOptimizationRunsEndToEnd() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Write a product listing for a bamboo toothbrush"
        ))

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(prompt.contains("Write an optimized Shopify product listing"))
    }

    // §7.3 Precedence: installing Shopify must not disturb other modules or
    // generics — including the collision-prone word "research".
    func testShopifyDoesNotHijackOtherDomains() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Research morning routines for a blog"
        ))
        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "Give me video ideas for a cooking channel"
        ))

        let prompts = capture.prompts
        XCTAssertTrue(prompts[0].contains("Produce a structured research outline"),
                      "A pure research goal stays on the built-in — Shopify's single skills avoid the word 'research'")
        XCTAssertTrue(prompts[1].contains("Generate 5 concrete YouTube video ideas"),
                      "YouTube keeps its domain")
    }

    // §7.3 Pasted store data drives the analysis; no fetch, no state.
    func testStoreAnalysisUsesPastedData() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "store analysis: 3.2k sessions, 1.1% conversion, $48 AOV last month"
        ))

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(prompt.contains("Analyze the store data"))
        XCTAssertTrue(prompt.contains("1.1% conversion"), "Pasted data reaches the prompt verbatim")
    }

    // §7.5 Cross-namespace composition: research (built-in) → listing (module).
    func testResearchToListingChainsBuiltInThenModuleSkill() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Research the niche and optimize product listing for a yoga mat"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2, "Two steps, two Gateway calls")
        XCTAssertTrue(prompts[0].contains("Produce a structured research outline"),
                      "Step 1 is the BUILT-IN research skill, resolved across the namespace")
        XCTAssertTrue(prompts[1].contains("Write an optimized Shopify product listing"))
        XCTAssertTrue(prompts[1].contains("Result of the previous step:\nstep-output-1"))
    }

    // §7.3 Curated union: a listing-only goal stays on the single skill.
    func testListingOnlyGoalStaysSingleCall() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"), text: "optimize product listing for a water bottle"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1, "A single-domain goal costs one AI call")
        XCTAssertTrue(prompts[0].contains("Write an optimized Shopify product listing"))
    }

    // §7.4 Sweep — the new module hijacks nobody and is hijacked by nobody:
    // no Shopify single-skill keyword contains or is contained by any other
    // skill's or the tool's keyword, across all three modules + generics.
    func testShopifySingleSkillKeywordsCollideWithNothing() {
        let isSingle: (SkillDefinition) -> Bool = { ($0.compositionSteps ?? []).isEmpty }
        let mine = ShopifyModule.manifest.skills.filter(isSingle)
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
