import Foundation

/// Secret storage contract (API keys). The production implementation is
/// Keychain-backed and lives in the app layer where Apple frameworks are
/// available; everything else depends only on this protocol.
public protocol SecretsVault: Sendable {
    func secret(for key: String) throws -> String?
    func setSecret(_ value: String, for key: String) throws
    func removeSecret(for key: String) throws
}

/// Non-persistent placeholder used until the Keychain implementation exists
/// (M0-2). Never ships as the production vault.
public final class InMemorySecretsVault: SecretsVault, @unchecked Sendable {
    private let lock = NSLock()
    private var secrets: [String: String] = [:]

    public init() {}

    public func secret(for key: String) throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        return secrets[key]
    }

    public func setSecret(_ value: String, for key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        secrets[key] = value
    }

    public func removeSecret(for key: String) throws {
        lock.lock()
        defer { lock.unlock() }
        secrets[key] = nil
    }
}
