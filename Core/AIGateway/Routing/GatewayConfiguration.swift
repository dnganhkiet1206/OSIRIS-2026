import Foundation

/// One model the Gateway is allowed to route to. Mirrors Config/models.json —
/// model IDs and prices never live in code (Configuration First).
public struct ModelInfo: Codable, Sendable {
    public let id: String
    public let tier: ModelTier
    public let inputCostPer1MTokens: Double
    public let outputCostPer1MTokens: Double

    public init(id: String, tier: ModelTier, inputCostPer1MTokens: Double, outputCostPer1MTokens: Double) {
        self.id = id
        self.tier = tier
        self.inputCostPer1MTokens = inputCostPer1MTokens
        self.outputCostPer1MTokens = outputCostPer1MTokens
    }
}

/// Everything the Gateway needs to operate, assembled from Config/ by the
/// composition root. The throwing initializer IS the config validation:
/// an invalid configuration never produces a Gateway (fail fast).
public struct GatewayConfiguration: Sendable {
    public let models: [ModelInfo]
    public let defaultModelID: String
    public let budget: BudgetPolicy
    public let retry: RetryPolicy
    public let preamble: String
    public let dryRun: Bool

    public init(
        models: [ModelInfo],
        defaultModelID: String,
        budget: BudgetPolicy,
        retry: RetryPolicy,
        preamble: String,
        preambleMaxTokens: Int,
        dryRun: Bool
    ) throws {
        guard !models.isEmpty else {
            throw AIGatewayError.invalidConfiguration("models list is empty")
        }
        guard models.contains(where: { $0.id == defaultModelID }) else {
            throw AIGatewayError.invalidConfiguration("defaultModelID '\(defaultModelID)' not present in models")
        }
        guard budget.maxTokensPerRequest > 0, budget.maxCostPerRequestUSD >= 0 else {
            throw AIGatewayError.invalidConfiguration("budget limits must be positive")
        }
        guard retry.maxAttempts >= 1 else {
            throw AIGatewayError.invalidConfiguration("retry.maxAttempts must be at least 1")
        }
        // Mechanical enforcement of AD-13: the static preamble stays small.
        let preambleTokens = TokenEstimator.estimate(preamble)
        guard preambleTokens <= preambleMaxTokens else {
            throw AIGatewayError.invalidConfiguration(
                "preamble is ~\(preambleTokens) tokens, exceeding the \(preambleMaxTokens)-token limit (AD-13)"
            )
        }

        self.models = models
        self.defaultModelID = defaultModelID
        self.budget = budget
        self.retry = retry
        self.preamble = preamble
        self.dryRun = dryRun
    }

    public func model(withID id: String) -> ModelInfo? {
        models.first { $0.id == id }
    }
}
