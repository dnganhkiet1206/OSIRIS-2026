import Foundation
import OsirisCore

/// Everything the Presentation layer is allowed to know about a running
/// task (AD-35). No provider, no retry, no reuse, no strategy — the UI
/// never learns where a result came from.
public struct TaskUpdate: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        /// Human-readable activity for the status line ("Planning…").
        case activity(String)
        /// The system needs an answer before it can proceed.
        case needsClarification(question: String)
        /// Terminal: the deliverable content to show.
        case completed(result: String)
        /// Terminal: friendly failure per the UI contract
        /// (what happened / what was attempted / what to do next).
        case failed(message: String)
    }

    public let kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }
}

/// Application service — the ONLY bridge between UI and Core (AD-35).
/// Responsibilities: forward goals to the Kernel, translate Core events and
/// errors into UI-facing updates. It holds no business logic and makes no
/// decisions.
///
/// Wiring (composition root only): create the service, hand `relay(_:)` to
/// the Kernel as its event publisher, then `configure(kernel:)` once.
/// Lock-based state — the module's standard pattern for small shared state.
public final class ChatService: @unchecked Sendable {
    private let lock = NSLock()
    private var kernel: Kernel?
    private var activeHandler: (@Sendable (TaskUpdate) -> Void)?

    public init() {}

    /// Set-once Kernel wiring; calling twice is a programmer error.
    public func configure(kernel: Kernel) {
        lock.lock()
        defer { lock.unlock() }
        precondition(self.kernel == nil, "ChatService is wired once, by the composition root")
        self.kernel = kernel
    }

    /// Receives Core execution events (wired as the Kernel's publisher)
    /// and forwards them as activity text. Terminal events are reported by
    /// `submit` itself, so they carry results and never race the handler.
    public func relay(_ event: ExecutionEvent) {
        guard let handler = currentHandler(), let text = Self.activityText(for: event) else { return }
        handler(TaskUpdate(kind: .activity(text)))
    }

    /// Submits one goal and reports updates until a terminal update
    /// (`completed` / `needsClarification` / `failed`) is delivered.
    /// One goal at a time — a second submit while running fails fast.
    public func submit(
        goal: String,
        projectID: String,
        onUpdate: @escaping @Sendable (TaskUpdate) -> Void
    ) async {
        guard let kernel = lockedKernel() else {
            onUpdate(TaskUpdate(kind: .failed(message: "The app is not fully set up. Restart it and try again.")))
            return
        }
        guard beginTask(onUpdate) else {
            onUpdate(TaskUpdate(kind: .failed(message: "A task is already running. Wait for it to finish, then try again.")))
            return
        }
        defer { endTask() }

        do {
            let deliverable = try await kernel.handle(Goal(projectID: ProjectID(projectID), text: goal))
            onUpdate(TaskUpdate(kind: .completed(result: deliverable.content)))
        } catch let error as KernelError {
            onUpdate(TaskUpdate(kind: Self.translate(error)))
        } catch let error as AIGatewayError {
            onUpdate(TaskUpdate(kind: .failed(message: Self.translate(error))))
        } catch {
            onUpdate(TaskUpdate(kind: .failed(message: "Something unexpected went wrong. Nothing was lost — please try again.")))
        }
    }

    // MARK: Translation (pure — unit tested on all platforms)

    static func activityText(for event: ExecutionEvent) -> String? {
        switch event {
        case .understanding: return "Understanding your request…"
        case .planning: return "Planning…"
        case .executing: return "Working on it…"
        case .updatingState: return "Saving progress…"
        case .completed, .failed: return nil
        }
    }

    static func translate(_ error: KernelError) -> TaskUpdate.Kind {
        switch error {
        case .needsClarification(let question):
            return .needsClarification(question: question)
        case .verificationFailed:
            return .failed(message: "The result didn't meet quality checks, so it wasn't delivered. Try rephrasing your goal.")
        }
    }

    static func translate(_ error: AIGatewayError) -> String {
        switch error {
        case .invalidRequest:
            return "Please describe what you want to accomplish."
        case .tokenBudgetExceeded:
            return "This request is too large, so it was stopped before spending anything. Try a shorter or more specific goal."
        case .costBudgetExceeded:
            return "This request would exceed the cost limit, so it was stopped before spending anything. Try a smaller goal or raise the budget in Settings."
        case .providerFailed(let attempts, _):
            return "The AI service didn't respond after \(attempts) attempt\(attempts == 1 ? "" : "s"). Check your connection and try again."
        case .invalidConfiguration:
            return "The app configuration is invalid. Reinstall or fix the Config files."
        }
    }

    // MARK: Locked state

    private func lockedKernel() -> Kernel? {
        lock.lock()
        defer { lock.unlock() }
        return kernel
    }

    private func currentHandler() -> (@Sendable (TaskUpdate) -> Void)? {
        lock.lock()
        defer { lock.unlock() }
        return activeHandler
    }

    private func beginTask(_ handler: @escaping @Sendable (TaskUpdate) -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard activeHandler == nil else { return false }
        activeHandler = handler
        return true
    }

    private func endTask() {
        lock.lock()
        defer { lock.unlock() }
        activeHandler = nil
    }
}
