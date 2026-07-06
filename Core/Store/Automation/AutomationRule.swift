import Foundation

/// A saved goal the user can re-run on demand ("run now") or, once iOS
/// scheduling exists, fire on a trigger (M6-1, AD-47). Automation is DATA:
/// a rule describes WHAT to run and WHEN — it holds no execution logic.
/// Running a rule reuses the exact Kernel lifecycle a typed goal uses;
/// there is no automation pipeline (AD-47).
///
/// Schema is minimal (AD-28): only the fields needed to run. No scheduling
/// metadata beyond the trigger, no "reserved" fields — added when the iOS
/// trigger design provides evidence of need.
public struct AutomationRule: Codable, Sendable, Equatable {
    public let id: String
    /// The goal to run, split into the two things a Goal needs.
    public let projectID: ProjectID
    public let goalText: String
    public let trigger: AutomationTrigger
    public var enabled: Bool

    public init(
        id: String,
        projectID: ProjectID,
        goalText: String,
        trigger: AutomationTrigger = .manual,
        enabled: Bool = true
    ) {
        self.id = id
        self.projectID = projectID
        self.goalText = goalText
        self.trigger = trigger
        self.enabled = enabled
    }
}

/// When a rule fires. Data only — NO scheduler, NO timer (AD-47). `.manual`
/// is the only trigger runnable offline (via "run now"); `.daily` defines
/// the time-trigger SCHEMA for when iOS background scheduling is built
/// (M6-2+), never fired on Linux.
public enum AutomationTrigger: Codable, Sendable, Equatable {
    case manual
    case daily(hour: Int)
}
