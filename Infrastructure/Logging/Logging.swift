import Foundation

/// Structured logging contract. Logs feed debugging, cost analysis and
/// Developer Mode; they must never interfere with user experience.
public protocol Logging: Sendable {
    func log(_ event: LogEvent)
}

public struct LogEvent: Sendable {
    public enum Level: String, Sendable {
        case debug, info, warning, error
    }

    public let level: Level
    public let message: String
    public let metadata: [String: String]
    public let timestamp: Date

    public init(level: Level, message: String, metadata: [String: String] = [:], timestamp: Date = Date()) {
        self.level = level
        self.message = message
        self.metadata = metadata
        self.timestamp = timestamp
    }
}

/// Default console sink. File/rotating sinks arrive when there is evidence
/// they are needed (M0-2).
public struct ConsoleLogger: Logging {
    public init() {}

    public func log(_ event: LogEvent) {
        let meta = event.metadata.isEmpty
            ? ""
            : " " + event.metadata.map { "\($0)=\($1)" }.sorted().joined(separator: " ")
        print("[\(event.level.rawValue)] \(event.message)\(meta)")
    }
}
