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
    /// Display name (M2-1). Pre-M2 files have no name — decoding falls
    /// back to the id so existing stores migrate silently.
    public var name: String
    public var currentGoal: String?
    public var currentTask: String?
    public var completedTasks: [String]
    public var nextTasks: [String]
    public var architectureDecisions: [String]
    public var knownIssues: [String]
    public var deliverablePaths: [String]
    public var updatedAt: Date

    public init(projectID: ProjectID, name: String? = nil) {
        self.projectID = projectID
        self.name = name ?? projectID.rawValue
        self.currentGoal = nil
        self.currentTask = nil
        self.completedTasks = []
        self.nextTasks = []
        self.architectureDecisions = []
        self.knownIssues = []
        self.deliverablePaths = []
        self.updatedAt = Date()
    }

    private enum CodingKeys: String, CodingKey {
        case projectID, name, currentGoal, currentTask, completedTasks
        case nextTasks, architectureDecisions, knownIssues, deliverablePaths, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        projectID = try container.decode(ProjectID.self, forKey: .projectID)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? projectID.rawValue
        currentGoal = try container.decodeIfPresent(String.self, forKey: .currentGoal)
        currentTask = try container.decodeIfPresent(String.self, forKey: .currentTask)
        completedTasks = try container.decode([String].self, forKey: .completedTasks)
        nextTasks = try container.decode([String].self, forKey: .nextTasks)
        architectureDecisions = try container.decode([String].self, forKey: .architectureDecisions)
        knownIssues = try container.decode([String].self, forKey: .knownIssues)
        deliverablePaths = try container.decode([String].self, forKey: .deliverablePaths)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    public mutating func recordCompletion(of goal: String) {
        completedTasks.append(goal)
        if currentGoal == goal { currentGoal = nil }
        updatedAt = Date()
    }
}
