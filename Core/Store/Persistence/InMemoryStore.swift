import Foundation

/// In-memory Store used for bootstrap and tests. The durable file-backed
/// implementation (on Infrastructure.LocalStorage) is task M0-6.
public actor InMemoryStore: Store {
    private var projectStates: [ProjectID: ProjectState] = [:]
    private var knowledgeRecords: [String: KnowledgeRecord] = [:]
    private var workingContextRecords: [String: WorkingContextRecord] = [:]

    public init() {}

    // MARK: ProjectState

    public func projectState(for projectID: ProjectID) throws -> ProjectState? {
        projectStates[projectID]
    }

    public func save(_ state: ProjectState) throws {
        projectStates[state.projectID] = state
    }

    // MARK: Knowledge

    public func knowledge(id: String) throws -> KnowledgeRecord? {
        knowledgeRecords[id]
    }

    public func save(_ record: KnowledgeRecord) throws {
        knowledgeRecords[record.id] = record
    }

    // MARK: WorkingContext

    public func workingContext(for projectID: ProjectID) throws -> [WorkingContextRecord] {
        workingContextRecords.values
            .filter { $0.projectID == projectID && !$0.isExpired() }
            .sorted { $0.id < $1.id }
    }

    public func save(_ record: WorkingContextRecord) throws {
        workingContextRecords[record.id] = record
    }

    // MARK: Search (naive substring match; relevance ranking arrives in M1)

    public func search(_ query: StoreQuery) throws -> [StoreSearchResult] {
        let needle = query.text.lowercased()
        var results: [StoreSearchResult] = []

        for record in knowledgeRecords.values.sorted(by: { $0.id < $1.id }) {
            if record.topic.lowercased().contains(needle) || record.body.lowercased().contains(needle) {
                results.append(StoreSearchResult(kind: .knowledge, id: record.id, snippet: record.topic))
            }
        }
        for record in workingContextRecords.values.sorted(by: { $0.id < $1.id }) {
            guard !record.isExpired() else { continue }
            if let projectID = query.projectID, record.projectID != projectID { continue }
            if record.content.lowercased().contains(needle) {
                results.append(StoreSearchResult(kind: .workingContext, id: record.id, snippet: record.content))
            }
        }
        return Array(results.prefix(query.limit))
    }
}
