import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// M4-3 (AD-45): channel analysis works on data the USER provides —
/// no API tool, no OAuth, no module state. The pasted data travels
/// goal → prompt → deliverable through the unchanged lifecycle; the
/// module contract did not move.
final class ChannelAnalysisTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-channel-test-\(UUID().uuidString)")
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
            return ProviderResponse(text: "analysis", tokensIn: 1, tokensOut: 1)
        }
    }

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
            approvalGate: RequireUserApprovalGate(),
            publish: { _ in }
        )
    }

    // Pasted channel data reaches the analysis prompt intact — the goal
    // IS the data source; nothing is fetched, nothing is stored.
    func testPastedChannelDataDrivesAnalysisPrompt() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)

        _ = try await kernel.handle(Goal(
            projectID: ProjectID("p1"),
            text: """
            Channel analysis please: Video A - 12k views, 45% retention. \
            Video B - 2k views, 20% retention. Video C - 30k views, 60% retention.
            """
        ))

        let prompts = capture.prompts
        XCTAssertEqual(prompts.count, 1, "Analysis of provided data is one AI call")
        XCTAssertTrue(prompts[0].contains("Analyze the YouTube channel data"))
        XCTAssertTrue(prompts[0].contains("Video C - 30k views"),
                      "The user's pasted data must reach the prompt verbatim")
    }

    private var channelAnalysis: SkillDefinition {
        YouTubeModule.manifest.skills.first { $0.id.rawValue == "youtube.channel-analysis" }!
    }

    // The analysis tier is earned: the skill declares .standard for real
    // analytical work (AD-42 flows through module data unchanged).
    func testChannelAnalysisDeclaresStandardTier() {
        XCTAssertEqual(channelAnalysis.preferredModelTier, .standard)
    }

    // Keyword overlap sweep: none of the channel-analysis triggers appear
    // in any other registered skill or the date tool — no precedence
    // surprises possible.
    func testChannelAnalysisKeywordsOverlapNothing() {
        let mine = Set(channelAnalysis.triggerKeywords ?? [])
        let others = (GenericSkills.all + YouTubeModule.manifest.skills)
            .filter { $0.id.rawValue != "youtube.channel-analysis" }
            .flatMap { $0.triggerKeywords ?? [] }
            + CurrentDateTimeTool().triggerKeywords

        for keyword in mine {
            for other in others {
                XCTAssertFalse(
                    keyword.contains(other) || other.contains(keyword),
                    "Keyword '\(keyword)' overlaps '\(other)' — precedence must be re-examined"
                )
            }
        }
    }
}
