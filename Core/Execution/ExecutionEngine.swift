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

    public init(goal: Goal, strategy: ExecutionStrategy, retryPolicy: RetryPolicy = .none) {
        self.goal = goal
        self.strategy = strategy
        self.retryPolicy = retryPolicy
    }
}

public struct ExecutionResult: Sendable {
    public let deliverable: Deliverable
    public let usage: AIUsage?

    public init(deliverable: Deliverable, usage: AIUsage? = nil) {
        self.deliverable = deliverable
        self.usage = usage
    }
}
