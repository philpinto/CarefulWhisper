import Foundation
import CryptoKit

/// Service responsible for generating, storing, and managing cryptographic keys
/// Uses Curve25519 for key agreement (X25519) - the same algorithm used by Signal Protocol
actor KeyManagementService {
    
    // MARK: - Constants
    
    private enum KeychainKeys {
        static let identityPrivateKey = "identity.privateKey"
        static let identityPublicKey = "identity.publicKey"
        static let signingPrivateKey = "signing.privateKey"
        static let signingPublicKey = "signing.publicKey"
        static let registrationId = "registration.id"
    }
    
    // MARK: - Errors
    
    enum KeyManagementError: Error {
        case keyGenerationFailed
        case keyNotFound
        case keyStorageFailed(underlying: Error)
        case keyRetrievalFailed(underlying: Error)
        case invalidKeyData
    }
    
    // MARK: - Types
    
    /// Contains both public and private keys for identity
    struct IdentityKeyPair: Sendable {
        let privateKey: Curve25519.KeyAgreement.PrivateKey
        let publicKey: Curve25519.KeyAgreement.PublicKey
        
        /// The raw bytes of the public key (32 bytes)
        var publicKeyData: Data {
            publicKey.rawRepresentation
        }
        
        /// The raw bytes of the private key (32 bytes)
        var privateKeyData: Data {
            privateKey.rawRepresentation
        }
    }
    
    /// Contains signing keys for message authentication
    struct SigningKeyPair: Sendable {
        let privateKey: Curve25519.Signing.PrivateKey
        let publicKey: Curve25519.Signing.PublicKey
        
        var publicKeyData: Data {
            publicKey.rawRepresentation
        }
        
        var privateKeyData: Data {
            privateKey.rawRepresentation
        }
    }
    
    // MARK: - Singleton
    
    static let shared = KeyManagementService()
    
    private init() {}
    
    // MARK: - Identity Key Management
    
    /// Generates a new identity key pair and stores it securely in the Keychain
    /// This should only be called once during initial app setup
    func generateAndStoreIdentityKeys() throws -> IdentityKeyPair {
        // Generate new Curve25519 key pair for key agreement
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Store private key in Keychain
        do {
            try KeychainHelper.save(
                privateKey.rawRepresentation,
                account: KeychainKeys.identityPrivateKey,
                accessibility: .afterFirstUnlockThisDeviceOnly
            )
        } catch {
            throw KeyManagementError.keyStorageFailed(underlying: error)
        }
        
        // Store public key in Keychain (for easy retrieval)
        do {
            try KeychainHelper.save(
                publicKey.rawRepresentation,
                account: KeychainKeys.identityPublicKey,
                accessibility: .afterFirstUnlockThisDeviceOnly
            )
        } catch {
            throw KeyManagementError.keyStorageFailed(underlying: error)
        }
        
        return IdentityKeyPair(privateKey: privateKey, publicKey: publicKey)
    }
    
    /// Retrieves the stored identity key pair
    func getIdentityKeyPair() throws -> IdentityKeyPair {
        let privateKeyData: Data
        do {
            privateKeyData = try KeychainHelper.load(account: KeychainKeys.identityPrivateKey)
        } catch KeychainHelper.KeychainError.itemNotFound {
            throw KeyManagementError.keyNotFound
        } catch {
            throw KeyManagementError.keyRetrievalFailed(underlying: error)
        }
        
        guard let privateKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKeyData) else {
            throw KeyManagementError.invalidKeyData
        }
        
        return IdentityKeyPair(privateKey: privateKey, publicKey: privateKey.publicKey)
    }
    
    /// Gets just the public key (useful for sharing with contacts)
    func getIdentityPublicKey() throws -> Curve25519.KeyAgreement.PublicKey {
        let keyPair = try getIdentityKeyPair()
        return keyPair.publicKey
    }
    
    /// Gets the public key as raw Data (32 bytes)
    func getIdentityPublicKeyData() throws -> Data {
        let publicKey = try getIdentityPublicKey()
        return publicKey.rawRepresentation
    }
    
    /// Checks if identity keys exist
    func hasIdentityKeys() -> Bool {
        KeychainHelper.exists(account: KeychainKeys.identityPrivateKey)
    }
    
    // MARK: - Signing Key Management
    
    /// Generates and stores signing keys for message authentication
    func generateAndStoreSigningKeys() throws -> SigningKeyPair {
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        do {
            try KeychainHelper.save(
                privateKey.rawRepresentation,
                account: KeychainKeys.signingPrivateKey,
                accessibility: .afterFirstUnlockThisDeviceOnly
            )
        } catch {
            throw KeyManagementError.keyStorageFailed(underlying: error)
        }
        
        do {
            try KeychainHelper.save(
                publicKey.rawRepresentation,
                account: KeychainKeys.signingPublicKey,
                accessibility: .afterFirstUnlockThisDeviceOnly
            )
        } catch {
            throw KeyManagementError.keyStorageFailed(underlying: error)
        }
        
        return SigningKeyPair(privateKey: privateKey, publicKey: publicKey)
    }
    
    /// Retrieves the stored signing key pair
    func getSigningKeyPair() throws -> SigningKeyPair {
        let privateKeyData: Data
        do {
            privateKeyData = try KeychainHelper.load(account: KeychainKeys.signingPrivateKey)
        } catch KeychainHelper.KeychainError.itemNotFound {
            throw KeyManagementError.keyNotFound
        } catch {
            throw KeyManagementError.keyRetrievalFailed(underlying: error)
        }
        
        guard let privateKey = try? Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData) else {
            throw KeyManagementError.invalidKeyData
        }
        
        return SigningKeyPair(privateKey: privateKey, publicKey: privateKey.publicKey)
    }
    
    func hasSigningKeys() -> Bool {
        KeychainHelper.exists(account: KeychainKeys.signingPrivateKey)
    }
    
    // MARK: - Registration ID
    
    /// Generates and stores a registration ID (used by Signal Protocol for device identification)
    func generateAndStoreRegistrationId() throws -> UInt32 {
        let registrationId = UInt32.random(in: 1...16380)
        var idData = Data()
        withUnsafeBytes(of: registrationId) { idData.append(contentsOf: $0) }
        
        do {
            try KeychainHelper.save(
                idData,
                account: KeychainKeys.registrationId,
                accessibility: .afterFirstUnlockThisDeviceOnly
            )
        } catch {
            throw KeyManagementError.keyStorageFailed(underlying: error)
        }
        
        return registrationId
    }
    
    /// Retrieves the stored registration ID
    func getRegistrationId() throws -> UInt32 {
        let idData: Data
        do {
            idData = try KeychainHelper.load(account: KeychainKeys.registrationId)
        } catch KeychainHelper.KeychainError.itemNotFound {
            throw KeyManagementError.keyNotFound
        } catch {
            throw KeyManagementError.keyRetrievalFailed(underlying: error)
        }
        
        guard idData.count == MemoryLayout<UInt32>.size else {
            throw KeyManagementError.invalidKeyData
        }
        
        return idData.withUnsafeBytes { $0.load(as: UInt32.self) }
    }
    
    func hasRegistrationId() -> Bool {
        KeychainHelper.exists(account: KeychainKeys.registrationId)
    }
    
    // MARK: - Initial Setup
    
    /// Performs complete key setup for a new user
    /// Returns the public key data that should be stored in the user profile
    @discardableResult
    func setupNewUser() throws -> Data {
        // Generate all required keys
        let identityKeyPair = try generateAndStoreIdentityKeys()
        _ = try generateAndStoreSigningKeys()
        _ = try generateAndStoreRegistrationId()
        
        return identityKeyPair.publicKeyData
    }
    
    /// Checks if the user has completed key setup
    func isSetupComplete() -> Bool {
        hasIdentityKeys() && hasSigningKeys() && hasRegistrationId()
    }
    
    // MARK: - Key Deletion
    
    /// Deletes all stored keys (use with caution - this is irreversible)
    func deleteAllKeys() throws {
        try? KeychainHelper.delete(account: KeychainKeys.identityPrivateKey)
        try? KeychainHelper.delete(account: KeychainKeys.identityPublicKey)
        try? KeychainHelper.delete(account: KeychainKeys.signingPrivateKey)
        try? KeychainHelper.delete(account: KeychainKeys.signingPublicKey)
        try? KeychainHelper.delete(account: KeychainKeys.registrationId)
    }
    
    // MARK: - Key Derivation
    
    /// Derives a shared secret from our private key and a contact's public key
    /// This is the core of X25519 Diffie-Hellman key agreement
    func deriveSharedSecret(with contactPublicKeyData: Data) throws -> SharedSecret {
        let identityKeyPair = try getIdentityKeyPair()
        
        guard let contactPublicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: contactPublicKeyData) else {
            throw KeyManagementError.invalidKeyData
        }
        
        do {
            return try identityKeyPair.privateKey.sharedSecretFromKeyAgreement(with: contactPublicKey)
        } catch {
            throw KeyManagementError.keyGenerationFailed
        }
    }
    
    /// Derives a symmetric encryption key from a shared secret
    /// Uses HKDF (HMAC-based Key Derivation Function) as recommended
    func deriveSymmetricKey(from sharedSecret: SharedSecret, salt: Data? = nil, info: Data? = nil) -> SymmetricKey {
        sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt ?? Data(),
            sharedInfo: info ?? Data("CarefulWhisper-v1".utf8),
            outputByteCount: 32
        )
    }
}
