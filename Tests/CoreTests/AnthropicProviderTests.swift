import XCTest
@testable import OsirisCore

/// Offline tests only — fixtures, never the network (NEXT_TASK M0-6 rule).
final class AnthropicProviderTests: XCTestCase {
    func testParsesTextAndRealUsage() throws {
        let fixture = Data("""
        {
          "id": "msg_01",
          "type": "message",
          "role": "assistant",
          "model": "claude-haiku-4-5-20251001",
          "content": [
            {"type": "text", "text": "Hello"},
            {"type": "text", "text": " world"}
          ],
          "usage": {"input_tokens": 12, "output_tokens": 5}
        }
        """.utf8)

        let response = try AnthropicProvider.parse(fixture)

        XCTAssertEqual(response.text, "Hello world")
        XCTAssertEqual(response.tokensIn, 12)
        XCTAssertEqual(response.tokensOut, 5)
    }

    func testIgnoresNonTextContentBlocks() throws {
        let fixture = Data("""
        {
          "content": [
            {"type": "tool_use", "text": null},
            {"type": "text", "text": "Answer"}
          ],
          "usage": {"input_tokens": 3, "output_tokens": 2}
        }
        """.utf8)

        let response = try AnthropicProvider.parse(fixture)
        XCTAssertEqual(response.text, "Answer")
    }

    func testMalformedBodyThrows() {
        XCTAssertThrowsError(try AnthropicProvider.parse(Data("not json".utf8)))
        XCTAssertThrowsError(try AnthropicProvider.parse(Data(#"{"content": [], "usage": {"input_tokens": 1, "output_tokens": 1}}"#.utf8)))
    }

    func testHTTPStatusHintsAreActionableAndLeakNothing() {
        for status in [401, 403, 429, 500, 503, 418] {
            let hint = AnthropicProvider.userHint(forStatus: status)
            XCTAssertFalse(hint.isEmpty)
            XCTAssertFalse(hint.contains("sk-"), "Hints must never contain key material")
            XCTAssertFalse(hint.lowercased().contains("anthropic"), "Hints stay provider-neutral for the UI")
        }
        XCTAssertTrue(AnthropicProvider.userHint(forStatus: 401).contains("key"))
        XCTAssertTrue(AnthropicProvider.userHint(forStatus: 429).lowercased().contains("wait"))
    }
}
