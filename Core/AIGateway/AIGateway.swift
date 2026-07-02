import Foundation

/// The single door for every AI call (AD-06, AD-24). Owns the full chain:
/// retrieve (via Store) → assemble → budget → cache → route → measure.
/// No component calls a provider directly; there is no separate Context
/// Engine/Loader/Builder — recreating one violates the architecture.
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
    public let usage: AIUsage

    public init(text: String, usage: AIUsage) {
        self.text = text
        self.usage = usage
    }
}

/// Every call is measured — unmeasured is unoptimizable (AD-15).
public struct AIUsage: Codable, Sendable {
    public let modelID: String
    public let tokensIn: Int
    public let tokensOut: Int
    public let cacheHit: Bool

    public init(modelID: String, tokensIn: Int, tokensOut: Int, cacheHit: Bool) {
        self.modelID = modelID
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.cacheHit = cacheHit
    }
}
