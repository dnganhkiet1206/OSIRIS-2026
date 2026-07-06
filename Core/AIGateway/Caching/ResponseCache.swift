import Foundation

/// Response cache contract. In-memory today; the interface is the seam for a
/// disk-backed replacement later — callers never know the difference.
/// A cache hit costs zero tokens (Reuse Before Create).
public protocol ResponseCache: Sendable {
    func response(for key: String) async -> String?
    func store(_ text: String, for key: String) async
}

/// Simple unbounded in-memory cache. Eviction policy arrives when there is
/// measured evidence it is needed.
public actor InMemoryResponseCache: ResponseCache {
    private var entries: [String: String] = [:]

    public init() {}

    public func response(for key: String) -> String? {
        entries[key]
    }

    public func store(_ text: String, for key: String) {
        entries[key] = text
    }
}
