import Foundation
import CryptoKit

/// Service responsible for encrypting and decrypting messages
/// Uses ChaCha20-Poly1305 authenticated encryption (same as Signal Protocol)
actor EncryptionService {
    
    // MARK: - Errors
    
    enum EncryptionError: Error {
        case encryptionFailed
        case decryptionFailed
        case invalidCiphertext
        case sessionNotFound
        case keyDerivationFailed
        case invalidMessageFormat
    }
    
    // MARK: - Types
    
    /// Encrypted message envelope containing all data needed to decrypt
    struct EncryptedEnvelope: Codable, Sendable {
        /// Unique message identifier
        let messageId: UUID
        
        /// Sender's public key (for recipient to derive shared secret)
        let senderPublicKey: Data
        
        /// Ephemeral public key used for this message (provides forward secrecy)
        let ephemeralPublicKey: Data
        
        /// The encrypted message content
        let ciphertext: Data
        
        /// Nonce used for encryption
        let nonce: Data
        
        /// Timestamp when message was encrypted
        let timestamp: Date
        
        /// Protocol version for future compatibility
        let version: Int = 1
        
        /// Converts envelope to Data for transmission
        func toData() throws -> Data {
            try JSONEncoder().encode(self)
        }
        
        /// Creates envelope from received Data
        static func fromData(_ data: Data) throws -> EncryptedEnvelope {
            try JSONDecoder().decode(EncryptedEnvelope.self, from: data)
        }
    }
    
    /// Decrypted message content
    struct DecryptedMessage: Sendable {
        let messageId: UUID
        let content: String
        let senderPublicKey: Data
        let timestamp: Date
    }
    
    // MARK: - Dependencies
    
    private let keyManagementService: KeyManagementService
    
    // MARK: - Initialization
    
    init(keyManagementService: KeyManagementService = .shared) {
        self.keyManagementService = keyManagementService
    }
    
    // MARK: - Singleton
    
    static let shared = EncryptionService()
    
    // MARK: - Message Encryption
    
    /// Encrypts a message for a specific recipient
    /// Uses ephemeral key pairs for forward secrecy
    /// - Parameters:
    ///   - content: The plaintext message to encrypt
    ///   - recipientPublicKey: The recipient's Curve25519 public key (32 bytes)
    /// - Returns: An encrypted envelope ready for transmission
    func encrypt(_ content: String, for recipientPublicKey: Data) async throws -> EncryptedEnvelope {
        // Get our identity key pair
        let identityKeyPair = try await keyManagementService.getIdentityKeyPair()
        
        // Generate ephemeral key pair for this message (provides forward secrecy)
        let ephemeralPrivateKey = Curve25519.KeyAgreement.PrivateKey()
        let ephemeralPublicKey = ephemeralPrivateKey.publicKey
        
        // Parse recipient's public key
        guard let recipientKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: recipientPublicKey) else {
            throw EncryptionError.keyDerivationFailed
        }
        
        // Perform X25519 key agreement with ephemeral key
        let sharedSecret: SharedSecret
        do {
            sharedSecret = try ephemeralPrivateKey.sharedSecretFromKeyAgreement(with: recipientKey)
        } catch {
            throw EncryptionError.keyDerivationFailed
        }
        
        // Derive symmetric key using HKDF
        // Include both public keys in info to bind the key to this specific exchange
        var info = Data("CarefulWhisper-message-v1".utf8)
        info.append(identityKeyPair.publicKeyData)
        info.append(recipientPublicKey)
        
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: info,
            outputByteCount: 32
        )
        
        // Convert message to data
        guard let messageData = content.data(using: .utf8) else {
            throw EncryptionError.encryptionFailed
        }
        
        // Encrypt using ChaCha20-Poly1305
        let sealedBox: ChaChaPoly.SealedBox
        do {
            sealedBox = try ChaChaPoly.seal(messageData, using: symmetricKey)
        } catch {
            throw EncryptionError.encryptionFailed
        }
        
        // Create envelope with all necessary data for decryption
        return EncryptedEnvelope(
            messageId: UUID(),
            senderPublicKey: identityKeyPair.publicKeyData,
            ephemeralPublicKey: ephemeralPublicKey.rawRepresentation,
            ciphertext: sealedBox.ciphertext + sealedBox.tag, // Combined ciphertext + auth tag
            nonce: Data(sealedBox.nonce),
            timestamp: Date()
        )
    }
    
    // MARK: - Message Decryption
    
    /// Decrypts a received message envelope
    /// - Parameter envelope: The encrypted envelope received from a sender
    /// - Returns: The decrypted message content
    func decrypt(_ envelope: EncryptedEnvelope) async throws -> DecryptedMessage {
        // Get our identity key pair
        let identityKeyPair = try await keyManagementService.getIdentityKeyPair()
        
        // Parse sender's ephemeral public key
        guard let ephemeralPublicKey = try? Curve25519.KeyAgreement.PublicKey(
            rawRepresentation: envelope.ephemeralPublicKey
        ) else {
            throw EncryptionError.invalidMessageFormat
        }
        
        // Perform X25519 key agreement with sender's ephemeral key
        let sharedSecret: SharedSecret
        do {
            sharedSecret = try identityKeyPair.privateKey.sharedSecretFromKeyAgreement(with: ephemeralPublicKey)
        } catch {
            throw EncryptionError.keyDerivationFailed
        }
        
        // Derive the same symmetric key the sender used
        var info = Data("CarefulWhisper-message-v1".utf8)
        info.append(envelope.senderPublicKey)
        info.append(identityKeyPair.publicKeyData)
        
        let symmetricKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: info,
            outputByteCount: 32
        )
        
        // Parse nonce
        guard let nonce = try? ChaChaPoly.Nonce(data: envelope.nonce) else {
            throw EncryptionError.invalidMessageFormat
        }
        
        // Split ciphertext and tag (last 16 bytes is the tag)
        guard envelope.ciphertext.count > 16 else {
            throw EncryptionError.invalidCiphertext
        }
        
        let ciphertext = envelope.ciphertext.prefix(envelope.ciphertext.count - 16)
        let tag = envelope.ciphertext.suffix(16)
        
        // Create sealed box for decryption
        let sealedBox: ChaChaPoly.SealedBox
        do {
            sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        } catch {
            throw EncryptionError.invalidCiphertext
        }
        
        // Decrypt
        let decryptedData: Data
        do {
            decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
        } catch {
            throw EncryptionError.decryptionFailed
        }
        
        // Convert to string
        guard let content = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.decryptionFailed
        }
        
        return DecryptedMessage(
            messageId: envelope.messageId,
            content: content,
            senderPublicKey: envelope.senderPublicKey,
            timestamp: envelope.timestamp
        )
    }
    
    /// Decrypts a message from raw Data
    func decrypt(_ data: Data) async throws -> DecryptedMessage {
        let envelope = try EncryptedEnvelope.fromData(data)
        return try await decrypt(envelope)
    }
    
    // MARK: - Message Signing
    
    /// Signs a message to prove authenticity
    /// - Parameter content: The content to sign
    /// - Returns: The Ed25519 signature
    func sign(_ content: String) async throws -> Data {
        let signingKeyPair = try await keyManagementService.getSigningKeyPair()
        
        guard let data = content.data(using: .utf8) else {
            throw EncryptionError.encryptionFailed
        }
        
        return try signingKeyPair.privateKey.signature(for: data)
    }
    
    /// Verifies a message signature
    /// - Parameters:
    ///   - signature: The signature to verify
    ///   - content: The original content that was signed
    ///   - signerPublicKey: The signer's Ed25519 public key
    /// - Returns: True if the signature is valid
    func verify(signature: Data, for content: String, from signerPublicKey: Data) throws -> Bool {
        guard let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: signerPublicKey),
              let data = content.data(using: .utf8) else {
            return false
        }
        
        return publicKey.isValidSignature(signature, for: data)
    }
}
