import Foundation

/// Actions that always require user approval before execution (Approval
/// contract). The user owns strategy; OSIRIS owns execution.
public enum RiskyAction: String, Codable, Sendable {
    case publish
    case delete
    case overwrite
    case largeSpend
    case permanentSettingsChange
    case coreBehaviorChange
}

public enum ApprovalDecision: Sendable {
    case approved
    case denied
    case requiresUser
}

/// Gate consulted by the Kernel's Decide phase before any risky action.
/// The UI-facing implementation (asking the user) lives in the app layer.
public protocol ApprovalGate: Sendable {
    func evaluate(_ action: RiskyAction) async -> ApprovalDecision
}

/// Safe default: every risky action requires the user. No silent approvals.
public struct RequireUserApprovalGate: ApprovalGate {
    public init() {}

    public func evaluate(_ action: RiskyAction) async -> ApprovalDecision {
        .requiresUser
    }
}
