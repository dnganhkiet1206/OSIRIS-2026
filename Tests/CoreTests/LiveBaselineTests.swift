import XCTest
@testable import OsirisCore
import OsirisInfrastructure

/// Opt-in LIVE baseline (resolves the Medium "real provider baseline" debt
/// WITHOUT a Mac — the AnthropicProvider is pure Swift and Linux runs the
/// network fine). It makes real, paid API calls, so it is doubly gated and
/// SKIPS by default: it runs only when BOTH `ANTHROPIC_API_KEY` and
/// `OSIRIS_LIVE_BASELINE=1` are set. Never runs in the normal suite/CI
/// unless deliberately enabled.
///
/// Run it:
///   OSIRIS_LIVE_BASELINE=1 ANTHROPIC_API_KEY=sk-... \
///     swift test --filter LiveBaselineTests
/// Then paste the printed BASELINE lines into PROJECT_STATE §4b.
final class LiveBaselineTests: XCTestCase {
    private func liveKeyOrSkip() throws -> String {
        let env = ProcessInfo.processInfo.environment
        guard env["OSIRIS_LIVE_BASELINE"] == "1", let key = env["ANTHROPIC_API_KEY"], !key.isEmpty else {
            throw XCTSkip("Live baseline is opt-in: set OSIRIS_LIVE_BASELINE=1 and ANTHROPIC_API_KEY to run.")
        }
        return key
    }

    /// Real token/latency for representative prompts. Cost is deterministic
    /// from tokens via the shipped catalog (already proven offline), so the
    /// only real unknowns are token counts and latency — captured here.
    func testRealProviderTokenAndLatencyBaseline() async throws {
        let key = try liveKeyOrSkip()
        let modelID = ProcessInfo.processInfo.environment["OSIRIS_LIVE_MODEL"]
            ?? "claude-haiku-4-5-20251001"
        let provider = AnthropicProvider(apiKey: key, maxOutputTokens: 300)

        let prompts = [
            "short": "Summarize in one sentence: the benefits of a morning routine.",
            "medium": "Draft a 150-word product description for a stainless steel water bottle, benefit-led.",
        ]

        for (label, prompt) in prompts.sorted(by: { $0.key < $1.key }) {
            let start = Date()
            let response = try await provider.complete(prompt: prompt, modelID: modelID)
            let latency = Date().timeIntervalSince(start)

            XCTAssertFalse(response.text.isEmpty, "Live response must not be empty")
            let tokensIn = response.tokensIn.map(String.init) ?? "nil"
            let tokensOut = response.tokensOut.map(String.init) ?? "nil"
            print(String(
                format: "BASELINE live model=%@ case=%@ tokensIn=%@ tokensOut=%@ latencySeconds=%.3f",
                modelID, label, tokensIn, tokensOut, latency
            ))
        }
    }
}
