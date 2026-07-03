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
        static let deliverables = "deliverables"
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

    public func listProjectStates() throws -> [ProjectState] {
        try loadAll(ProjectState.self, prefix: Prefix.projectState)
            .sorted { $0.updatedAt > $1.updatedAt }
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

    // MARK: Deliverables (AD-32: only the Store touches disk)

    /// Writes the deliverable as a Markdown file with the goal embedded as
    /// front matter — the file stays a usable asset AND repeated goals can
    /// be matched by search without a second record anywhere.
    public func saveDeliverable(_ content: String, goal: String, for projectID: ProjectID) throws -> String {
        let path = "\(Prefix.deliverables)/\(Self.safeFilename(projectID.rawValue))/\(UUID().uuidString).md"
        let goalLine = goal.replacingOccurrences(of: "\n", with: " ")
        let file = "---\ngoal: \(goalLine)\n---\n\n\(content)"
        try storage.write(Data(file.utf8), key: path)
        return path
    }

    public func deliverableContent(at path: String) throws -> String? {
        guard let data = try storage.read(key: path),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return Self.strippingFrontMatter(from: text)
    }

    // MARK: Search

    /// One walk over all record types. `.exact` keeps the original early-exit
    /// behavior; `.anyWord` gathers hit counts and ranks by relevance
    /// (stores are small — measured optimization belongs to M3/M7).
    public func search(_ query: StoreQuery) throws -> [StoreSearchResult] {
        let matcher = Matcher(query: query)
        var candidates: [(result: StoreSearchResult, hits: Int, order: Int)] = []

        func collect(_ hits: Int, _ result: @autoclosure () -> StoreSearchResult) -> Bool {
            guard hits > 0 else { return false }
            candidates.append((result(), hits, candidates.count))
            return query.matchMode == .exact && candidates.count >= query.limit
        }

        for record in try loadAll(KnowledgeRecord.self, prefix: Prefix.knowledge)
            .sorted(by: { $0.id < $1.id }) {
            if collect(
                matcher.hits(in: record.topic + " " + record.body),
                StoreSearchResult(kind: .knowledge, id: record.id, snippet: record.topic)
            ) { return finalize(candidates, for: query) }
        }
        for record in try loadAll(WorkingContextRecord.self, prefix: Prefix.workingContext)
            .sorted(by: { $0.id < $1.id }) {
            guard !record.isExpired() else { continue }
            if let projectID = query.projectID, record.projectID != projectID { continue }
            if collect(
                matcher.hits(in: record.content),
                StoreSearchResult(kind: .workingContext, id: record.id, snippet: record.content)
            ) { return finalize(candidates, for: query) }
        }
        // Deliverables are found through their index (ProjectState.deliverablePaths,
        // AD-10) — no directory walking.
        let states: [ProjectState]
        if let projectID = query.projectID {
            states = try projectState(for: projectID).map { [$0] } ?? []
        } else {
            states = try loadAll(ProjectState.self, prefix: Prefix.projectState)
        }
        for state in states {
            for path in state.deliverablePaths {
                guard let data = try storage.read(key: path),
                      let text = String(data: data, encoding: .utf8) else { continue }
                let body = Self.strippingFrontMatter(from: text)
                if collect(
                    matcher.hits(in: text),
                    StoreSearchResult(kind: .deliverable, id: path, snippet: String(body.prefix(120)))
                ) { return finalize(candidates, for: query) }
            }
        }
        return finalize(candidates, for: query)
    }

    private func finalize(
        _ candidates: [(result: StoreSearchResult, hits: Int, order: Int)],
        for query: StoreQuery
    ) -> [StoreSearchResult] {
        switch query.matchMode {
        case .exact:
            return Array(candidates.map(\.result).prefix(query.limit))
        case .anyWord:
            return Array(
                candidates
                    .sorted { $0.hits != $1.hits ? $0.hits > $1.hits : $0.order < $1.order }
                    .map(\.result)
                    .prefix(query.limit)
            )
        }
    }

    private struct Matcher {
        private let mode: StoreQuery.MatchMode
        private let needle: String
        private let words: [String]

        init(query: StoreQuery) {
            mode = query.matchMode
            needle = query.text.lowercased()
            words = mode == .anyWord
                ? needle.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                    .map(String.init)
                    .filter { $0.count >= 3 }
                : []
        }

        func hits(in text: String) -> Int {
            let lowered = text.lowercased()
            switch mode {
            case .exact:
                return lowered.contains(needle) ? 1 : 0
            case .anyWord:
                return words.filter { lowered.contains($0) }.count
            }
        }
    }

    // MARK: Private

    /// Record IDs are percent-encoded so arbitrary IDs map to safe filenames.
    private static func safeFilename(_ raw: String) -> String {
        raw.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? raw
    }

    private func key(_ prefix: String, id: String) -> String {
        "\(prefix)/\(Self.safeFilename(id)).json"
    }

    private static func strippingFrontMatter(from text: String) -> String {
        guard text.hasPrefix("---\n"), let end = text.range(of: "\n---\n") else { return text }
        return String(String(text[end.upperBound...]).drop(while: { $0 == "\n" }))
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
