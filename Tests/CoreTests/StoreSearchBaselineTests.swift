import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// Measures `FileBackedStore.search` cost as the Knowledge store grows (AD-15
/// baseline; M7 "measure before you optimize"). `search` re-reads and decodes
/// every record file per query — this records how much that actually costs at
/// realistic single-user scales, so any index/cache is justified by numbers,
/// not by the shape of the code. `.anyWord` is the worst case: it never
/// early-exits, so it always walks the whole store.
///
/// Opt-in: it seeds thousands of files and takes several seconds, so it must
/// not weigh down the lean default suite. Runs only when `OSIRIS_SEARCH_BASELINE=1`
/// is set (same discipline as `LiveBaselineTests`). Numbers are recorded in
/// PROJECT_STATE §4b; assertions are order-of-magnitude sanity bounds, not a gate.
///
/// Run it:
///   OSIRIS_SEARCH_BASELINE=1 swift test -c release --filter StoreSearchBaselineTests
final class StoreSearchBaselineTests: XCTestCase {
    private var directory: URL!

    private func enabledOrSkip() throws {
        guard ProcessInfo.processInfo.environment["OSIRIS_SEARCH_BASELINE"] == "1" else {
            throw XCTSkip("Store-search baseline is opt-in: set OSIRIS_SEARCH_BASELINE=1 to run.")
        }
    }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-search-baseline-\(UUID().uuidString)")
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    private func makeStore() throws -> FileBackedStore {
        FileBackedStore(storage: try FileStorage(baseDirectory: directory))
    }

    private func seedKnowledge(_ store: FileBackedStore, count: Int) async throws {
        for i in 0..<count {
            try await store.save(KnowledgeRecord(
                id: "k-\(i)",
                topic: "topic number \(i) about planning and focus",
                body: "body text for record \(i): productivity, execution, review, delivery, outcome"
            ))
        }
    }

    private func meanSearchMillis(
        _ store: FileBackedStore,
        text: String,
        mode: StoreQuery.MatchMode,
        iterations: Int
    ) async throws -> Double {
        // Warm-up (first read primes any FS caches).
        _ = try await store.search(StoreQuery(text: text, matchMode: mode))
        let start = Date()
        for _ in 0..<iterations {
            _ = try await store.search(StoreQuery(text: text, matchMode: mode))
        }
        return Date().timeIntervalSince(start) / Double(iterations) * 1000
    }

    func testSearchCostAcrossStoreSizes() async throws {
        try enabledOrSkip()
        let iterations = 20
        for size in [100, 500, 2000] {
            let store = try makeStore()
            try await seedKnowledge(store, count: size)

            let exact = try await meanSearchMillis(store, text: "delivery outcome", mode: .exact, iterations: iterations)
            let anyWord = try await meanSearchMillis(store, text: "planning focus productivity", mode: .anyWord, iterations: iterations)

            print("BASELINE store-search size=\(size) exact-mean=\(String(format: "%.3f", exact)) ms  anyWord-mean=\(String(format: "%.3f", anyWord)) ms")

            // Order-of-magnitude sanity: even the full-walk worst case must stay
            // well under a tenth of a second for a single-user store.
            XCTAssertLessThan(anyWord, 100)
        }
    }
}
