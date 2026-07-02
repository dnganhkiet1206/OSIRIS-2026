import Foundation
import OsirisInfrastructure

/// The production Gateway. Pipeline for every request:
///
///   validate request → budget check → cache lookup →
///   (dry-run simulation | provider call with declared retry) →
///   metrics + structured log → response
///
/// Configuration is validated at construction (GatewayConfiguration throws),
/// so an operating Gateway is always validly configured. Retry follows the
/// declared RetryPolicy mechanically (AD-25) — no improvised recovery.
/// Logs carry metrics only, never prompt content or secrets.
public struct DefaultAIGateway: AIGateway {
    private let provider: any AIProvider
    private let configuration: GatewayConfiguration
    private let cache: any ResponseCache
    private let logger: any Logging

    public init(
        provider: any AIProvider,
        configuration: GatewayConfiguration,
        cache: any ResponseCache = InMemoryResponseCache(),
        logger: any Logging
    ) {
        self.provider = provider
        self.configuration = configuration
        self.cache = cache
        self.logger = logger
    }

    public func complete(_ request: AIRequest) async throws -> AIResponse {
        let requestID = UUID()
        let start = Date()

        // 1. Validate request — fail fast, cost nothing.
        guard !request.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AIGatewayError.invalidRequest("Task is empty")
        }
        let modelID = configuration.defaultModelID
        // Safe force-unwrap by construction: configuration validated defaultModelID.
        let model = configuration.model(withID: modelID)!
        let prompt = assemblePrompt(for: request)
        let estimatedTokens = TokenEstimator.estimate(prompt)

        // 2. Budget — a rejected request costs nothing.
        guard estimatedTokens <= configuration.budget.maxTokensPerRequest else {
            throw AIGatewayError.tokenBudgetExceeded(
                estimated: estimatedTokens, limit: configuration.budget.maxTokensPerRequest
            )
        }
        let estimatedCost = cost(inputTokens: estimatedTokens, outputTokens: 0, model: model)
        guard estimatedCost <= configuration.budget.maxCostPerRequestUSD else {
            throw AIGatewayError.costBudgetExceeded(
                estimatedUSD: estimatedCost, limitUSD: configuration.budget.maxCostPerRequestUSD
            )
        }

        // 3. Cache — a hit is free (Reuse Before Create).
        let cacheKey = "\(modelID)\n\(prompt)"
        if let cached = await cache.response(for: cacheKey) {
            let metrics = makeMetrics(
                requestID: requestID, modelID: modelID, start: start,
                estimatedTokens: estimatedTokens, response: nil, costUSD: 0,
                cacheHit: true, retryCount: 0, succeeded: true
            )
            log(metrics)
            return AIResponse(text: cached, metrics: metrics)
        }

        // 4a. Dry run — full pipeline, zero provider contact, zero cost.
        if configuration.dryRun {
            let metrics = makeMetrics(
                requestID: requestID, modelID: modelID, start: start,
                estimatedTokens: estimatedTokens, response: nil, costUSD: 0,
                cacheHit: false, retryCount: 0, succeeded: true
            )
            log(metrics)
            // Dry-run output is never cached — it would poison the cache.
            return AIResponse(
                text: "[dry-run] \(modelID) not called; estimated \(estimatedTokens) input tokens",
                metrics: metrics
            )
        }

        // 4b. Provider call with declared retry (AD-25).
        var attempt = 0
        var lastError = "unknown"
        while attempt < configuration.retry.maxAttempts {
            do {
                let result = try await provider.complete(prompt: prompt, modelID: modelID)
                await cache.store(result.text, for: cacheKey)
                let metrics = makeMetrics(
                    requestID: requestID, modelID: modelID, start: start,
                    estimatedTokens: estimatedTokens, response: result,
                    costUSD: cost(
                        inputTokens: result.tokensIn ?? estimatedTokens,
                        outputTokens: result.tokensOut ?? 0,
                        model: model
                    ),
                    cacheHit: false, retryCount: attempt, succeeded: true
                )
                log(metrics)
                return AIResponse(text: result.text, metrics: metrics)
            } catch {
                lastError = String(describing: error)
                attempt += 1
            }
        }

        // 5. Retries exhausted — measure the failure too, then surface it.
        let metrics = makeMetrics(
            requestID: requestID, modelID: modelID, start: start,
            estimatedTokens: estimatedTokens, response: nil, costUSD: 0,
            cacheHit: false, retryCount: attempt - 1, succeeded: false,
            failureReason: lastError
        )
        log(metrics)
        throw AIGatewayError.providerFailed(attempts: attempt, lastError: lastError)
    }

    // MARK: Private

    private func assemblePrompt(for request: AIRequest) -> String {
        configuration.preamble.isEmpty
            ? request.task
            : "\(configuration.preamble)\n\n\(request.task)"
    }

    private func cost(inputTokens: Int, outputTokens: Int, model: ModelInfo) -> Double {
        (Double(inputTokens) * model.inputCostPer1MTokens
            + Double(outputTokens) * model.outputCostPer1MTokens) / 1_000_000
    }

    private func makeMetrics(
        requestID: UUID,
        modelID: String,
        start: Date,
        estimatedTokens: Int,
        response: ProviderResponse?,
        costUSD: Double,
        cacheHit: Bool,
        retryCount: Int,
        succeeded: Bool,
        failureReason: String? = nil
    ) -> AIRequestMetrics {
        AIRequestMetrics(
            requestID: requestID,
            providerID: provider.id,
            modelID: modelID,
            latencySeconds: Date().timeIntervalSince(start),
            estimatedTokensIn: estimatedTokens,
            actualTokensIn: response?.tokensIn,
            actualTokensOut: response?.tokensOut,
            costUSD: costUSD,
            cacheHit: cacheHit,
            retryCount: retryCount,
            dryRun: configuration.dryRun,
            succeeded: succeeded,
            failureReason: failureReason
        )
    }

    private func log(_ metrics: AIRequestMetrics) {
        logger.log(LogEvent(
            level: metrics.succeeded ? .info : .error,
            message: "ai.request",
            metadata: [
                "requestID": metrics.requestID.uuidString,
                "provider": metrics.providerID,
                "model": metrics.modelID,
                "latencySeconds": String(format: "%.3f", metrics.latencySeconds),
                "estimatedTokensIn": String(metrics.estimatedTokensIn),
                "actualTokensIn": metrics.actualTokensIn.map(String.init) ?? "-",
                "actualTokensOut": metrics.actualTokensOut.map(String.init) ?? "-",
                "costUSD": String(format: "%.6f", metrics.costUSD),
                "cacheHit": String(metrics.cacheHit),
                "retryCount": String(metrics.retryCount),
                "dryRun": String(metrics.dryRun),
                "succeeded": String(metrics.succeeded),
            ]
        ))
    }
}
