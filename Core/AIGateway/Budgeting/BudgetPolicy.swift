import Foundation

/// Per-request spending limits (Token Philosophy: tokens are budget, not free
/// resources). The Gateway rejects any request whose pre-flight estimate
/// exceeds these limits — a rejected request costs nothing.
public struct BudgetPolicy: Codable, Sendable {
    public let maxTokensPerRequest: Int
    public let maxCostPerRequestUSD: Double

    public init(maxTokensPerRequest: Int, maxCostPerRequestUSD: Double) {
        self.maxTokensPerRequest = maxTokensPerRequest
        self.maxCostPerRequestUSD = maxCostPerRequestUSD
    }
}
