import XCTest
import OsirisModules
@testable import OsirisCore
import OsirisInfrastructure

/// Debt fix (logged M5-0, resolved at M6-1 debt sweep): the built-in
/// draft skill used the bare word "viết", a substring of module keywords
/// like "viết kịch bản đầy đủ". A Vietnamese "write full script" goal tied
/// 1-1 and won by id for the generic draft skill instead of the more
/// specific youtube.script-generation. These tests pin the corrected
/// Vietnamese routing so the regression cannot return.
final class VietnameseKeywordPrecedenceTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-vi-precedence-\(UUID().uuidString)")
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
                retry: .none, preamble: "", preambleMaxTokens: 400, dryRun: false
            ),
            logger: ConsoleLogger()
        )
        return Kernel(
            skills: InMemorySkillRegistry(registering: GenericSkills.all + YouTubeModule.manifest.skills),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { _ in }
        )
    }

    private func promptFor(_ goal: String) async throws -> String {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture)
        _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: goal))
        return try XCTUnwrap(capture.prompts.last)
    }

    // The bug: this Vietnamese goal must reach the specific module skill,
    // not the generic draft.
    func testVietnameseFullScriptGoalReachesScriptGeneration() async throws {
        let prompt = try await promptFor("viết kịch bản đầy đủ cho video nấu ăn")
        XCTAssertTrue(prompt.contains("Write the complete, ready-to-record YouTube script"),
                      "A Vietnamese full-script goal must reach youtube.script-generation, not generic draft")
        XCTAssertFalse(prompt.contains("Deliver a complete, immediately usable first"),
                       "It must NOT fall to the generic draft skill")
    }

    // The fix must not cost the draft skill its own Vietnamese goals.
    func testVietnameseWriteArticleGoalStillReachesDraft() async throws {
        let prompt = try await promptFor("viết bài blog về cà phê")
        XCTAssertTrue(prompt.contains("Deliver a complete, immediately usable first"),
                      "'viết bài' still routes to the generic draft skill")
    }

    func testVietnameseComposeGoalStillReachesDraft() async throws {
        let prompt = try await promptFor("soạn email cảm ơn khách hàng")
        XCTAssertTrue(prompt.contains("Deliver a complete, immediately usable first"),
                      "'soạn' still routes to the generic draft skill")
    }

    // A Vietnamese script-outline goal keeps its own skill.
    func testVietnameseScriptOutlineGoalReachesOutline() async throws {
        let prompt = try await promptFor("kịch bản video cho kênh du lịch")
        XCTAssertTrue(prompt.contains("Outline a YouTube video script"),
                      "'kịch bản video' routes to youtube.script-outline")
    }
}
