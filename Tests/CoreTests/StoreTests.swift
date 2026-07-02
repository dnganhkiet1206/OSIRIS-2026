import XCTest
@testable import OsirisCore

final class StoreTests: XCTestCase {
    func testProjectStateRoundtrip() async throws {
        let store = InMemoryStore()
        let projectID = ProjectID("p1")

        var state = ProjectState(projectID: projectID)
        state.currentGoal = "Bootstrap the platform"
        try await store.save(state)

        let loaded = try await store.projectState(for: projectID)
        XCTAssertEqual(loaded?.currentGoal, "Bootstrap the platform")
    }

    func testWorkingContextExpiry() async throws {
        let store = InMemoryStore()
        let projectID = ProjectID("p1")

        let live = WorkingContextRecord(
            id: "live", projectID: projectID, content: "current research",
            expiresAt: Date().addingTimeInterval(3600)
        )
        let expired = WorkingContextRecord(
            id: "expired", projectID: projectID, content: "old scratch",
            expiresAt: Date().addingTimeInterval(-1)
        )
        try await store.save(live)
        try await store.save(expired)

        let records = try await store.workingContext(for: projectID)
        XCTAssertEqual(records.map(\.id), ["live"])
    }

    func testSearchFindsKnowledgeAndRespectsLimit() async throws {
        let store = InMemoryStore()
        try await store.save(KnowledgeRecord(id: "k1", topic: "Routing rules", body: "Pick smallest model"))
        try await store.save(KnowledgeRecord(id: "k2", topic: "Routing extras", body: "More routing notes"))

        let all = try await store.search(StoreQuery(text: "routing"))
        XCTAssertEqual(all.count, 2)

        let limited = try await store.search(StoreQuery(text: "routing", limit: 1))
        XCTAssertEqual(limited.count, 1)
    }
}
