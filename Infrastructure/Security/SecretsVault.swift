import Foundation

/// Secret storage contract (API keys). The production implementation is
/// Keychain-backed and lives in the app layer where Apple frameworks are
/// available; everything else depends only on this protocol.
///
/// (The InMemorySecretsVault placeholder was removed at the M2 review —
/// zero consumers by its recorded deadline. Test doubles conform to this
/// protocol in-place when needed.)
public protocol SecretsVault: Sendable {
    func secret(for key: String) throws -> String?
    func setSecret(_ value: String, for key: String) throws
    func removeSecret(for key: String) throws
}
