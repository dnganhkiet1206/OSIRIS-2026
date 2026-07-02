import Foundation
import OsirisInfrastructure

/// The production Gateway. Pipeline for every request (AD-24):
///
///   validate request → retrieve context (via Store) → trim to budget →
///   assemble → budget checks → cache lookup →
///   (dry-run simulation | provider call with declared retry) →
///   metrics + structured log → response
///
/// Retrieval happens before the cache lookup, so the cache key (model +
/// assembled prompt) always reflects the context actually used — changed
/// context can never serve a stale cached answer.
///
/// Configuration is validated at construction (GatewayConfiguration throws),
/// so an operating Gateway is always validly configured. Retry follows the
/// declared RetryPolicy mechanically (AD-25) — no improvised recovery.
/// Logs carry metrics only, never prompt content or secrets.
public struct DefaultAIGateway: AIGateway {
    private let provider: any AIProvider
    private let configuration: GatewayConfiguration
    private let store: (any Store)?
    private let cache: any ResponseCache
    private let logger: any Logging

    /// Per-snippet cap: few and short beats many and noisy (~150 tokens).
    private let maxSnippetCharacters = 600

    public init(
        provider: any AIProvider,
        configuration: GatewayConfiguration,
        store: (any Store)? = nil,
        cache: any ResponseCache = InMemoryResponseCache(),
        logger: any Logging
    ) {
        self.provider = provider
        self.configuration = configuration
        self.store = store
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

        // 2. Retrieve → trim → assemble (M1-2). No store or no project means
        // no retrieval — the prompt is then identical to the pre-M1-2 shape.
        let context = trim(await retrieveContext(for: request), task: request.task)
        let prompt = assemblePrompt(task: request.task, context: context)
        let estimatedTokens = TokenEstimator.estimate(prompt)

        // 3. Budget — a rejected request costs nothing.
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

        // 4. Cache — a hit is free (Reuse Before Create). The key contains
        // the assembled prompt, so it reflects the context actually used.
        let cacheKey = "\(modelID)\n\(prompt)"
        if let cached = await cache.response(for: cacheKey) {
            let metrics = makeMetrics(
                requestID: requestID, modelID: modelID, start: start,
                estimatedTokens: estimatedTokens, response: nil, costUSD: 0,
                cacheHit: true, retryCount: 0, contextSnippets: context.count, succeeded: true
            )
            log(metrics)
            return AIResponse(text: cached, metrics: metrics)
        }

        // 5a. Dry run — full pipeline, zero provider contact, zero cost.
        if configuration.dryRun {
            let metrics = makeMetrics(
                requestID: requestID, modelID: modelID, start: start,
                estimatedTokens: estimatedTokens, response: nil, costUSD: 0,
                cacheHit: false, retryCount: 0, contextSnippets: context.count, succeeded: true
            )
            log(metrics)
            // Dry-run output is never cached — it would poison the cache.
            return AIResponse(
                text: "[dry-run] \(modelID) not called; estimated \(estimatedTokens) input tokens",
                metrics: metrics
            )
        }

        // 5b. Provider call with declared retry (AD-25).
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
                    cacheHit: false, retryCount: attempt, contextSnippets: context.count, succeeded: true
                )
                log(metrics)
                return AIResponse(text: result.text, metrics: metrics)
            } catch {
                lastError = String(describing: error)
                attempt += 1
            }
        }

        // 6. Retries exhausted — measure the failure too, then surface it.
        let metrics = makeMetrics(
            requestID: requestID, modelID: modelID, start: start,
            estimatedTokens: estimatedTokens, response: nil, costUSD: 0,
            cacheHit: false, retryCount: attempt - 1, contextSnippets: context.count,
            succeeded: false, failureReason: lastError
        )
        log(metrics)
        throw AIGatewayError.providerFailed(attempts: attempt, lastError: lastError)
    }

    // MARK: Retrieval (AD-24 — via the Store protocol only, never LocalStorage)

    private struct ContextSnippet {
        let priority: ContextPriority
        let text: String
    }

    /// Few but relevant: at most `maxContextSnippets`, project-scoped,
    /// ranked by word overlap. A failed search never blocks the AI call.
    private func retrieveContext(for request: AIRequest) async -> [ContextSnippet] {
        guard let store, let projectID = request.projectID else { return [] }
        let results = (try? await store.search(StoreQuery(
            text: request.task,
            projectID: projectID,
            limit: configuration.budget.maxContextSnippets,
            matchMode: .anyWord
        ))) ?? []

        var snippets: [ContextSnippet] = []
        for result in results {
            switch result.kind {
            case .workingContext:
                snippets.append(ContextSnippet(priority: .important, text: cap(result.snippet)))
            case .knowledge:
                // The topic alone is too thin to be useful context —
                // fetch the body (N ≤ maxContextSnippets keeps this cheap).
                let body = (try? await store.knowledge(id: result.id))??.body ?? result.snippet
                snippets.append(ContextSnippet(priority: .helpful, text: cap(body)))
            case .deliverable:
                snippets.append(ContextSnippet(priority: .optional, text: cap(result.snippet)))
            case .projectState:
                continue
            }
        }
        return snippets
    }

    private func cap(_ text: String) -> String {
        String(text.prefix(maxSnippetCharacters))
    }

    // MARK: Assembly (structured sections; critical parts are never trimmed)

    /// Drops snippets lowest-priority-first until the assembled prompt fits
    /// the context budget. Deterministic — never a random cut, never a
    /// broken structure: trimming removes whole snippets only.
    private func trim(_ context: [ContextSnippet], task: String) -> [ContextSnippet] {
        var current = context.sorted { $0.priority < $1.priority }
        while !current.isEmpty {
            let prompt = assemblePrompt(task: task, context: current)
            if TokenEstimator.estimate(prompt) <= configuration.budget.contextBudgetTokens { break }
            current.removeLast()
        }
        return current
    }

    /// Stable sectioned layout. With no context this produces exactly the
    /// pre-M1-2 prompt (preamble + task), so cache keys and tests hold.
    private func assemblePrompt(task: String, context: [ContextSnippet]) -> String {
        var parts: [String] = []
        if !configuration.preamble.isEmpty {
            parts.append(configuration.preamble)
        }
        if context.isEmpty {
            parts.append(task)
            return parts.joined(separator: "\n\n")
        }

        var sections = ["## Relevant context"]
        let groups: [(ContextPriority, String)] = [
            (.important, "Current working context"),
            (.helpful, "Knowledge"),
            (.optional, "Previous results"),
        ]
        for (priority, title) in groups {
            let items = context.filter { $0.priority == priority }
            guard !items.isEmpty else { continue }
            sections.append("### \(title)\n" + items.map { "- \($0.text)" }.joined(separator: "\n"))
        }
        parts.append(sections.joined(separator: "\n\n"))
        parts.append("## Task\n\(task)")
        return parts.joined(separator: "\n\n")
    }

    // MARK: Accounting

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
        contextSnippets: Int,
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
            contextSnippetCount: contextSnippets,
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
                "contextSnippets": String(metrics.contextSnippetCount),
                "succeeded": String(metrics.succeeded),
            ]
        ))
    }
}
