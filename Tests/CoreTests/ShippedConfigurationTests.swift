import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// Verifies the ACTUAL shipped Config/ files build a valid Gateway
/// configuration — the same fail-fast validation the app runs at launch.
/// Catches config drift (bad model IDs, oversized preamble, broken JSON)
/// before it ever reaches a device.
final class ShippedConfigurationTests: XCTestCase {
    // Mirrors of CompositionRoot's private decode shapes (duplicated by
    // design: this test must fail if the files stop matching them).
    private struct ModelsFile: Decodable { let models: [ModelInfo] }
    private struct RoutingFile: Decodable {
        let defaultModelID: String
        let offlineModelID: String
    }
    private struct BudgetsFile: Decodable {
        let preambleMaxTokens: Int
        let maxTokensPerRequest: Int
        let maxCostPerRequestUSD: Double
        let perRequestMaxOutputTokens: Int
        let contextBudgetTokens: Int
        let maxContextSnippets: Int
    }
    private struct FeaturesFile: Decodable { let aiDryRun: Bool }
    private struct PoliciesFile: Decodable {
        struct AIRetry: Decodable { let maxAttempts: Int }
        let aiRetry: AIRetry
    }

    private static let configDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Config")

    func testShippedConfigBuildsValidGatewayConfiguration() throws {
        let loader = ConfigurationLoader(directory: Self.configDirectory)

        let models = try loader.loadJSON(ModelsFile.self, file: "models.json")
        let routing = try loader.loadJSON(RoutingFile.self, file: "routing.json")
        let budgets = try loader.loadJSON(BudgetsFile.self, file: "budgets.json")
        let features = try loader.loadJSON(FeaturesFile.self, file: "features.json")
        let policies = try loader.loadJSON(PoliciesFile.self, file: "policies.json")
        let preamble = try loader.loadText(file: "preamble.md")

        // Both provider modes must validate: real (default) and offline.
        for modelID in [routing.defaultModelID, routing.offlineModelID] {
            XCTAssertNoThrow(try GatewayConfiguration(
                models: models.models,
                defaultModelID: modelID,
                budget: BudgetPolicy(
                    maxTokensPerRequest: budgets.maxTokensPerRequest,
                    maxCostPerRequestUSD: budgets.maxCostPerRequestUSD,
                    contextBudgetTokens: budgets.contextBudgetTokens,
                    maxContextSnippets: budgets.maxContextSnippets
                ),
                retry: RetryPolicy(maxAttempts: policies.aiRetry.maxAttempts),
                preamble: preamble,
                preambleMaxTokens: budgets.preambleMaxTokens,
                dryRun: features.aiDryRun
            ), "Shipped Config/ must validate for model '\(modelID)'")
        }

        // AD-13 stays enforced on the shipped preamble.
        XCTAssertLessThanOrEqual(TokenEstimator.estimate(preamble), budgets.preambleMaxTokens)
        XCTAssertGreaterThan(budgets.perRequestMaxOutputTokens, 0)
    }
}
