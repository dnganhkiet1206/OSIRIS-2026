import Foundation
import OsirisInfrastructure

/// Bootstrap Gateway: static preamble + task → provider, with usage logging.
/// Retrieval via Store.search, budgeting, compression and response caching
/// are layered in during M0-3/M1 — behind this same interface.
public struct DefaultAIGateway: AIGateway {
    private let provider: any AIProvider
    private let preamble: String
    private let defaultModelID: String
    private let logger: any Logging

    public init(provider: any AIProvider, preamble: String, defaultModelID: String, logger: any Logging) {
        self.provider = provider
        self.preamble = preamble
        self.defaultModelID = defaultModelID
        self.logger = logger
    }

    public func complete(_ request: AIRequest) async throws -> AIResponse {
        let prompt = preamble.isEmpty ? request.task : "\(preamble)\n\n\(request.task)"
        let response = try await provider.complete(prompt: prompt, modelID: defaultModelID)
        logger.log(LogEvent(
            level: .info,
            message: "ai.call",
            metadata: [
                "provider": provider.id,
                "model": response.usage.modelID,
                "tokensIn": String(response.usage.tokensIn),
                "tokensOut": String(response.usage.tokensOut),
                "cacheHit": String(response.usage.cacheHit),
            ]
        ))
        return response
    }
}
