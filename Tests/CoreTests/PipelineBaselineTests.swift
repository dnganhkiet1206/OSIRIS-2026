import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// Measures the internal pipeline overhead (AD-15 baseline, provider
/// excluded): full five-phase lifecycle with the offline provider, and the
/// reuse path. Numbers are printed for PROJECT_STATE; assertions are
/// deliberately generous — this is a baseline recorder, not a flaky gate.
final class PipelineBaselineTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-baseline-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeKernel() throws -> Kernel {
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: try GatewayConfiguration(
                models: [ModelInfo(id: "placeholder-local", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
                defaultModelID: "placeholder-local",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 1),
                retry: .none,
                preamble: "",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            logger: NoopLogger()
        )
        return Kernel(
            skills: InMemorySkillRegistry(),
            engine: DefaultExecutionEngine(gateway: gateway),
            store: FileBackedStore(storage: try FileStorage(baseDirectory: directory)),
            publish: { _ in }
        )
    }

    private struct NoopLogger: Logging {
        func log(_ event: LogEvent) {}
    }

    func testPipelineOverheadBaseline() async throws {
        let kernel = try makeKernel()
        let projectID = ProjectID("baseline")

        // Warm-up.
        for i in 0..<3 {
            _ = try await kernel.handle(Goal(projectID: projectID, text: "warmup \(i)"))
        }

        // Fresh goals: full lifecycle incl. search miss + deliverable write.
        let runs = 30
        let start = Date()
        for i in 0..<runs {
            _ = try await kernel.handle(Goal(projectID: projectID, text: "fresh goal number \(i)"))
        }
        let meanFresh = Date().timeIntervalSince(start) / Double(runs)

        // Reuse path: same goal repeatedly — zero AI, no new files.
        _ = try await kernel.handle(Goal(projectID: projectID, text: "repeated goal"))
        let reuseStart = Date()
        for _ in 0..<runs {
            _ = try await kernel.handle(Goal(projectID: projectID, text: "repeated goal"))
        }
        let meanReuse = Date().timeIntervalSince(reuseStart) / Double(runs)

        print("BASELINE pipeline-overhead fresh-goal mean: \(String(format: "%.2f", meanFresh * 1000)) ms/request")
        print("BASELINE pipeline-overhead reuse-path mean: \(String(format: "%.2f", meanReuse * 1000)) ms/request")

        // Generous sanity bounds — catches order-of-magnitude regressions only.
        XCTAssertLessThan(meanFresh, 0.5)
        XCTAssertLessThan(meanReuse, 0.5)
    }
}
