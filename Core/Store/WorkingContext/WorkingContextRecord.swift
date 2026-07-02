import Foundation

/// Temporary task-scoped context (current file, current error, current
/// research). Always carries an expiry — working context that outlives its
/// task is a design failure (AD-22). Never promoted to permanent storage
/// without passing the write gate (AD-20).
public struct WorkingContextRecord: Codable, Sendable {
    public let id: String
    public let projectID: ProjectID
    public var content: String
    public let expiresAt: Date

    public init(id: String, projectID: ProjectID, content: String, expiresAt: Date) {
        self.id = id
        self.projectID = projectID
        self.content = content
        self.expiresAt = expiresAt
    }

    public func isExpired(at date: Date = Date()) -> Bool {
        date >= expiresAt
    }
}
