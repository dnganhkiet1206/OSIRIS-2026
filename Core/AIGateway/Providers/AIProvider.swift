import Foundation

/// Provider adapter contract — the standard every future provider must
/// follow. Providers do exactly one thing: turn a prompt into text and
/// report what the API actually consumed. Everything else (validation,
/// budget, cache, retry, dry-run, metrics, logging) is the Gateway's job —
/// never reimplement it inside an adapter.
public protocol AIProvider: Sendable {
    var id: String { get }
    func complete(prompt: String, modelID: String) async throws -> ProviderResponse
    /// Preferred entry point: the OSIRIS behaviour contract (system) is kept
    /// separate from the task (user) so each provider can route the contract
    /// to its strongest instruction channel — Anthropic `system`, OpenAI/Grok/
    /// Mistral/Qwen/DeepSeek `role: "system"`, Gemini `systemInstruction`.
    /// System instructions outrank user text in every major provider's
    /// hierarchy, so a persistent contract (identity, language) belongs here.
    func complete(systemPrompt: String, userPrompt: String, modelID: String) async throws -> ProviderResponse
}

public extension AIProvider {
    /// Faithful fallback for providers (and test doubles) that don't separate
    /// the two channels: concatenate exactly as before. Overriding providers
    /// route `systemPrompt` to their system channel instead.
    func complete(systemPrompt: String, userPrompt: String, modelID: String) async throws -> ProviderResponse {
        let combined = systemPrompt.isEmpty ? userPrompt : "\(systemPrompt)\n\n\(userPrompt)"
        return try await complete(prompt: combined, modelID: modelID)
    }
}

/// What a provider reports back. Token counts are optional because not every
/// provider reports them; the Gateway falls back to estimates.
public struct ProviderResponse: Sendable {
    public let text: String
    public let tokensIn: Int?
    public let tokensOut: Int?

    public init(text: String, tokensIn: Int? = nil, tokensOut: Int? = nil) {
        self.text = text
        self.tokensIn = tokensIn
        self.tokensOut = tokensOut
    }
}

/// Deterministic offline provider: no network, no tokens, no cost. The only
/// provider until the Core is complete — real adapters are integrations and
/// arrive in a later milestone, after the Gateway is stable.
public struct PlaceholderAIProvider: AIProvider {
    /// Fixed offline answer. It must NEVER echo the prompt: the prompt carries
    /// OSIRIS's system contract (preamble) and the retrieved context, which are
    /// internal — echoing them made those strings a user-visible answer AND a
    /// persisted deliverable that retrieval then surfaced as "Previous results".
    static let offlineAnswer =
        "OSIRIS is running in offline mode — no AI provider is connected. Add an API key in Settings to get real answers."

    public let id = "placeholder"

    public init() {}

    public func complete(prompt: String, modelID: String) async throws -> ProviderResponse {
        // `prompt` is intentionally ignored — a stand-in never returns the
        // prompt. Token count still reflects the input size for metrics.
        ProviderResponse(
            text: Self.offlineAnswer,
            tokensIn: TokenEstimator.estimate(prompt),
            tokensOut: 0
        )
    }
}
