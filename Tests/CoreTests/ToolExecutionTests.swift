import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M1-4: "AI Is The Last Tool" becomes a permanent test — a goal a
/// deterministic tool can answer costs zero AI requests and zero tokens.
final class ToolExecutionTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-tool-test-\(UUID().uuidString)")
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
            return ProviderResponse(text: "ai answer", tokensIn: 1, tokensOut: 1)
        }
    }

    private struct FailingTool: Tool {
        struct Broken: Error {}
        let id = ToolID("test.failing")
        let triggerKeywords = ["failword"]

        func run(_ input: ToolInput) async throws -> ToolOutput {
            throw Broken()
        }
    }

    private final class RecordingLogger: Logging, @unchecked Sendable {
        private let lock = NSLock()
        private var _events: [LogEvent] = []
        var events: [LogEvent] {
            lock.lock(); defer { lock.unlock() }
            return _events
        }
        func log(_ event: LogEvent) {
            lock.lock(); defer { lock.unlock() }
            _events.append(event)
        }
    }

    private func makeKernel(
        counter: CallCounter,
        tools: [any Tool],
        logger: any Logging = ConsoleLogger()
    ) throws -> Kernel {
        let gateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "m1",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 1),
                retry: .none,
                preamble: "",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            logger: logger
        )
        return Kernel(
            skills: InMemorySkillRegistry(registering: GenericSkills.all),
            tools: tools,
            engine: DefaultExecutionEngine(gateway: gateway, logger: logger),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { _ in }
        )
    }

    // The founding principle, mechanically proven: tool answer = 0 AI calls.
    func testDateGoalUsesToolWithZeroAICalls() async throws {
        let counter = CallCounter()
        let logger = RecordingLogger()
        let fixed = Date(timeIntervalSince1970: 1_782_000_000) // 2026
        let kernel = try makeKernel(
            counter: counter,
            tools: [CurrentDateTimeTool(now: { fixed })],
            logger: logger
        )

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "What is the date today?")
        )

        let calls = await counter.count
        XCTAssertEqual(calls, 0, "AI Is The Last Tool: a tool answer must cost zero AI requests")
        XCTAssertTrue(deliverable.content.contains("2026"))
        XCTAssertNil(deliverable.filePath, "Tool results are not persisted (AD-37) — free to recompute, stale if stored")

        let toolEvent = logger.events.first { $0.message == "tool.run" }
        XCTAssertNotNil(toolEvent, "Tool runs are measured")
        XCTAssertEqual(toolEvent?.metadata["tool"], "core.current-datetime")
        XCTAssertEqual(toolEvent?.metadata["succeeded"], "true")
    }

    // Repeating the goal stays fresh: the tool runs again, still zero AI.
    func testRepeatedDateGoalStaysFreshWithZeroAI() async throws {
        let counter = CallCounter()
        let logger = RecordingLogger()
        let kernel = try makeKernel(counter: counter, tools: [CurrentDateTimeTool()], logger: logger)
        let goal = Goal(projectID: ProjectID("p1"), text: "What is the date today?")

        _ = try await kernel.handle(goal)
        _ = try await kernel.handle(goal)

        let calls = await counter.count
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(
            logger.events.filter { $0.message == "tool.run" }.count, 2,
            "No stale reuse: the tool re-runs (free) instead of serving yesterday's answer"
        )
    }

    // Ordinary goals are never hijacked by tools — narrow keywords.
    func testOrdinaryGoalIsNotHijackedByTool() async throws {
        let counter = CallCounter()
        let kernel = try makeKernel(counter: counter, tools: [CurrentDateTimeTool()])

        let deliverable = try await kernel.handle(
            Goal(projectID: ProjectID("p1"), text: "Plan tomorrow morning")
        )

        let calls = await counter.count
        XCTAssertEqual(calls, 1, "Non-tool goal takes the AI path as before")
        XCTAssertEqual(deliverable.content, "ai answer")
    }

    // A failing tool surfaces a real error and is measured as a failure.
    func testToolFailureSurfacesErrorAndIsMeasured() async throws {
        let counter = CallCounter()
        let logger = RecordingLogger()
        let kernel = try makeKernel(counter: counter, tools: [FailingTool()], logger: logger)

        do {
            _ = try await kernel.handle(Goal(projectID: ProjectID("p1"), text: "do the failword thing"))
            XCTFail("Expected the tool error to propagate")
        } catch {
            // Expected — never a half-finished deliverable.
        }
        let calls = await counter.count
        XCTAssertEqual(calls, 0, "A failing tool must not silently fall through to AI (the Kernel decided tool)")
        XCTAssertTrue(logger.events.contains {
            $0.message == "tool.run" && $0.metadata["succeeded"] == "false"
        })
    }
}
