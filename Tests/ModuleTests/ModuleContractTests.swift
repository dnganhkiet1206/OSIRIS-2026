import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// M4-0 (AD-44): a module is data behind the Module Contract. These tests
/// prove the whole point of M4: module skills flow through the EXISTING
/// registry, matcher and lifecycle — zero Core changes, zero special
/// casing. If Core ever needs to know a module, these tests break first.
final class ModuleContractTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-module-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: Manifest (pure data)

    func testManifestSkillsAreNamespacedAndDeclared() {
        let manifest = YouTubeModule.manifest
        XCTAssertEqual(manifest.id.rawValue, "youtube")
        XCTAssertFalse(manifest.skills.isEmpty)
        for skill in manifest.skills {
            XCTAssertTrue(
                skill.id.rawValue.hasPrefix("youtube."),
                "Module skills are structurally namespaced — \(skill.id.rawValue)"
            )
            XCTAssertTrue(
                skill.promptTemplate != nil || !(skill.compositionSteps ?? []).isEmpty,
                "Module skills are data: prompt-driven or a declared composition (AD-36) — \(skill.id.rawValue)"
            )
            XCTAssertNotNil(skill.triggerKeywords, "Unmatched skills would be dead data")
        }
    }

    func testModuleSkillsDoNotCollideWithBuiltIns() {
        let builtIn = Set(GenericSkills.all.map(\.id.rawValue))
        let module = Set(YouTubeModule.manifest.skills.map(\.id.rawValue))
        XCTAssertTrue(builtIn.isDisjoint(with: module))
    }

    // MARK: End-to-end through the unchanged Core lifecycle

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
            return ProviderResponse(text: "module answer", tokensIn: 1, tokensOut: 1)
        }
    }

    /// The composition-root recipe: built-ins + module skills into the ONE
    /// registry. No module-aware Core API exists to call — that absence is
    /// the proof.
    private func makeKernel(capture: PromptCapture) throws -> Kernel {
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
            logger: ConsoleLogger()
        )
        return Kernel(
            skills: InMemorySkillRegistry(
                registering: GenericSkills.all + YouTubeModule.manifest.skills
            ),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { _ in }
        )
    }

    func testModuleSkillRunsEndToEnd() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Give me video ideas for a cooking channel")
        )

        XCTAssertEqual(deliverable.content, "module answer")
        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(
            prompt.contains("Generate 5 concrete YouTube video ideas"),
            "The module's declared template must drive the prompt"
        )
    }

    func testGenericSkillsKeepTheirGoals() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Summarize the sponsorship offer email")
        )

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(
            prompt.contains("Summarize the following request"),
            "Installing a module must not hijack goals the built-ins already serve"
        )
    }

    /// Overlapping-phrase precedence (same mechanism compositions use,
    /// M1-3): "video script" hits two youtube keywords, outscoring the
    /// single-keyword generic draft skill — deterministic, no matcher change.
    func testModuleWinsItsDomainByKeywordOverlap() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Draft a video script about sourdough baking")
        )

        let prompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(
            prompt.contains("Outline a YouTube video script"),
            "Two keyword hits (video script + script) must outscore draft's single hit"
        )
    }
}
