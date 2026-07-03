import Foundation
import OsirisCore

/// A project as the UI sees it — id and display name, nothing more.
public struct ProjectSummary: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// A stored deliverable as the UI sees it: its path (id) and a short preview.
public struct DeliverablePreview: Identifiable, Equatable, Sendable {
    public let id: String
    public let preview: String

    public init(id: String, preview: String) {
        self.id = id
        self.preview = preview
    }
}

/// Everything "resume work instantly" needs (M2-2) — read straight from
/// ProjectState (State Over Chat: the chat transcript is UI-temporary;
/// the real history is state + deliverables).
public struct ProjectOverview: Equatable, Sendable {
    public let name: String
    public let lastGoal: String?
    public let completedCount: Int
    /// Most recent first, capped.
    public let deliverables: [DeliverablePreview]

    public init(name: String, lastGoal: String?, completedCount: Int, deliverables: [DeliverablePreview]) {
        self.name = name
        self.lastGoal = lastGoal
        self.completedCount = completedCount
        self.deliverables = deliverables
    }

    public var isEmpty: Bool {
        completedCount == 0 && deliverables.isEmpty
    }

    /// Pure, platform-testable assembly (the composition root only supplies
    /// `bodyFor` — reading a deliverable body through the Store).
    public static func assemble(
        from state: ProjectState,
        maxDeliverables: Int = 5,
        previewLength: Int = 120,
        bodyFor: @Sendable (String) async throws -> String?
    ) async rethrows -> ProjectOverview {
        var previews: [DeliverablePreview] = []
        for path in state.deliverablePaths.suffix(maxDeliverables).reversed() {
            guard let body = try await bodyFor(path) else { continue }
            previews.append(DeliverablePreview(id: path, preview: String(body.prefix(previewLength))))
        }
        return ProjectOverview(
            name: state.name,
            lastGoal: state.completedTasks.last ?? state.currentGoal,
            completedCount: state.completedTasks.count,
            deliverables: previews
        )
    }
}

/// Port for project management (AD-38). Listing and creating projects is
/// state management, not goal execution — so it does not pass through the
/// Kernel. The composition root wires these closures onto the Store (the
/// single persister); execution results still persist only through the
/// Kernel lifecycle. Same pattern as ProviderSettings: types + closures,
/// no new import edges.
public struct ProjectDirectory: Sendable {
    public let list: @Sendable () async throws -> [ProjectSummary]
    public let create: @Sendable (_ name: String) async throws -> ProjectSummary
    /// Resume data for one project (M2-2); nil when the project has no state yet.
    public let overview: @Sendable (_ projectID: String) async throws -> ProjectOverview?
    /// Full deliverable body, loaded on demand when the user opens one.
    public let deliverableContent: @Sendable (_ path: String) async throws -> String?

    public init(
        list: @escaping @Sendable () async throws -> [ProjectSummary],
        create: @escaping @Sendable (_ name: String) async throws -> ProjectSummary,
        overview: @escaping @Sendable (_ projectID: String) async throws -> ProjectOverview?,
        deliverableContent: @escaping @Sendable (_ path: String) async throws -> String?
    ) {
        self.list = list
        self.create = create
        self.overview = overview
        self.deliverableContent = deliverableContent
    }
}
