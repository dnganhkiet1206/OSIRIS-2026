import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// M2-1: multi-project — listing, naming, and silent migration of
/// pre-M2 state files that have no name field.
final class ProjectListingTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-projects-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    func testListReturnsMostRecentlyUpdatedFirst() async throws {
        let store = try makeStore()
        var older = ProjectState(projectID: ProjectID("older"), name: "Older")
        older.updatedAt = Date(timeIntervalSinceNow: -3600)
        try await store.save(older)
        try await store.save(ProjectState(projectID: ProjectID("newer"), name: "Newer"))

        let listed = try await store.listProjectStates()
        XCTAssertEqual(listed.map(\.name), ["Newer", "Older"])
    }

    /// Pre-M2 files have no `name` — decoding must fall back to the id,
    /// never fail. Written raw through storage to simulate a legacy file.
    func testLegacyStateWithoutNameMigratesSilently() async throws {
        let storage = try FileStorage(baseDirectory: directory)
        let legacy = """
        {"projectID":{"rawValue":"p1"},"completedTasks":["old work"],"nextTasks":[],
         "architectureDecisions":[],"knownIssues":[],"deliverablePaths":[],
         "updatedAt":"2026-07-01T00:00:00Z"}
        """
        try storage.write(Data(legacy.utf8), key: "project-state/p1.json")

        let store = FileBackedStore(storage: storage)
        let state = try await store.projectState(for: ProjectID("p1"))
        XCTAssertEqual(state?.name, "p1", "Missing name falls back to the id")
        XCTAssertEqual(state?.completedTasks, ["old work"], "Legacy data survives migration")
    }

    func testCreatedProjectKeepsGivenName() async throws {
        let store = try makeStore()
        try await store.save(ProjectState(projectID: ProjectID("abc-123"), name: "YouTube Q3"))

        let loaded = try await store.projectState(for: ProjectID("abc-123"))
        XCTAssertEqual(loaded?.name, "YouTube Q3")
    }
}
