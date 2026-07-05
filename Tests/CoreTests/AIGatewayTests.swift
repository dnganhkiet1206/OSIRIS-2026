import XCTest
@testable import OsirisCore
import OsirisInfrastructure

// MARK: - Test doubles (interface-conformant, no network anywhere)

/// Counts provider invocations — proves cache hits and dry runs never touch
/// the provider.
private actor CallCounter {
    private(set) var count = 0
    func increment() { count += 1 }
}

private struct CountingProvider: AIProvider {
    let id = "counting"
    let counter: CallCounter

    func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
        await counter.increment()
        return ProviderResponse(text: "response for: \(prompt)", tokensIn: 10, tokensOut: 5)
    }
}

/// Fails a fixed number of times, then succeeds — proves declared retry.
private struct FlakyProvider: AIProvider {
    struct TransientError: Error {}
    let id = "flaky"
    let failuresBeforeSuccess: Int
    let counter: CallCounter

    func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
        await counter.increment()
        if await counter.count <= failuresBeforeSuccess {
            throw TransientError()
        }
        return ProviderResponse(text: "recovered", tokensIn: 1, tokensOut: 1)
    }
}

/// Captures log events — proves metrics are logged and contain no prompt text.
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

// MARK: - Tests

final class AIGatewayTests: XCTestCase {
    private func makeConfiguration(
        maxTokens: Int = 8000,
        maxCostUSD: Double = 1.0,
        retryAttempts: Int = 1,
        preamble: String = "",
        dryRun: Bool = false,
        inputCostPer1M: Double = 0
    ) throws -> GatewayConfiguration {
        try GatewayConfiguration(
            models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: inputCostPer1M, outputCostPer1MTokens: 0)],
            defaultModelID: "m1",
            budget: BudgetPolicy(maxTokensPerRequest: maxTokens, maxCostPerRequestUSD: maxCostUSD),
            retry: RetryPolicy(maxAttempts: retryAttempts),
            preamble: preamble,
            preambleMaxTokens: 400,
            dryRun: dryRun
        )
    }

    // 1. Happy path: metrics complete and logged.
    func testSuccessProducesFullMetricsAndLog() async throws {
        let logger = RecordingLogger()
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: try makeConfiguration(),
            logger: logger
        )

        let response = try await gateway.complete(AIRequest(task: "Hello"))

        XCTAssertTrue(response.metrics.succeeded)
        XCTAssertEqual(response.metrics.providerID, "placeholder")
        XCTAssertEqual(response.metrics.modelID, "m1")
        XCTAssertFalse(response.metrics.cacheHit)
        XCTAssertEqual(response.metrics.retryCount, 0)
        XCTAssertGreaterThan(response.metrics.estimatedTokensIn, 0)
        XCTAssertGreaterThanOrEqual(response.metrics.latencySeconds, 0)

        let event = logger.events.first { $0.message == "ai.request" }
        XCTAssertNotNil(event)
        // Metrics only — never prompt content (Prompt Security).
        XCTAssertFalse(event!.metadata.values.contains { $0.contains("Hello") })
    }

    // 2. Cache: identical request served free, provider untouched.
    func testCacheHitSkipsProvider() async throws {
        let counter = CallCounter()
        let gateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try makeConfiguration(),
            logger: RecordingLogger()
        )

        let first = try await gateway.complete(AIRequest(task: "same task"))
        let second = try await gateway.complete(AIRequest(task: "same task"))

        XCTAssertFalse(first.metrics.cacheHit)
        XCTAssertTrue(second.metrics.cacheHit)
        XCTAssertEqual(second.metrics.costUSD, 0)
        XCTAssertEqual(second.text, first.text)
        let calls = await counter.count
        XCTAssertEqual(calls, 1)
    }

    // 3. Token budget: over-limit request rejected before any spend.
    func testTokenBudgetExceededRejectsBeforeProvider() async throws {
        let counter = CallCounter()
        let gateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try makeConfiguration(maxTokens: 10),
            logger: RecordingLogger()
        )

        let longTask = String(repeating: "x", count: 500)
        do {
            _ = try await gateway.complete(AIRequest(task: longTask))
            XCTFail("Expected tokenBudgetExceeded")
        } catch let error as AIGatewayError {
            guard case .tokenBudgetExceeded(_, let limit) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertEqual(limit, 10)
        }
        let calls = await counter.count
        XCTAssertEqual(calls, 0)
    }

    // 4. Cost budget: expensive model rejected before any spend.
    func testCostBudgetExceededRejectsBeforeProvider() async throws {
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            // 1M USD per 1M input tokens => ~1 USD/token; limit 0.001 USD.
            configuration: try makeConfiguration(maxCostUSD: 0.001, inputCostPer1M: 1_000_000),
            logger: RecordingLogger()
        )

        do {
            _ = try await gateway.complete(AIRequest(task: "costly"))
            XCTFail("Expected costBudgetExceeded")
        } catch let error as AIGatewayError {
            guard case .costBudgetExceeded = error else {
                return XCTFail("Wrong error: \(error)")
            }
        }
    }

    // 5. Dry run: full pipeline, metrics logged, provider never called.
    func testDryRunNeverCallsProvider() async throws {
        let counter = CallCounter()
        let logger = RecordingLogger()
        let gateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try makeConfiguration(dryRun: true),
            logger: logger
        )

        let response = try await gateway.complete(AIRequest(task: "simulate"))

        XCTAssertTrue(response.metrics.dryRun)
        XCTAssertTrue(response.metrics.succeeded)
        XCTAssertEqual(response.metrics.costUSD, 0)
        XCTAssertTrue(logger.events.contains { $0.message == "ai.request" })
        let calls = await counter.count
        XCTAssertEqual(calls, 0)
    }

    // 5b. Dry run must NOT poison the cache: a simulated request must never
    // leave "[dry-run] ..." behind to be served as a real answer later. The
    // property lives in a code comment (DefaultAIGateway step 5a); this guards
    // it. Same cache instance shared across a dry-run gateway and a real one,
    // same task, so a leak would surface as a cache hit on the real call.
    func testDryRunDoesNotPoisonCache() async throws {
        let cache = InMemoryResponseCache()
        let counter = CallCounter()

        let dryGateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try makeConfiguration(dryRun: true),
            cache: cache,
            logger: RecordingLogger()
        )
        let dryResponse = try await dryGateway.complete(AIRequest(task: "same task"))
        XCTAssertTrue(dryResponse.text.contains("dry-run"))

        let realGateway = DefaultAIGateway(
            provider: CountingProvider(counter: counter),
            configuration: try makeConfiguration(dryRun: false),
            cache: cache,
            logger: RecordingLogger()
        )
        let realResponse = try await realGateway.complete(AIRequest(task: "same task"))

        XCTAssertFalse(realResponse.metrics.cacheHit, "Dry-run output must not have been cached")
        XCTAssertFalse(realResponse.text.contains("dry-run"), "Real call must return a real answer")
        let calls = await counter.count
        XCTAssertEqual(calls, 1, "Only the real call reaches the provider")
    }

    // 6. Retry: declared policy recovers from transient failure.
    func testRetryRecoversWithinDeclaredPolicy() async throws {
        let counter = CallCounter()
        let gateway = DefaultAIGateway(
            provider: FlakyProvider(failuresBeforeSuccess: 1, counter: counter),
            configuration: try makeConfiguration(retryAttempts: 2),
            logger: RecordingLogger()
        )

        let response = try await gateway.complete(AIRequest(task: "flaky call"))
        XCTAssertEqual(response.text, "recovered")
        XCTAssertEqual(response.metrics.retryCount, 1)
    }

    // 7. Retry exhausted: clear error, failure measured.
    func testRetryExhaustionThrowsAndLogsFailure() async throws {
        let counter = CallCounter()
        let logger = RecordingLogger()
        let gateway = DefaultAIGateway(
            provider: FlakyProvider(failuresBeforeSuccess: 99, counter: counter),
            configuration: try makeConfiguration(retryAttempts: 2),
            logger: logger
        )

        do {
            _ = try await gateway.complete(AIRequest(task: "always fails"))
            XCTFail("Expected providerFailed")
        } catch let error as AIGatewayError {
            guard case .providerFailed(let attempts, _) = error else {
                return XCTFail("Wrong error: \(error)")
            }
            XCTAssertEqual(attempts, 2)
        }
        let calls = await counter.count
        XCTAssertEqual(calls, 2)
        XCTAssertTrue(logger.events.contains { $0.level == .error && $0.message == "ai.request" })
    }

    // 8. Config validation fails fast at construction.
    func testInvalidConfigurationThrowsAtConstruction() {
        XCTAssertThrowsError(try GatewayConfiguration(
            models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
            defaultModelID: "missing-model",
            budget: BudgetPolicy(maxTokensPerRequest: 100, maxCostPerRequestUSD: 1),
            retry: .none,
            preamble: "",
            preambleMaxTokens: 400,
            dryRun: false
        ))

        // Oversized preamble violates AD-13 and must be rejected.
        XCTAssertThrowsError(try GatewayConfiguration(
            models: [ModelInfo(id: "m1", tier: .light, inputCostPer1MTokens: 0, outputCostPer1MTokens: 0)],
            defaultModelID: "m1",
            budget: BudgetPolicy(maxTokensPerRequest: 100, maxCostPerRequestUSD: 1),
            retry: .none,
            preamble: String(repeating: "long preamble ", count: 500),
            preambleMaxTokens: 400,
            dryRun: false
        ))
    }

    // 9. Empty request rejected.
    func testEmptyTaskRejected() async throws {
        let gateway = DefaultAIGateway(
            provider: PlaceholderAIProvider(),
            configuration: try makeConfiguration(),
            logger: RecordingLogger()
        )

        do {
            _ = try await gateway.complete(AIRequest(task: "   "))
            XCTFail("Expected invalidRequest")
        } catch let error as AIGatewayError {
            guard case .invalidRequest = error else {
                return XCTFail("Wrong error: \(error)")
            }
        }
    }
}
