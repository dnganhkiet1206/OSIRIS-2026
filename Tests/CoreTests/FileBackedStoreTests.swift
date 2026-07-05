import XCTest
@testable import OsirisCore
import OsirisInfrastructure

final class FileBackedStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-store-test-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    func testProjectStateRoundtrip() async throws {
        let store = try makeStore()
        var state = ProjectState(projectID: ProjectID("p1"))
        state.currentGoal = "Persist me"
        try await store.save(state)

        let loaded = try await store.projectState(for: ProjectID("p1"))
        XCTAssertEqual(loaded?.currentGoal, "Persist me")
    }

    /// The M0 success criterion: state survives an app restart. A new store
    /// instance over the same directory must read what the old one wrote.
    func testProjectStateSurvivesRestart() async throws {
        var state = ProjectState(projectID: ProjectID("p1"))
        state.currentGoal = "Survive restart"
        state.completedTasks = ["bootstrap"]
        try await makeStore().save(state)

        let reopened = try makeStore()
        let loaded = try await reopened.projectState(for: ProjectID("p1"))
        XCTAssertEqual(loaded?.currentGoal, "Survive restart")
        XCTAssertEqual(loaded?.completedTasks, ["bootstrap"])
    }

    func testWorkingContextExpiryFilteredOnRead() async throws {
        let store = try makeStore()
        let projectID = ProjectID("p1")
        try await store.save(WorkingContextRecord(
            id: "live", projectID: projectID, content: "current",
            expiresAt: Date().addingTimeInterval(3600)
        ))
        try await store.save(WorkingContextRecord(
            id: "expired", projectID: projectID, content: "old",
            expiresAt: Date().addingTimeInterval(-1)
        ))

        let records = try await store.workingContext(for: projectID)
        XCTAssertEqual(records.map(\.id), ["live"])
    }

    func testSearchFindsKnowledgeAcrossRestartAndRespectsLimit() async throws {
        try await makeStore().save(KnowledgeRecord(id: "k1", topic: "Routing rules", body: "Pick smallest model"))
        try await makeStore().save(KnowledgeRecord(id: "k2", topic: "Routing extras", body: "More notes"))

        let store = try makeStore()
        let all = try await store.search(StoreQuery(text: "routing"))
        XCTAssertEqual(all.count, 2)

        let limited = try await store.search(StoreQuery(text: "routing", limit: 1))
        XCTAssertEqual(limited.count, 1)
    }

    /// `.anyWord` ranking feeds Gateway context retrieval (which searches with
    /// `.anyWord`), so the order it returns decides what context the AI sees.
    /// Contract: rank by number of distinct query words matched (desc), break
    /// ties by stable walk order (ascending id), and respect the limit.
    func testAnyWordSearchRanksByHitCountThenStableOrder() async throws {
        let store = try makeStore()
        // Query = "alpha bravo charlie" (three words, each ≥3 chars → all count).
        try await store.save(KnowledgeRecord(id: "k-one-hit", topic: "alpha", body: "only one match"))
        try await store.save(KnowledgeRecord(id: "k-three-hits", topic: "alpha bravo", body: "charlie too"))
        try await store.save(KnowledgeRecord(id: "k-two-hits-a", topic: "alpha bravo", body: "no third"))
        try await store.save(KnowledgeRecord(id: "k-two-hits-b", topic: "bravo charlie", body: "no first"))

        let ranked = try await store.search(StoreQuery(text: "alpha bravo charlie", matchMode: .anyWord))
        XCTAssertEqual(
            ranked.map(\.id),
            ["k-three-hits", "k-two-hits-a", "k-two-hits-b", "k-one-hit"],
            "3 hits first; the two 2-hit records tie-break by ascending id; 1 hit last"
        )

        let limited = try await store.search(StoreQuery(text: "alpha bravo charlie", limit: 2, matchMode: .anyWord))
        XCTAssertEqual(limited.map(\.id), ["k-three-hits", "k-two-hits-a"], "Top-ranked survive the limit")
    }

    func testUnusualIDsMapToSafeFilenames() async throws {
        let store = try makeStore()
        let weirdID = ProjectID("p/1 ../x")
        try await store.save(ProjectState(projectID: weirdID))

        let loaded = try await store.projectState(for: weirdID)
        XCTAssertEqual(loaded?.projectID, weirdID)
    }
}
