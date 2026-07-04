import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M1-1: the Kernel selects skills from declared data; the Execution Engine
/// assembles their templates mechanically. Proven by capturing the exact
/// prompt that reaches the provider.
final class SkillSelectionTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-skill-test-\(UUID().uuidString)")
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
            return ProviderResponse(text: "answer", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeKernel(capture: PromptCapture, skills: [SkillDefinition]) throws -> Kernel {
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
            skills: InMemorySkillRegistry(registering: skills),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { _ in }
        )
    }

    // A matching goal runs through the skill's template.
    func testMatchingGoalUsesSkillTemplate() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: GenericSkills.all)

        _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "Summarize the quarterly report"))

        let prompt = try XCTUnwrap(capture.prompts.first)
        XCTAssertTrue(prompt.contains("actionable key points"), "Skill template must shape the prompt")
        XCTAssertTrue(prompt.contains("Request: Summarize the quarterly report"), "{goal} must be substituted")
    }

    // An unmatched goal keeps the exact pre-M1-1 behavior — no regression.
    func testUnmatchedGoalKeepsPlainPrompt() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: GenericSkills.all)

        _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "Plan tomorrow morning"))

        XCTAssertEqual(capture.prompts.first, "Plan tomorrow morning")
    }

    // An empty registry also keeps the plain path (composition without skills).
    func testEmptyRegistryFallsBackToPlainAI() async throws {
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: [])

        _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "Summarize everything"))

        XCTAssertEqual(capture.prompts.first, "Summarize everything")
    }

    // Tie-breaking is deterministic: equal hits resolve by skill id.
    func testTieBreaksDeterministicallyByID() async throws {
        let a = SkillDefinition(
            id: SkillID("a.skill"), version: "1.0.0",
            capabilityTags: [CapabilityTag("x")], purpose: "A",
            inputs: ["goal"], outputs: ["out"],
            promptTemplate: "TEMPLATE-A {goal}", triggerKeywords: ["overlap"]
        )
        let b = SkillDefinition(
            id: SkillID("b.skill"), version: "1.0.0",
            capabilityTags: [CapabilityTag("x")], purpose: "B",
            inputs: ["goal"], outputs: ["out"],
            promptTemplate: "TEMPLATE-B {goal}", triggerKeywords: ["overlap"]
        )
        let capture = PromptCapture()
        let kernel = try makeKernel(capture: capture, skills: [b, a])

        _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "an overlap goal"))

        let prompt = try XCTUnwrap(capture.prompts.first)
        XCTAssertTrue(prompt.contains("TEMPLATE-A"), "Ties resolve by ascending id, regardless of registration order")
    }
}
