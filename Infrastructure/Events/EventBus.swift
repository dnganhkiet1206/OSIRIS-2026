import Foundation

/// Thin publish/subscribe channel (AD-26: infrastructure plumbing, not a Core
/// component). Generic over the event type so Infrastructure stays free of
/// domain knowledge — Core defines its own event enums.
public actor EventBus<Event: Sendable> {
    private var subscribers: [UUID: AsyncStream<Event>.Continuation] = [:]

    public init() {}

    /// Returns a stream of all events published after the call.
    public func events() -> AsyncStream<Event> {
        let id = UUID()
        return AsyncStream { continuation in
            subscribers[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeSubscriber(id) }
            }
        }
    }

    public func publish(_ event: Event) {
        for continuation in subscribers.values {
            continuation.yield(event)
        }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}
