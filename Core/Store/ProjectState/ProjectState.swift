import Foundation

/// Unique identifier of a project. Projects are isolated from each other.
public struct ProjectID: Hashable, Codable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
}

/// The structured record of where a project stands — the single source of
/// truth (State Over Chat, AD-22). Deliverables themselves are files on disk;
/// `deliverablePaths` is a derived index (AD-10). "Executive State" does not
/// exist as data — it is computed from this record when needed (AD-08).
public struct ProjectState: Codable, Sendable {
    public let projectID: ProjectID
    public var currentGoal: String?
    public var currentTask: String?
    public var completedTasks: [String]
    public var nextTasks: [String]
    public var architectureDecisions: [String]
    public var knownIssues: [String]
    public var deliverablePaths: [String]
    public var updatedAt: Date

    public init(projectID: ProjectID) {
        self.projectID = projectID
        self.currentGoal = nil
        self.currentTask = nil
        self.completedTasks = []
        self.nextTasks = []
        self.architectureDecisions = []
        self.knownIssues = []
        self.deliverablePaths = []
        self.updatedAt = Date()
    }

    public mutating func recordCompletion(of goal: String) {
        completedTasks.append(goal)
        if currentGoal == goal { currentGoal = nil }
        updatedAt = Date()
    }
}
