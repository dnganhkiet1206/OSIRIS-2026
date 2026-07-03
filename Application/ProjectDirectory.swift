import Foundation

/// A project as the UI sees it — id and display name, nothing more.
public struct ProjectSummary: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
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

    public init(
        list: @escaping @Sendable () async throws -> [ProjectSummary],
        create: @escaping @Sendable (_ name: String) async throws -> ProjectSummary
    ) {
        self.list = list
        self.create = create
    }
}
