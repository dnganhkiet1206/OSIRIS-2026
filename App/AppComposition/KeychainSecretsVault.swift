import Foundation
import OsirisInfrastructure
import Security

/// Production SecretsVault backed by the iOS/macOS Keychain. Lives in the
/// app layer where the Security framework exists; everything else depends
/// only on the SecretsVault protocol. Secrets never appear in logs,
/// prompts, config files or error messages.
final class KeychainSecretsVault: SecretsVault {
    private let service = "com.osiris.secrets"

    func secret(for key: String) throws -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess, let data = item as? Data else {
            throw KeychainError.readFailed(status)
        }
        return String(data: data, encoding: .utf8)
    }

    func setSecret(_ value: String, for key: String) throws {
        let data = Data(value.utf8)
        var query = baseQuery(for: key)
        let update = [kSecValueData as String: data]

        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            // Device-local secret: never leaves this device (excluded from
            // encrypted backups and iCloud Keychain), and readable after first
            // unlock so it is available without keeping the app foregrounded.
            // Accessibility belongs only on the ADD — never in the search
            // query, which would break matching on read/update/delete.
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(query as CFDictionary, nil)
            guard addStatus == errSecSuccess else { throw KeychainError.writeFailed(addStatus) }
        } else if status != errSecSuccess {
            throw KeychainError.writeFailed(status)
        }
    }

    func removeSecret(for key: String) throws {
        let status = SecItemDelete(baseQuery(for: key) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    private func baseQuery(for key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
    }

    enum KeychainError: Error {
        case readFailed(OSStatus)
        case writeFailed(OSStatus)
        case deleteFailed(OSStatus)
    }
}
