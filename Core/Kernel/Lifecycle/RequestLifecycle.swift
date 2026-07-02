import Foundation

// The canonical five-phase lifecycle (AD-12) — Intake → Decide → Execute →
// Verify → Persist — is implemented by Kernel.handle. There is no other
// pipeline anywhere in the platform.

/// A user objective entering the system. The user thinks in goals;
/// everything else is OSIRIS's responsibility.
public struct Goal: Sendable {
    public let projectID: ProjectID
    public let text: String

    public init(projectID: ProjectID, text: String) {
        self.projectID = projectID
        self.text = text
    }
}

/// The product of every completed request. Conversation is the interface;
/// deliverables are the product. Substantial deliverables become files on
/// disk (AD-10); this carries the content and its eventual location.
public struct Deliverable: Sendable {
    public let content: String
    public let filePath: String?

    public init(content: String, filePath: String? = nil) {
        self.content = content
        self.filePath = filePath
    }
}

/// Lightweight execution events shown to the user (UI contract: activities,
/// never reasoning). Defined in Core; carried by the generic
/// Infrastructure.EventBus.
public enum ExecutionEvent: Sendable {
    case understanding
    case planning
    case executing
    case updatingState
    case completed
    case failed(String)
}
