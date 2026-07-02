import Foundation

/// Per-request spending limits (Token Philosophy: tokens are budget, not free
/// resources). The Gateway rejects any request whose pre-flight estimate
/// exceeds these limits — a rejected request costs nothing.
public struct BudgetPolicy: Codable, Sendable {
    public let maxTokensPerRequest: Int
    public let maxCostPerRequestUSD: Double
    /// Assembly budget (M1-2): the assembled prompt aims to stay under this;
    /// context is trimmed lowest-priority-first until it fits. The critical
    /// parts (preamble + task) are never trimmed here — an oversized task
    /// still fails the hard `maxTokensPerRequest` check instead.
    public let contextBudgetTokens: Int
    /// Retrieval width: few but relevant beats many but noisy.
    public let maxContextSnippets: Int

    public init(
        maxTokensPerRequest: Int,
        maxCostPerRequestUSD: Double,
        contextBudgetTokens: Int = 4000,
        maxContextSnippets: Int = 3
    ) {
        self.maxTokensPerRequest = maxTokensPerRequest
        self.maxCostPerRequestUSD = maxCostPerRequestUSD
        self.contextBudgetTokens = contextBudgetTokens
        self.maxContextSnippets = maxContextSnippets
    }
}
