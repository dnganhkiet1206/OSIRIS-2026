import XCTest
@testable import OsirisCore
import OsirisInfrastructure
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// End-to-end verification of the Anthropic integration WITHOUT touching
/// the network: a URLProtocol stub intercepts the real URLSession request
/// the provider builds, so headers, body, parsing, usage and cost
/// accounting are all exercised exactly as in production.
final class AnthropicProviderIntegrationTests: XCTestCase {
    /// Captures the outgoing request and returns a canned Messages response.
    final class MessagesAPIStub: URLProtocol {
        static var capturedHeaders: [String: String] = [:]
        static var capturedBody: Data?

        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            Self.capturedHeaders = request.allHTTPHeaderFields ?? [:]
            Self.capturedBody = request.httpBody ?? request.httpBodyStream.map { stream in
                stream.open()
                defer { stream.close() }
                var data = Data()
                let bufferSize = 4096
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { buffer.deallocate() }
                while stream.hasBytesAvailable {
                    let read = stream.read(buffer, maxLength: bufferSize)
                    guard read > 0 else { break }
                    data.append(buffer, count: read)
                }
                return data
            }

            let fixture = Data("""
            {
              "content": [{"type": "text", "text": "Baseline reply"}],
              "usage": {"input_tokens": 1000, "output_tokens": 500}
            }
            """.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: fixture)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    func testFullGatewayToProviderRoundTripWithCostAccounting() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MessagesAPIStub.self]
        let session = URLSession(configuration: configuration)

        let provider = AnthropicProvider(
            apiKey: "test-key-not-real",
            maxOutputTokens: 4000,
            session: session
        )
        let gateway = DefaultAIGateway(
            provider: provider,
            configuration: try GatewayConfiguration(
                models: [ModelInfo(
                    id: "claude-haiku-4-5-20251001", tier: .light,
                    inputCostPer1MTokens: 1.0, outputCostPer1MTokens: 5.0
                )],
                defaultModelID: "claude-haiku-4-5-20251001",
                budget: BudgetPolicy(maxTokensPerRequest: 8000, maxCostPerRequestUSD: 0.5),
                retry: .none,
                preamble: "You are OSIRIS.",
                preambleMaxTokens: 400,
                dryRun: false
            ),
            logger: ConsoleLogger()
        )

        let response = try await gateway.complete(AIRequest(task: "Say hello"))

        // Response and REAL usage propagated end to end.
        XCTAssertEqual(response.text, "Baseline reply")
        XCTAssertEqual(response.metrics.actualTokensIn, 1000)
        XCTAssertEqual(response.metrics.actualTokensOut, 500)
        // Cost from catalog pricing: 1000/1M * $1 + 500/1M * $5 = $0.0035.
        XCTAssertEqual(response.metrics.costUSD, 0.0035, accuracy: 0.000001)
        XCTAssertEqual(response.metrics.providerID, "anthropic")

        // Headers are asserted on the URLRequest directly (Linux's
        // URLProtocol does not surface request headers — platform quirk,
        // discovered in M0 final verification).
        let request = try provider.makeRequest(systemPrompt: "sys", userPrompt: "x", modelID: "m")
        XCTAssertEqual(request.value(forHTTPHeaderField: "anthropic-version"), AnthropicProvider.apiVersion)
        XCTAssertEqual(request.value(forHTTPHeaderField: "x-api-key"), "test-key-not-real")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try XCTUnwrap(MessagesAPIStub.capturedBody)
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["model"] as? String, "claude-haiku-4-5-20251001")
        XCTAssertEqual(json["max_tokens"] as? Int, 4000)
        // The OSIRIS contract (preamble) rides the Anthropic `system` field —
        // its strongest instruction channel — not the user message.
        XCTAssertEqual(json["system"] as? String, "You are OSIRIS.", "Preamble must be the system prompt")
        let messages = try XCTUnwrap(json["messages"] as? [[String: Any]])
        XCTAssertEqual(messages.count, 1)
        let content = try XCTUnwrap(messages.first?["content"] as? String)
        XCTAssertEqual(messages.first?["role"] as? String, "user")
        XCTAssertTrue(content.contains("Say hello"), "The task is the user message")
        XCTAssertFalse(content.contains("You are OSIRIS."), "The contract must not leak into the user message")
    }
}
