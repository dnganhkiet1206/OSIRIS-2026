import Foundation

/// The single source of truth for all persistent platform data (AD-22).
/// Three record types with one owner each: ProjectState / Knowledge /
/// WorkingContext. Vision is NOT here — it is a static Config artifact
/// (AD-23). Search is a Store capability serving the Decide phase (reuse
/// checks), the AI Gateway (context retrieval) and Global Search.
///
/// There is deliberately no separate "State Store" or "Memory Store";
/// recreating either violates the architecture (SYSTEM_COMPONENTS.md §6).
public protocol Store: Sendable {
    // ProjectState
    func projectState(for projectID: ProjectID) async throws -> ProjectState?
    func save(_ state: ProjectState) async throws
    /// All projects, most recently updated first (M2-1 — feeds the UI's
    /// project list through the ProjectDirectory port, AD-38).
    func listProjectStates() async throws -> [ProjectState]

    // Knowledge
    func knowledge(id: String) async throws -> KnowledgeRecord?
    func save(_ record: KnowledgeRecord) async throws

    // WorkingContext (TTL — expired records are never returned)
    func workingContext(for projectID: ProjectID) async throws -> [WorkingContextRecord]
    func save(_ record: WorkingContextRecord) async throws

    // Deliverables (AD-10, AD-32): files on disk are the source of truth,
    // written ONLY by the Store; ProjectState.deliverablePaths is the
    // derived index maintained by the Kernel's Persist phase. The goal is
    // embedded in the file so reuse detection can match repeated goals.
    func saveDeliverable(_ content: String, goal: String, for projectID: ProjectID) async throws -> String
    func deliverableContent(at path: String) async throws -> String?

    // Search across record types
    func search(_ query: StoreQuery) async throws -> [StoreSearchResult]
}

public struct StoreQuery: Sendable {
    /// How records match the query text (M1-2). `.exact` is the default and
    /// keeps the strict behavior the Kernel's reuse depends on (the full
    /// text must appear — prefer a miss over a wrong match). `.anyWord` is
    /// relevance retrieval for the Gateway's context assembly: any word
    /// (≥3 chars) may match; results rank by hit count.
    public enum MatchMode: Sendable {
        case exact
        case anyWord
    }

    public let text: String
    public let projectID: ProjectID?
    public let limit: Int
    public let matchMode: MatchMode

    public init(text: String, projectID: ProjectID? = nil, limit: Int = 10, matchMode: MatchMode = .exact) {
        self.text = text
        self.projectID = projectID
        self.limit = limit
        self.matchMode = matchMode
    }
}

public struct StoreSearchResult: Sendable {
    public enum Kind: Sendable {
        case projectState, knowledge, workingContext, deliverable
    }

    public let kind: Kind
    public let id: String
    public let snippet: String

    public init(kind: Kind, id: String, snippet: String) {
        self.kind = kind
        self.id = id
        self.snippet = snippet
    }
}
