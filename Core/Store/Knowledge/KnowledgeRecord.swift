import Foundation

/// A searchable record describing how OSIRIS itself works (architecture,
/// standards, routing rules). Knowledge explains the system; ProjectState
/// explains the project; WorkingContext explains the current task — never
/// confuse the three. Update once, reference everywhere.
public struct KnowledgeRecord: Codable, Sendable {
    public let id: String
    public var topic: String
    public var body: String
    public var updatedAt: Date

    public init(id: String, topic: String, body: String, updatedAt: Date = Date()) {
        self.id = id
        self.topic = topic
        self.body = body
        self.updatedAt = updatedAt
    }
}
