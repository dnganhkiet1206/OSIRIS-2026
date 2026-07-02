import Foundation

/// Provider adapter contract. Providers are interchangeable; the platform
/// keeps functioning regardless of which one is active (AI Philosophy).
public protocol AIProvider: Sendable {
    var id: String { get }
    func complete(prompt: String, modelID: String) async throws -> AIResponse
}

/// Deterministic offline provider for bootstrap and tests. Echoes the task so
/// the end-to-end pipeline is verifiable without network or cost. The first
/// real provider adapter is task M0-3.
public struct PlaceholderAIProvider: AIProvider {
    public let id = "placeholder"

    public init() {}

    public func complete(prompt: String, modelID: String) async throws -> AIResponse {
        AIResponse(
            text: "[placeholder:\(modelID)] \(prompt)",
            usage: AIUsage(modelID: modelID, tokensIn: prompt.count / 4, tokensOut: 0, cacheHit: false)
        )
    }
}
