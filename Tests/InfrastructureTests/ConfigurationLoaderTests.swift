import XCTest
@testable import OsirisInfrastructure

final class ConfigurationLoaderTests: XCTestCase {
    private struct Budgets: Decodable {
        let contextBudgetTokens: Int
    }

    func testLoadsJSONAndText() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("osiris-config-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        try #"{"contextBudgetTokens": 8000}"#
            .write(to: dir.appendingPathComponent("budgets.json"), atomically: true, encoding: .utf8)
        try "You are OSIRIS."
            .write(to: dir.appendingPathComponent("preamble.md"), atomically: true, encoding: .utf8)

        let loader = ConfigurationLoader(directory: dir)
        let budgets = try loader.loadJSON(Budgets.self, file: "budgets.json")
        XCTAssertEqual(budgets.contextBudgetTokens, 8000)
        XCTAssertEqual(try loader.loadText(file: "preamble.md"), "You are OSIRIS.")
    }

    func testMissingFileThrows() {
        let loader = ConfigurationLoader(directory: FileManager.default.temporaryDirectory)
        XCTAssertThrowsError(try loader.loadText(file: "does-not-exist.md"))
    }
}
