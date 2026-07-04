import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// M4-2: the publishing package is a DELIVERABLE, not a system — one
/// structured output from the existing pipeline. Standalone it costs one
/// AI call; behind a script it is a two-step composition grounded in the
/// actual script. No publishing/SEO/metadata engine exists to test —
/// that absence is the architecture.
final class PublishingPackageTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-publishing-test-\(UUID().uuidString)")
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
            skills: InMemorySkillRegistry(
                registering: GenericSkills.all + YouTubeModule.manifest.skills
            ),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { _ in }
        )
    }

    // SEO metadata alone: one skill, one AI call, no package hijack.
    func testSeoGoalSelectsSeoSkillOnly() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Create SEO tags and a video description for my sourdough video"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1)
        XCTAssertTrue(prompts[0].contains("Produce the SEO metadata"))
        XCTAssertFalse(prompts[0].contains("ready-to-publish YouTube package"),
                       "Metadata-only goals must not become a package pipeline")
    }

    // Package alone: single-domain goal tie-breaks to the single skill
    // (M4-1 curated-union guideline) — one AI call.
    func testPackageOnlyGoalStaysSingleCall() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Prepare the publishing package for my sourdough video"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1, "A package-only goal costs one AI call")
        XCTAssertTrue(prompts[0].contains("ready-to-publish YouTube package"))
    }

    // Script + package: the two-step pipeline, package grounded in the
    // ACTUAL script via previous-step chaining. The deliverable is the
    // final package.
    func testScriptToPackagePipelineGroundsPackageInScript() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        let deliverable = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: "Write the full script and the publishing package for a sourdough video"
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 2, "Script step, then package step")
        XCTAssertTrue(prompts[0].contains("Write the complete, ready-to-record YouTube script"))
        XCTAssertTrue(prompts[1].contains("ready-to-publish YouTube package"))
        XCTAssertTrue(prompts[1].contains("Result of the previous step:\nstep-output-1"),
                      "The package must be grounded in the actual script")
        XCTAssertEqual(deliverable.content, "step-output-2",
                       "The publishing package IS the deliverable — no extra system")
    }
}
