import XCTest
@testable import OsirisApplication
import OsirisCore
import OsirisInfrastructure

/// M2-4: the dashboard is session-level operational awareness — metrics via
/// the Gateway's onMetrics seam (AD-39), activity via execution events.
final class DashboardTests: XCTestCase {
    private func makeMetrics(
        tokensIn: Int? = 100, tokensOut: Int? = 50,
        estimated: Int = 80, cost: Double = 0.001, cacheHit: Bool = false
    ) -> AIRequestMetrics {
        AIRequestMetrics(
            requestID: UUID(), providerID: "test", modelID: "m1",
            latencySeconds: 0.1, estimatedTokensIn: estimated,
            actualTokensIn: tokensIn, actualTokensOut: tokensOut,
            costUSD: cost, cacheHit: cacheHit, retryCount: 0, dryRun: false,
            succeeded: true
        )
    }

    private func makeModel(state: ProjectState? = nil, connected: Bool = false) -> DashboardModel {
        DashboardModel(
            stateFor: { _ in state },
            providerConnected: { connected }
        )
    }

    func testMetricsAccumulateWithEstimatedFallback() async {
        let model = makeModel()
        model.recordMetrics(makeMetrics(tokensIn: 100, tokensOut: 50, cost: 0.001))
        model.recordMetrics(makeMetrics(tokensIn: nil, tokensOut: nil, estimated: 30, cost: 0, cacheHit: true))

        let usage = await model.snapshot(projectID: "p1").usage
        XCTAssertEqual(usage.requests, 2)
        XCTAssertEqual(usage.tokensIn, 130, "Falls back to estimated when actual is missing")
        XCTAssertEqual(usage.tokensOut, 50)
        XCTAssertEqual(usage.costUSD, 0.001, accuracy: 0.000001)
        XCTAssertEqual(usage.cacheHits, 1)
    }

    func testActivityIsNewestFirstAndCapped() async {
        let model = makeModel()
        for _ in 0..<6 {
            model.recordEvent(.understanding)
            model.recordEvent(.completed)
        }
        model.recordEvent(.planning)

        let activity = await model.snapshot(projectID: "p1").recentActivity
        XCTAssertEqual(activity.count, 10, "Capped — a status strip, not a log")
        XCTAssertEqual(activity.first, "Planning…", "Newest first")
        XCTAssertTrue(activity.contains("Completed"), "Terminal events get their own lines")
    }

    func testSnapshotReadsProjectStateAndProviderStatus() async {
        var state = ProjectState(projectID: ProjectID("p1"), name: "YouTube Q3")
        state.recordCompletion(of: "research thumbnails")

        let snapshot = await makeModel(state: state, connected: true).snapshot(projectID: "p1")

        XCTAssertEqual(snapshot.projectName, "YouTube Q3")
        XCTAssertEqual(snapshot.lastCompletedTask, "research thumbnails")
        XCTAssertEqual(snapshot.completedCount, 1)
        XCTAssertTrue(snapshot.providerConnected)
    }

    func testMissingStateIsSafe() async {
        let snapshot = await makeModel(state: nil).snapshot(projectID: "ghost")

        XCTAssertEqual(snapshot.projectName, "ghost")
        XCTAssertNil(snapshot.currentGoal)
        XCTAssertEqual(snapshot.completedCount, 0)
    }

    // The Gateway seam fires for every measured request, including cache hits.
    func testGatewayOnMetricsSeamFires() async throws {
        let model = makeModel()
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "m1",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 1),
                retry: .none,
                preamble: "",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            logger: ConsoleLogger(),
            onMetrics: { model.recordMetrics($0) }
        )

        _ = try await gateway.complete(AIRequest(task: "hello"))
        _ = try await gateway.complete(AIRequest(task: "hello"))

        let usage = await model.snapshot(projectID: "p1").usage
        XCTAssertEqual(usage.requests, 2, "Cache hits are measured too")
        XCTAssertEqual(usage.cacheHits, 1)
    }
}
