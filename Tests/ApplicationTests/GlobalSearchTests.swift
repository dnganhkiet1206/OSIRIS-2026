import XCTest
@testable import OsirisApplication
import OsirisCore

/// M2-3: the search merge is one pure function — project-name matches plus
/// translated Store results, grouped deterministically.
final class GlobalSearchTests: XCTestCase {
    private let projects = [
        ProjectSummary(id: "p1", name: "YouTube Q3"),
        ProjectSummary(id: "p2", name: "Etsy Shop"),
    ]

    func testEmptyOrWhitespaceQueryReturnsNothing() {
        XCTAssertTrue(SearchHit.assemble(query: "", projects: projects, storeResults: []).isEmpty)
        XCTAssertTrue(SearchHit.assemble(query: "   ", projects: projects, storeResults: []).isEmpty)
    }

    func testProjectNamesMatchCaseInsensitively() {
        let hits = SearchHit.assemble(query: "youtube", projects: projects, storeResults: [])

        XCTAssertEqual(hits.count, 1)
        XCTAssertEqual(hits.first?.kind, .project)
        XCTAssertEqual(hits.first?.id, "p1")
        XCTAssertEqual(hits.first?.title, "YouTube Q3")
    }

    func testStoreResultsTranslateAndGroupInOrder() {
        let storeResults = [
            StoreSearchResult(kind: .workingContext, id: "wc1", snippet: "note about thumbnails"),
            StoreSearchResult(kind: .knowledge, id: "k1", snippet: "Thumbnail guidelines"),
            StoreSearchResult(kind: .deliverable, id: "deliverables/p1/x.md", snippet: "Thumbnail concept draft"),
            StoreSearchResult(kind: .projectState, id: "p1", snippet: "ignored"),
        ]

        let hits = SearchHit.assemble(query: "thumbnail", projects: [], storeResults: storeResults)

        XCTAssertEqual(hits.map(\.kind), [.deliverable, .knowledge, .workingContext],
                       "Grouped order: deliverables → knowledge → working context; projectState skipped")
        XCTAssertEqual(hits[0].title, "Thumbnail concept draft",
                       "Deliverables are titled by preview, never by internal path")
        XCTAssertFalse(hits[0].title.contains("deliverables/"))
        XCTAssertEqual(hits[2].snippet, "note about thumbnails")
    }

    func testProjectsComeBeforeStoreResults() {
        let storeResults = [StoreSearchResult(kind: .knowledge, id: "k1", snippet: "YouTube SEO rules")]

        let hits = SearchHit.assemble(query: "youtube", projects: projects, storeResults: storeResults)

        XCTAssertEqual(hits.map(\.kind), [.project, .knowledge])
    }
}
