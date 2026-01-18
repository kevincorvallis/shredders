import Foundation
import Security

/// Secure Keychain storage for JWT tokens
/// Uses iOS Keychain Services for encrypted storage
enum KeychainHelper {
    // MARK: - Keys

    private enum Keys {
        static let accessToken = "com.powdertracker.accessToken"
        static let refreshToken = "com.powdertracker.refreshToken"
        static let tokenExpiry = "com.powdertracker.tokenExpiry"
    }

    // MARK: - Error Handling

    enum KeychainError: Error, LocalizedError {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
        case encodingFailed
        case decodingFailed

        var errorDescription: String? {
            switch self {
            case .itemNotFound:
                return "Item not found in Keychain"
            case .duplicateItem:
                return "Item already exists in Keychain"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status)"
            case .encodingFailed:
                return "Failed to encode data"
            case .decodingFailed:
                return "Failed to decode data"
            }
        }
    }

    // MARK: - Token Storage

    /// Store access token securely
    static func saveAccessToken(_ token: String) throws {
        try save(key: Keys.accessToken, value: token)
    }

    /// Retrieve access token
    static func getAccessToken() -> String? {
        return get(key: Keys.accessToken)
    }

    /// Store refresh token securely
    static func saveRefreshToken(_ token: String) throws {
        try save(key: Keys.refreshToken, value: token)
    }

    /// Retrieve refresh token
    static func getRefreshToken() -> String? {
        return get(key: Keys.refreshToken)
    }

    /// Store token expiry timestamp
    static func saveTokenExpiry(_ date: Date) throws {
        let timestamp = String(date.timeIntervalSince1970)
        try save(key: Keys.tokenExpiry, value: timestamp)
    }

    /// Retrieve token expiry timestamp
    static func getTokenExpiry() -> Date? {
        guard let timestampString = get(key: Keys.tokenExpiry),
              let timestamp = Double(timestampString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    /// Store both tokens at once
    static func saveTokens(accessToken: String, refreshToken: String, expiresIn: TimeInterval? = nil) throws {
        try saveAccessToken(accessToken)
        try saveRefreshToken(refreshToken)

        if let expiresIn = expiresIn {
            let expiryDate = Date().addingTimeInterval(expiresIn)
            try saveTokenExpiry(expiryDate)
        }
    }

    /// Check if access token is expired (with 60-second buffer)
    static func isAccessTokenExpired() -> Bool {
        guard let expiry = getTokenExpiry() else {
            // If no expiry stored, consider it expired
            return true
        }
        // Add 60-second buffer for network latency
        return Date().addingTimeInterval(60) >= expiry
    }

    /// Check if we have valid tokens stored
    static func hasValidTokens() -> Bool {
        return getAccessToken() != nil && getRefreshToken() != nil
    }

    /// Clear all stored tokens (for logout)
    static func clearTokens() {
        delete(key: Keys.accessToken)
        delete(key: Keys.refreshToken)
        delete(key: Keys.tokenExpiry)
    }

    // MARK: - Generic Keychain Operations

    private static func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        // First, try to delete any existing item
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    private static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    @discardableResult
    private static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
