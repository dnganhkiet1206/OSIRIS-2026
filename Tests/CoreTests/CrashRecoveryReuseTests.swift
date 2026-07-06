import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M8-3 crash recovery. After a goal completes, re-running it — what a user
/// does after the app is killed mid-goal, or simply by asking again — must
/// reuse the real DELIVERABLE, never a working-context process note that
/// happens to embed the goal text, and must not accumulate duplicate notes.
///
/// This exercises the production write gate (unlike the reuse tests that use
/// the disabled gate): a medium-confidence goal writes an "Assumption …" note
/// and a ≥4-word goal on the AI path writes a "Recently completed …" note —
/// both embed the goal verbatim, both live in working context.
final class CrashRecoveryReuseTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-crash-reuse-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private actor CallCounter {
        private(set) var count = 0
        func increment() { count += 1 }
    }

    private struct CountingProvider: AIProvider {
        let id = "counting"
        let counter: CallCounter
        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            await counter.increment()
            return ProviderResponse(text: "the real deliverable", tokensIn: 1, tokensOut: 1)
        }
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    private func makeKernel(store: FileBackedStore, counter: CallCounter) throws -> Kernel {
        let gateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "m1",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 1),
                retry: .none, preamble: "", preambleMaxTokens: 400, dryRun: false
            ),
            logger: ConsoleLogger()
        )
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: store,
            // Production-shaped gate: the notes actually get written.
            writeGate: WriteGate(policy: WritePolicy(requiresAnyOf: [.reusableLater], workingContextTTLHours: 24)),
            publish: { _ in }
        )
    }

    func testReRunReusesDeliverableNotProcessNoteAndDoesNotDuplicate() async throws {
        let store = try makeStore()
        let counter = CallCounter()
        let kernel = try makeKernel(store: store, counter: counter)
        let projectID = ProjectID("p1")
        // "something" → medium confidence; five words → also a reflection note.
        let goal = Goal(projectID: projectID, text: "write something useful about focus")

        let first = try await kernel.handle(goal)
        XCTAssertEqual(first.content, "the real deliverable")

        // Re-run == crash-then-resubmit. Working context now holds notes that
        // embed the goal; reuse must still return the deliverable.
        let second = try await kernel.handle(goal)
        XCTAssertEqual(
            second.content, "the real deliverable",
            "Reuse must return the real deliverable, never a working-context process note"
        )
        let calls = await counter.count
        XCTAssertEqual(calls, 1, "Reuse hits the deliverable — no re-run, no duplicate deliverable")

        // A completed medium goal documents its assumption once; a reuse
        // re-run must not re-write an identical note (no unbounded duplicates).
        let notes = try await store.workingContext(for: projectID)
        let assumptions = notes.filter { $0.content.hasPrefix("Assumption (medium confidence)") }
        XCTAssertEqual(assumptions.count, 1, "Assumption documented once, not re-written on every re-run")
    }
}
