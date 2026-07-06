import XCTest
@testable import OsirisApplication
import OsirisCore

/// M2-2: all resume-assembly logic lives in one pure, platform-testable
/// function — the composition root only supplies data access.
final class ProjectOverviewTests: XCTestCase {
    private func makeState(
        completed: [String] = [],
        deliverablePaths: [String] = []
    ) -> ProjectState {
        var state = ProjectState(projectID: ProjectID("p1"), name: "My Project")
        for goal in completed {
            state.recordCompletion(of: goal)
        }
        state.deliverablePaths = deliverablePaths
        return state
    }

    func testAssemblesNameLastGoalCountAndPreviews() async throws {
        let state = makeState(
            completed: ["first goal", "second goal"],
            deliverablePaths: ["d/a.md", "d/b.md"]
        )
        let bodies = ["d/a.md": "Body of A", "d/b.md": "Body of B"]

        let overview = try await ProjectOverview.assemble(from: state) { bodies[$0] }

        XCTAssertEqual(overview.name, "My Project")
        XCTAssertEqual(overview.lastGoal, "second goal")
        XCTAssertEqual(overview.completedCount, 2)
        XCTAssertEqual(overview.deliverables.map(\.id), ["d/b.md", "d/a.md"], "Most recent deliverable first")
        XCTAssertEqual(overview.deliverables.first?.preview, "Body of B")
        XCTAssertFalse(overview.isEmpty)
    }

    func testCapsDeliverablesAndTruncatesPreviews() async throws {
        let paths = (1...8).map { "d/\($0).md" }
        let state = makeState(completed: ["g"], deliverablePaths: paths)
        let longBody = String(repeating: "x", count: 500)

        let overview = try await ProjectOverview.assemble(
            from: state, maxDeliverables: 5, previewLength: 120
        ) { _ in longBody }

        XCTAssertEqual(overview.deliverables.count, 5, "Capped at the 5 most recent")
        XCTAssertEqual(overview.deliverables.map(\.id).first, "d/8.md")
        XCTAssertEqual(overview.deliverables.first?.preview.count, 120, "Preview is truncated")
    }

    func testEmptyProjectIsSafeAndMarkedEmpty() async throws {
        let overview = try await ProjectOverview.assemble(from: makeState()) { _ in nil }

        XCTAssertNil(overview.lastGoal)
        XCTAssertEqual(overview.completedCount, 0)
        XCTAssertTrue(overview.deliverables.isEmpty)
        XCTAssertTrue(overview.isEmpty)
    }

    func testMissingBodiesAreSkippedNotFailed() async throws {
        let state = makeState(completed: ["g"], deliverablePaths: ["d/ok.md", "d/gone.md"])

        let overview = try await ProjectOverview.assemble(from: state) {
            $0 == "d/ok.md" ? "OK body" : nil
        }

        XCTAssertEqual(overview.deliverables.map(\.id), ["d/ok.md"], "A missing file never breaks resume")
    }
}
