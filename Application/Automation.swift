import Foundation
import OsirisCore

/// An automation rule as the UI sees it (M6-1). A saved goal, its trigger,
/// and whether it is enabled — enough to list, toggle and run.
public struct AutomationRuleSummary: Identifiable, Equatable, Sendable {
    public let id: String
    public let goalText: String
    public let trigger: AutomationTrigger
    public let enabled: Bool

    public init(id: String, goalText: String, trigger: AutomationTrigger, enabled: Bool) {
        self.id = id
        self.goalText = goalText
        self.trigger = trigger
        self.enabled = enabled
    }

    /// Pure mapping from the stored record — platform-testable, no I/O.
    public static func from(_ rule: AutomationRule) -> AutomationRuleSummary {
        AutomationRuleSummary(
            id: rule.id, goalText: rule.goalText, trigger: rule.trigger, enabled: rule.enabled
        )
    }
}

/// Automation port (M6-1, AD-47) — state management via closures wired by
/// the composition root onto the Store (single persister, AD-38 pattern).
/// `run` reuses the SAME `ChatService.submit` path a typed goal uses:
/// automation has no second execution path (AD-47). Scheduled triggers
/// (`.daily`) are iOS background firing — not part of this port yet.
public struct Automation: Sendable {
    public let list: @Sendable () async throws -> [AutomationRuleSummary]
    public let create: @Sendable (_ goalText: String, _ projectID: String) async throws -> AutomationRuleSummary
    public let setEnabled: @Sendable (_ id: String, _ enabled: Bool) async throws -> Void
    public let delete: @Sendable (_ id: String) async throws -> Void
    /// Runs the rule's goal now, through the exact Kernel path (via
    /// ChatService). Updates stream back like any submitted goal.
    public let runNow: @Sendable (_ id: String, _ onUpdate: @escaping @Sendable (TaskUpdate) -> Void) async -> Void

    public init(
        list: @escaping @Sendable () async throws -> [AutomationRuleSummary],
        create: @escaping @Sendable (_ goalText: String, _ projectID: String) async throws -> AutomationRuleSummary,
        setEnabled: @escaping @Sendable (_ id: String, _ enabled: Bool) async throws -> Void,
        delete: @escaping @Sendable (_ id: String) async throws -> Void,
        runNow: @escaping @Sendable (_ id: String, _ onUpdate: @escaping @Sendable (TaskUpdate) -> Void) async -> Void
    ) {
        self.list = list
        self.create = create
        self.setEnabled = setEnabled
        self.delete = delete
        self.runNow = runNow
    }
}
