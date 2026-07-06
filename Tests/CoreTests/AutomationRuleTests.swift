import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M6-1 (AD-47): automation is DATA. An AutomationRule persists through the
/// single Store, survives restart (State Over Chat), and "runs" by feeding
/// its goal into the EXISTING Kernel lifecycle — no automation pipeline,
/// no second execution path.
final class AutomationRuleTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-automation-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    // MARK: Persistence via the single Store

    func testRuleSurvivesRestartAndListsSorted() async throws {
        let first = try makeStore()
        try await first.save(AutomationRule(id: "b", projectID: ProjectID("p1"), goalText: "Write the weekly recap"))
        try await first.save(AutomationRule(id: "a", projectID: ProjectID("p1"), goalText: "Summarize inbox"))

        // A brand-new Store over the same directory = an app restart.
        let restarted = try makeStore()
        let rules = try await restarted.automationRules()
        XCTAssertEqual(rules.map(\.id), ["a", "b"], "Rules survive restart, sorted by id")
        XCTAssertEqual(rules.first?.goalText, "Summarize inbox")
    }

    func testDeleteRemovesRule() async throws {
        let store = try makeStore()
        try await store.save(AutomationRule(id: "r1", projectID: ProjectID("p1"), goalText: "Do a thing"))
        try await store.deleteAutomationRule(id: "r1")
        let rules = try await store.automationRules()
        XCTAssertTrue(rules.isEmpty)
    }

    // MARK: Trigger schema round-trips (defined, not fired — AD-47)

    func testDailyTriggerSchemaRoundTrips() throws {
        let rule = AutomationRule(
            id: "r1", projectID: ProjectID("p1"), goalText: "Daily digest",
            trigger: .daily(hour: 8)
        )
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(AutomationRule.self, from: data)
        XCTAssertEqual(decoded.trigger, .daily(hour: 8))
        XCTAssertEqual(decoded, rule)
    }

    func testDefaultsAreManualAndEnabled() {
        let rule = AutomationRule(id: "r1", projectID: ProjectID("p1"), goalText: "x")
        XCTAssertEqual(rule.trigger, .manual)
        XCTAssertTrue(rule.enabled)
    }

    // MARK: Running a rule reuses the existing Kernel lifecycle

    private actor CallCounter {
        private(set) var count = 0
        func increment() { count += 1 }
    }

    private struct CountingProvider: AIProvider {
        let id = "counting"
        let counter: CallCounter
        func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
            await counter.increment()
            return ProviderResponse(text: "automated answer", tokensIn: 1, tokensOut: 1)
        }
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
            publish: { _ in }
        )
    }

    /// A stored rule's goal, fed to the existing Kernel, produces a real
    /// deliverable — exactly as a typed goal would. This IS "run now": the
    /// composition root's runNow forwards rule.goalText/projectID to the
    /// same path (proven here at the Kernel boundary).
    func testStoredRuleGoalRunsThroughKernel() async throws {
        let store = try makeStore()
        let counter = CallCounter()
        let kernel = try makeKernel(store: store, counter: counter)

        try await store.save(AutomationRule(
            id: "r1", projectID: ProjectID("p1"), goalText: "Draft the launch announcement"
        ))
        let stored = try await store.automationRules()
        let rule = try XCTUnwrap(stored.first)

        let deliverable = try await kernel.handle(
            Goal(projectID: rule.projectID, text: rule.goalText)
        )

        XCTAssertEqual(deliverable.content, "automated answer")
        let calls = await counter.count
        XCTAssertEqual(calls, 1, "Running a rule is one ordinary Kernel run — no second path")
    }
}
