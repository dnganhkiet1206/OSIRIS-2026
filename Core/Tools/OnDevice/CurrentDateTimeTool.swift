import Foundation

/// The first on-device tool — exists to prove "AI Is The Last Tool":
/// a date/time question completes with zero AI requests and zero tokens.
/// Deterministic given the injected clock; no network, no AI.
public struct CurrentDateTimeTool: Tool {
    public let id = ToolID("core.current-datetime")

    /// Narrow phrases only — an ordinary goal must never be hijacked.
    public let triggerKeywords = [
        "date today", "today's date", "current date", "what day is it",
        "what time is it", "current time",
        "hôm nay là ngày", "hôm nay ngày", "ngày mấy", "mấy giờ",
    ]

    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = { Date() }) {
        self.now = now
    }

    public func run(_ input: ToolInput) async throws -> ToolOutput {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return ToolOutput(content: formatter.string(from: now()))
    }
}
