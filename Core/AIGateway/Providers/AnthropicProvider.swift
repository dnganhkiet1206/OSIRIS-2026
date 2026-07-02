import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Adapter for the Anthropic Messages API.
/// Reference: https://docs.anthropic.com/en/api/messages (version pinned below).
///
/// Per the AIProvider contract this does exactly one thing: turn a prompt
/// into text plus real usage. Validation, budget, cache, retry, dry-run,
/// metrics and logging belong to the Gateway — never reimplement them here.
/// Errors carry an HTTP status and a user-facing hint; they NEVER contain
/// the API key or response bodies.
public struct AnthropicProvider: AIProvider {
    /// Pinned API version; update deliberately, never implicitly.
    static let apiVersion = "2023-06-01"

    public let id = "anthropic"

    private let apiKey: String
    private let endpoint: URL
    private let maxOutputTokens: Int
    private let session: URLSession

    public init(
        apiKey: String,
        maxOutputTokens: Int,
        endpoint: URL = URL(string: "https://api.anthropic.com/v1/messages")!,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.maxOutputTokens = maxOutputTokens
        self.endpoint = endpoint
        self.session = session
    }

    public func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
        let (data, http) = try await perform(makeRequest(prompt: prompt, modelID: modelID))
        guard http.statusCode == 200 else {
            throw AnthropicProviderError.httpStatus(http.statusCode, Self.userHint(forStatus: http.statusCode))
        }
        return try Self.parse(data)
    }

    /// Internal for tests: header/body correctness is asserted on the
    /// URLRequest directly, independent of platform networking quirks.
    func makeRequest(prompt: String, modelID: String) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(Self.apiVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            model: modelID,
            maxTokens: maxOutputTokens,
            messages: [RequestBody.Message(role: "user", content: prompt)]
        ))
        return request
    }

    // MARK: Parsing (static and pure — unit tested offline)

    static func parse(_ data: Data) throws -> ProviderResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let response = try? decoder.decode(APIResponse.self, from: data) else {
            throw AnthropicProviderError.malformedBody("Response did not match the Messages API schema")
        }
        let text = response.content.compactMap { $0.type == "text" ? $0.text : nil }.joined()
        guard !text.isEmpty else {
            throw AnthropicProviderError.malformedBody("Response contained no text content")
        }
        return ProviderResponse(
            text: text,
            tokensIn: response.usage.inputTokens,
            tokensOut: response.usage.outputTokens
        )
    }

    static func userHint(forStatus status: Int) -> String {
        switch status {
        case 401, 403: return "The API key was rejected. Update it and try again."
        case 429: return "Rate limited by the AI service. Wait a moment and try again."
        case 500...599: return "The AI service is temporarily unavailable. Try again shortly."
        default: return "Unexpected response from the AI service."
        }
    }

    // MARK: Wire types

    private struct RequestBody: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let maxTokens: Int
        let messages: [Message]

        enum CodingKeys: String, CodingKey {
            case model
            case maxTokens = "max_tokens"
            case messages
        }
    }

    private struct APIResponse: Decodable {
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }

        struct Usage: Decodable {
            let inputTokens: Int
            let outputTokens: Int
        }

        let content: [ContentBlock]
        let usage: Usage
    }

    // MARK: Networking (continuation-based for cross-platform URLSession)

    private func perform(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            session.dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let http = response as? HTTPURLResponse else {
                    continuation.resume(throwing: AnthropicProviderError.invalidResponse)
                    return
                }
                continuation.resume(returning: (data, http))
            }.resume()
        }
    }
}

/// Provider-level failures. Status + user hint only — no key, no body.
public enum AnthropicProviderError: Error, Equatable, Sendable {
    case invalidResponse
    case httpStatus(Int, String)
    case malformedBody(String)
}
