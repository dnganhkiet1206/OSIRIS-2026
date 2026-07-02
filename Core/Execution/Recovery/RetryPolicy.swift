import Foundation

/// Declared retry/fallback policy (AD-25). The Execution Engine executes this
/// mechanically — it never invents recovery strategies. Situations beyond the
/// declared policy escalate back to the Kernel, the only place allowed to
/// choose.
public struct RetryPolicy: Codable, Sendable {
    public let maxAttempts: Int

    public init(maxAttempts: Int) {
        self.maxAttempts = maxAttempts
    }

    /// No retries — fail fast and escalate.
    public static let none = RetryPolicy(maxAttempts: 1)
}
