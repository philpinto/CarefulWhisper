import Foundation
import Security

/// Helper for storing and retrieving sensitive data in the iOS Keychain
enum KeychainHelper {
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
        case invalidData
    }
    
    /// Accessibility options for keychain items
    enum Accessibility {
        case afterFirstUnlock
        case afterFirstUnlockThisDeviceOnly
        case whenUnlocked
        case whenUnlockedThisDeviceOnly
        
        var secAttrValue: CFString {
            switch self {
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        }
    }
    
    // MARK: - Generic Password Operations
    
    /// Saves data to the keychain as a generic password
    /// - Parameters:
    ///   - data: The data to store
    ///   - account: Unique identifier for the keychain item
    ///   - service: Service name (defaults to app bundle identifier)
    ///   - accessibility: When the keychain item should be accessible
    static func save(
        _ data: Data,
        account: String,
        service: String = Bundle.main.bundleIdentifier ?? "com.carefulwhisper",
        accessibility: Accessibility = .afterFirstUnlockThisDeviceOnly
    ) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.secAttrValue
        ]
        
        // Delete existing item if present
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieves data from the keychain
    /// - Parameters:
    ///   - account: Unique identifier for the keychain item
    ///   - service: Service name (defaults to app bundle identifier)
    /// - Returns: The stored data
    static func load(
        account: String,
        service: String = Bundle.main.bundleIdentifier ?? "com.carefulwhisper"
    ) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    /// Deletes an item from the keychain
    /// - Parameters:
    ///   - account: Unique identifier for the keychain item
    ///   - service: Service name (defaults to app bundle identifier)
    static func delete(
        account: String,
        service: String = Bundle.main.bundleIdentifier ?? "com.carefulwhisper"
    ) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Checks if an item exists in the keychain
    /// - Parameters:
    ///   - account: Unique identifier for the keychain item
    ///   - service: Service name (defaults to app bundle identifier)
    /// - Returns: True if the item exists
    static func exists(
        account: String,
        service: String = Bundle.main.bundleIdentifier ?? "com.carefulwhisper"
    ) -> Bool {
        do {
            _ = try load(account: account, service: service)
            return true
        } catch {
            return false
        }
    }
    
    /// Updates existing keychain data
    /// - Parameters:
    ///   - data: The new data to store
    ///   - account: Unique identifier for the keychain item
    ///   - service: Service name (defaults to app bundle identifier)
    static func update(
        _ data: Data,
        account: String,
        service: String = Bundle.main.bundleIdentifier ?? "com.carefulwhisper"
    ) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
