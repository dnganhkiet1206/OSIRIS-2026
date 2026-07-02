import Foundation

/// The single door for every AI call (AD-06, AD-24). Owns the full request
/// lifecycle: validate → budget → cache → (dry-run | provider with retry) →
/// measure → log. No component calls a provider directly; there is no
/// separate Context Engine/Loader/Builder — recreating one violates the
/// architecture.
public protocol AIGateway: Sendable {
    func complete(_ request: AIRequest) async throws -> AIResponse
}

/// What the Kernel hands the Gateway: the task and references to what the
/// Gateway may retrieve. The Kernel never assembles prompts itself.
public struct AIRequest: Sendable {
    public let task: String
    public let projectID: ProjectID?
    public let preferredTier: ModelTier

    public init(task: String, projectID: ProjectID? = nil, preferredTier: ModelTier = .light) {
        self.task = task
        self.projectID = projectID
        self.preferredTier = preferredTier
    }
}

public struct AIResponse: Sendable {
    public let text: String
    public let metrics: AIRequestMetrics

    public init(text: String, metrics: AIRequestMetrics) {
        self.text = text
        self.metrics = metrics
    }
}

/// Gateway failures. Every case carries enough context for the UI contract:
/// what happened, what was attempted, what to do next. Never contains
/// prompt content or secrets.
public enum AIGatewayError: Error, Equatable, Sendable {
    case invalidConfiguration(String)
    case invalidRequest(String)
    case tokenBudgetExceeded(estimated: Int, limit: Int)
    case costBudgetExceeded(estimatedUSD: Double, limitUSD: Double)
    case providerFailed(attempts: Int, lastError: String)
}
