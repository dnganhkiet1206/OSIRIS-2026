import XCTest
@testable import OsirisCore
import OsirisInfrastructure
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Guards the AnthropicProvider security contract (its own doc comment:
/// "Errors carry an HTTP status and a user-facing hint; they NEVER contain
/// the API key or response bodies"). That property was documented but never
/// tested — a future change that folded the key or the raw error body into an
/// error would leak a billing secret into logs/UI unnoticed. A URLProtocol
/// stub returns a 401 whose body even ECHOES the key, the worst case.
final class AnthropicProviderSecurityTests: XCTestCase {
    fileprivate static let secretKey = "sk-ant-SECRET-must-not-leak-000"

    /// Hostile/echoing server: 401 with the key reflected in the body.
    final class UnauthorizedEchoStub: URLProtocol {
        override class func canInit(with request: URLRequest) -> Bool { true }
        override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

        override func startLoading() {
            let body = Data(#"{"error":{"message":"invalid x-api-key \#(AnthropicProviderSecurityTests.secretKey)"}}"#.utf8)
            let response = HTTPURLResponse(
                url: request.url!, statusCode: 401, httpVersion: "HTTP/1.1", headerFields: nil
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        }

        override func stopLoading() {}
    }

    func testProviderErrorNeverContainsKeyOrResponseBody() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UnauthorizedEchoStub.self]
        let session = URLSession(configuration: configuration)
        let provider = AnthropicProvider(apiKey: Self.secretKey, maxOutputTokens: 100, session: session)

        do {
            _ = try await provider.complete(prompt: "hello", modelID: "m1")
            XCTFail("A 401 must throw")
        } catch let error as AnthropicProviderError {
            let rendered = "\(error) \(String(describing: error))"
            XCTAssertFalse(rendered.contains(Self.secretKey), "Error must never contain the API key")
            XCTAssertFalse(rendered.contains("invalid x-api-key"), "Error must never fold in the response body")
            guard case .httpStatus(401, let hint) = error else {
                return XCTFail("Expected httpStatus(401, hint), got \(error)")
            }
            XCTAssertFalse(hint.contains(Self.secretKey), "The user-facing hint must never contain the key")
        }
    }
}
