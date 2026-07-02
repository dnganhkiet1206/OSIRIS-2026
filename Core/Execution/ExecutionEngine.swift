import Foundation

/// The only place allowed to DO (AD-25). Runs what the Kernel decided:
/// direct work, tools, skill compositions, or AI calls via the Gateway.
/// It never chooses strategy — that is the Kernel's exclusive right.
public protocol ExecutionEngine: Sendable {
    func run(_ plan: ExecutionPlan) async throws -> ExecutionResult
}

/// The Kernel's decision, handed over for mechanical execution.
public struct ExecutionPlan: Sendable {
    public let goal: Goal
    public let strategy: ExecutionStrategy
    public let retryPolicy: RetryPolicy
    /// Model tier the Kernel decided on; Execution passes it through
    /// unchanged (routing by tier activates with ≥2 real models — AD-31).
    public let preferredTier: ModelTier

    public init(
        goal: Goal,
        strategy: ExecutionStrategy,
        retryPolicy: RetryPolicy = .none,
        preferredTier: ModelTier = .light
    ) {
        self.goal = goal
        self.strategy = strategy
        self.retryPolicy = retryPolicy
        self.preferredTier = preferredTier
    }
}

public struct ExecutionResult: Sendable {
    public let deliverable: Deliverable
    public let aiMetrics: AIRequestMetrics?

    public init(deliverable: Deliverable, aiMetrics: AIRequestMetrics? = nil) {
        self.deliverable = deliverable
        self.aiMetrics = aiMetrics
    }
}
