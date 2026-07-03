import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M3-1: deterministic reflection proposes candidates; the Write Gate is
/// the only path to a persistable record; the Store persists. AD-20 gains
/// its first consumer. Trustworthy memory over more memory.
final class ReflectionTests: XCTestCase {
    private var directory: URL!

    private let fullPolicy = WritePolicy(
        requiresAnyOf: [.reusableLater, .affectsArchitecture, .reducesFutureTokens],
        workingContextTTLHours: 24
    )

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-reflection-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    // MARK: Write Gate (pure policy)

    func testGateAdmitsMatchingJustificationWithPolicyTTL() throws {
        let gate = WriteGate(policy: fullPolicy)
        let now = Date()
        let candidate = MemoryCandidate(
            projectID: ProjectID("p1"), content: "useful note", justifications: [.reusableLater]
        )

        let record = try XCTUnwrap(gate.admit(candidate, now: now))
        XCTAssertEqual(record.content, "useful note")
        XCTAssertEqual(record.expiresAt.timeIntervalSince(now), 24 * 3600, accuracy: 1)
    }

    func testGateRejectsWhenPolicyDisabledOrJustificationMissing() {
        let disabled = WriteGate(policy: .disabled)
        let narrow = WriteGate(policy: WritePolicy(requiresAnyOf: [.affectsArchitecture], workingContextTTLHours: 1))
        let candidate = MemoryCandidate(
            projectID: ProjectID("p1"), content: "note", justifications: [.reusableLater]
        )

        XCTAssertNil(disabled.admit(candidate), "Disabled policy admits nothing")
        XCTAssertNil(narrow.admit(candidate), "Justification must match the configured policy")
        XCTAssertNil(WriteGate(policy: fullPolicy).admit(
            MemoryCandidate(projectID: ProjectID("p1"), content: "   ", justifications: [.reusableLater])
        ), "Empty content is never memory")
    }

    // MARK: Reflection (pure, deterministic, no AI)

    func testReflectionProposesOnlyForFreshAIContentWithTopicSignal() {
        let goal = Goal(projectID: ProjectID("p1"), text: "Research thumbnail ideas for cooking channel")

        let candidate = Reflection.candidate(goal: goal, strategy: .ai(skill: nil), deliverablePath: "d/x.md")
        XCTAssertNotNil(candidate)
        XCTAssertEqual(candidate?.justifications, [.reusableLater])
        XCTAssertTrue(candidate?.content.contains("Research thumbnail ideas") ?? false)

        XCTAssertNil(Reflection.candidate(
            goal: Goal(projectID: ProjectID("p1"), text: "hi there"),
            strategy: .ai(skill: nil), deliverablePath: "d/x.md"
        ), "Short goals carry no topic signal — propose nothing")
        XCTAssertNil(Reflection.candidate(
            goal: goal, strategy: .reuse(existing: "x"), deliverablePath: nil
        ), "Reuse already lives on disk")
        XCTAssertNil(Reflection.candidate(
            goal: goal, strategy: .ai(skill: nil), deliverablePath: nil
        ), "No deliverable, nothing to point back to")
    }

    // MARK: End-to-end value loop

    private actor CallCounter {
        private(set) var count = 0
        func increment() { count += 1 }
    }

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

    private func makeKernel(store: FileBackedStore, capture: PromptCapture, policy: WritePolicy) throws -> Kernel {
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
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: store,
            approvalGate: RequireUserApprovalGate(),
            writeGate: WriteGate(policy: policy),
            publish: { _ in }
        )
    }

    func testSuccessfulAIGoalLeavesOneGatedMemory() async throws {
        let store = FileBackedStore(storage: try FileStorage(baseDirectory: directory))
        let kernel = try makeKernel(store: store, capture: PromptCapture(), policy: fullPolicy)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Research thumbnail ideas for cooking channel")
        )

        let records = try await store.workingContext(for: ProjectID("p1"))
        XCTAssertEqual(records.count, 1)
        XCTAssertTrue(records[0].content.contains("Research thumbnail ideas"))
        XCTAssertTrue(records[0].id.hasPrefix("reflection-"))
    }

    /// The point of it all: a RELATED (not identical) goal later benefits —
    /// the reflected memory enters the next prompt via Gateway retrieval.
    func testReflectedMemoryFeedsRelatedGoalContext() async throws {
        let store = FileBackedStore(storage: try FileStorage(baseDirectory: directory))
        let capture = PromptCapture()
        let kernel = try makeKernel(store: store, capture: capture, policy: fullPolicy)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Research thumbnail ideas for cooking channel")
        )
        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Write catchy thumbnail captions for cooking videos")
        )

        let secondPrompt = try XCTUnwrap(capture.prompts.last)
        XCTAssertTrue(
            secondPrompt.contains("Recently completed: Research thumbnail ideas"),
            "Reflected memory must reach the related goal's context"
        )
        XCTAssertTrue(secondPrompt.contains("### Current working context"))
    }

    func testDisabledPolicyWritesNothing() async throws {
        let store = FileBackedStore(storage: try FileStorage(baseDirectory: directory))
        let kernel = try makeKernel(store: store, capture: PromptCapture(), policy: .disabled)

        _ = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Research thumbnail ideas for cooking channel")
        )

        let records = try await store.workingContext(for: ProjectID("p1"))
        XCTAssertTrue(records.isEmpty, "No gate admission, no memory — no bypass exists")
    }
}
