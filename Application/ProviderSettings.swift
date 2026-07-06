import Foundation

/// Whether a real AI provider is configured. All the UI ever learns —
/// never which provider, never the key.
public enum ProviderStatus: Equatable, Sendable {
    case connected
    case offline
}

/// Thin port for provider credentials (AD-35). Defined here so the UI can
/// manage the API key without touching Infrastructure (the arch rules
/// forbid both Presentation→Infrastructure and Application→Infrastructure);
/// the composition root supplies closures backed by the Keychain vault.
/// Provider selection is wired at launch — key changes apply on restart.
public struct ProviderSettings: Sendable {
    public let currentStatus: @Sendable () -> ProviderStatus
    public let setKey: @Sendable (String) throws -> Void
    public let removeKey: @Sendable () throws -> Void

    public init(
        currentStatus: @escaping @Sendable () -> ProviderStatus,
        setKey: @escaping @Sendable (String) throws -> Void,
        removeKey: @escaping @Sendable () throws -> Void
    ) {
        self.currentStatus = currentStatus
        self.setKey = setKey
        self.removeKey = removeKey
    }
}
