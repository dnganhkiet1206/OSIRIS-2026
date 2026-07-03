import Foundation
import OsirisCore

/// Today's resource usage — session only, never persisted (metrics history
/// is an M7 question, decided with real data).
public struct UsageSnapshot: Equatable, Sendable {
    public let requests: Int
    public let tokensIn: Int
    public let tokensOut: Int
    public let costUSD: Double
    public let cacheHits: Int

    public init(requests: Int, tokensIn: Int, tokensOut: Int, costUSD: Double, cacheHits: Int) {
        self.requests = requests
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
        self.costUSD = costUSD
        self.cacheHits = cacheHits
    }
}

/// Everything the Dashboard shows — operational awareness only, exactly the
/// BLUEPRINT list. No charts, no trends, no history.
public struct DashboardSnapshot: Equatable, Sendable {
    public let projectName: String
    public let currentGoal: String?
    public let lastCompletedTask: String?
    public let completedCount: Int
    public let recentActivity: [String]
    public let usage: UsageSnapshot
    public let providerConnected: Bool
}

/// Session-level dashboard state (M2-4). Receives metrics through the
/// Gateway's onMetrics seam (AD-39) and execution events through the Event
/// Bus — it never knows the Gateway or the Kernel themselves. Lock-based
/// like ChatService; all math here so it is testable on every platform.
public final class DashboardModel: @unchecked Sendable {
    private let lock = NSLock()
    private var requests = 0
    private var tokensIn = 0
    private var tokensOut = 0
    private var costUSD = 0.0
    private var cacheHits = 0
    /// Newest first, capped — a status strip, not a log.
    private var activity: [String] = []
    private let maxActivityLines = 10

    private let stateFor: @Sendable (String) async throws -> ProjectState?
    private let providerConnected: @Sendable () -> Bool

    public init(
        stateFor: @escaping @Sendable (String) async throws -> ProjectState?,
        providerConnected: @escaping @Sendable () -> Bool
    ) {
        self.stateFor = stateFor
        self.providerConnected = providerConnected
    }

    /// Target of the Gateway's onMetrics callback.
    public func recordMetrics(_ metrics: AIRequestMetrics) {
        lock.lock()
        defer { lock.unlock() }
        requests += 1
        tokensIn += metrics.actualTokensIn ?? metrics.estimatedTokensIn
        tokensOut += metrics.actualTokensOut ?? 0
        costUSD += metrics.costUSD
        if metrics.cacheHit { cacheHits += 1 }
    }

    /// Target of the Event Bus subscription.
    public func recordEvent(_ event: ExecutionEvent) {
        guard let line = Self.activityLine(for: event) else { return }
        lock.lock()
        defer { lock.unlock() }
        activity.insert(line, at: 0)
        if activity.count > maxActivityLines {
            activity.removeLast(activity.count - maxActivityLines)
        }
    }

    public func snapshot(projectID: String) async -> DashboardSnapshot {
        let state = (try? await stateFor(projectID)) ?? nil
        let (usage, recent) = usageAndActivity()

        return DashboardSnapshot(
            projectName: state?.name ?? projectID,
            currentGoal: state?.currentGoal,
            lastCompletedTask: state?.completedTasks.last,
            completedCount: state?.completedTasks.count ?? 0,
            recentActivity: recent,
            usage: usage,
            providerConnected: providerConnected()
        )
    }

    /// Synchronous read under the lock — NSLock must never span an await.
    private func usageAndActivity() -> (UsageSnapshot, [String]) {
        lock.lock()
        defer { lock.unlock() }
        return (
            UsageSnapshot(
                requests: requests, tokensIn: tokensIn, tokensOut: tokensOut,
                costUSD: costUSD, cacheHits: cacheHits
            ),
            activity
        )
    }

    /// One translation for activity text (reuses ChatService's mapping);
    /// terminal events get their own short lines.
    static func activityLine(for event: ExecutionEvent) -> String? {
        switch event {
        case .completed: return "Completed"
        case .failed: return "Failed"
        default: return ChatService.activityText(for: event)
        }
    }
}
