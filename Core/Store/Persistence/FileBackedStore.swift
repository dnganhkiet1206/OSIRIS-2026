import Foundation
import OsirisInfrastructure

/// Durable Store implementation: each record is one JSON file persisted via
/// Infrastructure.LocalStorage. This is the production Store from M0-2 on.
///
/// Layout (NEXT_TASK M0-2 convention):
///   project-state/<projectID>.json
///   knowledge/<id>.json
///   working-context/<id>.json
///
/// Expired WorkingContext records are filtered on read; physical cleanup of
/// expired files is an M1 policy concern.
public actor FileBackedStore: Store {
    private enum Prefix {
        static let projectState = "project-state"
        static let knowledge = "knowledge"
        static let workingContext = "working-context"
    }

    private let storage: any LocalStorage
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(storage: any LocalStorage) {
        self.storage = storage

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    // MARK: ProjectState

    public func projectState(for projectID: ProjectID) throws -> ProjectState? {
        try load(ProjectState.self, key: key(Prefix.projectState, id: projectID.rawValue))
    }

    public func save(_ state: ProjectState) throws {
        try write(state, key: key(Prefix.projectState, id: state.projectID.rawValue))
    }

    // MARK: Knowledge

    public func knowledge(id: String) throws -> KnowledgeRecord? {
        try load(KnowledgeRecord.self, key: key(Prefix.knowledge, id: id))
    }

    public func save(_ record: KnowledgeRecord) throws {
        try write(record, key: key(Prefix.knowledge, id: record.id))
    }

    // MARK: WorkingContext

    public func workingContext(for projectID: ProjectID) throws -> [WorkingContextRecord] {
        try loadAll(WorkingContextRecord.self, prefix: Prefix.workingContext)
            .filter { $0.projectID == projectID && !$0.isExpired() }
            .sorted { $0.id < $1.id }
    }

    public func save(_ record: WorkingContextRecord) throws {
        try write(record, key: key(Prefix.workingContext, id: record.id))
    }

    // MARK: Search (naive substring match; relevance ranking arrives in M1)

    public func search(_ query: StoreQuery) throws -> [StoreSearchResult] {
        let needle = query.text.lowercased()
        var results: [StoreSearchResult] = []

        for record in try loadAll(KnowledgeRecord.self, prefix: Prefix.knowledge)
            .sorted(by: { $0.id < $1.id }) {
            if record.topic.lowercased().contains(needle) || record.body.lowercased().contains(needle) {
                results.append(StoreSearchResult(kind: .knowledge, id: record.id, snippet: record.topic))
            }
        }
        for record in try loadAll(WorkingContextRecord.self, prefix: Prefix.workingContext)
            .sorted(by: { $0.id < $1.id }) {
            guard !record.isExpired() else { continue }
            if let projectID = query.projectID, record.projectID != projectID { continue }
            if record.content.lowercased().contains(needle) {
                results.append(StoreSearchResult(kind: .workingContext, id: record.id, snippet: record.content))
            }
        }
        return Array(results.prefix(query.limit))
    }

    // MARK: Private

    /// Record IDs are percent-encoded so arbitrary IDs map to safe filenames.
    private func key(_ prefix: String, id: String) -> String {
        let safe = id.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? id
        return "\(prefix)/\(safe).json"
    }

    private func load<T: Decodable>(_ type: T.Type, key: String) throws -> T? {
        guard let data = try storage.read(key: key) else { return nil }
        return try decoder.decode(type, from: data)
    }

    private func loadAll<T: Decodable>(_ type: T.Type, prefix: String) throws -> [T] {
        try storage.keys(withPrefix: prefix).compactMap { key in
            try load(type, key: key)
        }
    }

    private func write<T: Encodable>(_ value: T, key: String) throws {
        try storage.write(try encoder.encode(value), key: key)
    }
}
