import Foundation

/// Full measurement of one AI request (AD-15: unmeasured is unoptimizable).
/// Emitted for every request — success, failure, cache hit or dry run — and
/// logged through the platform Logger. Foundation for Dashboard and Token
/// Analysis. Never contains prompt content or secrets.
public struct AIRequestMetrics: Codable, Sendable {
    public let requestID: UUID
    public let providerID: String
    public let modelID: String
    public let latencySeconds: Double
    public let estimatedTokensIn: Int
    public let actualTokensIn: Int?
    public let actualTokensOut: Int?
    public let costUSD: Double
    public let cacheHit: Bool
    public let retryCount: Int
    public let dryRun: Bool
    /// How many retrieved context snippets made it into the prompt after
    /// trimming (M1-2) — retrieval quality is tunable only if measured.
    public let contextSnippetCount: Int
    public let succeeded: Bool
    public let failureReason: String?

    public init(
        requestID: UUID,
        providerID: String,
        modelID: String,
        latencySeconds: Double,
        estimatedTokensIn: Int,
        actualTokensIn: Int?,
        actualTokensOut: Int?,
        costUSD: Double,
        cacheHit: Bool,
        retryCount: Int,
        dryRun: Bool,
        contextSnippetCount: Int = 0,
        succeeded: Bool,
        failureReason: String? = nil
    ) {
        self.requestID = requestID
        self.providerID = providerID
        self.modelID = modelID
        self.latencySeconds = latencySeconds
        self.estimatedTokensIn = estimatedTokensIn
        self.actualTokensIn = actualTokensIn
        self.actualTokensOut = actualTokensOut
        self.costUSD = costUSD
        self.cacheHit = cacheHit
        self.retryCount = retryCount
        self.dryRun = dryRun
        self.contextSnippetCount = contextSnippetCount
        self.succeeded = succeeded
        self.failureReason = failureReason
    }
}
