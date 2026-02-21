import Testing
import Foundation
import CryptoKit
@testable import CarefulWhisper

@Suite("Encryption Tests")
struct EncryptionTests {
    
    // MARK: - Key Generation Tests
    
    @Test("Curve25519 key generation produces valid keys")
    func testKeyGeneration() {
        let privateKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Keys should be 32 bytes
        #expect(privateKey.rawRepresentation.count == 32)
        #expect(publicKey.rawRepresentation.count == 32)
    }
    
    @Test("Key pairs are unique each time")
    func testKeyUniqueness() {
        let key1 = Curve25519.KeyAgreement.PrivateKey()
        let key2 = Curve25519.KeyAgreement.PrivateKey()
        
        #expect(key1.rawRepresentation != key2.rawRepresentation)
        #expect(key1.publicKey.rawRepresentation != key2.publicKey.rawRepresentation)
    }
    
    @Test("Public key can be recreated from raw data")
    func testPublicKeyRecreation() throws {
        let originalKey = Curve25519.KeyAgreement.PrivateKey()
        let publicKeyData = originalKey.publicKey.rawRepresentation
        
        let recreatedKey = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKeyData)
        
        #expect(recreatedKey.rawRepresentation == publicKeyData)
    }
    
    // MARK: - Key Agreement Tests
    
    @Test("X25519 key agreement produces matching shared secrets")
    func testKeyAgreement() throws {
        // Alice and Bob generate their key pairs
        let alicePrivate = Curve25519.KeyAgreement.PrivateKey()
        let bobPrivate = Curve25519.KeyAgreement.PrivateKey()
        
        // Alice computes shared secret with Bob's public key
        let aliceShared = try alicePrivate.sharedSecretFromKeyAgreement(with: bobPrivate.publicKey)
        
        // Bob computes shared secret with Alice's public key
        let bobShared = try bobPrivate.sharedSecretFromKeyAgreement(with: alicePrivate.publicKey)
        
        // Derive symmetric keys and verify they match
        let aliceKey = aliceShared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("test".utf8),
            outputByteCount: 32
        )
        
        let bobKey = bobShared.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("test".utf8),
            outputByteCount: 32
        )
        
        // Keys should match
        let aliceKeyData = aliceKey.withUnsafeBytes { Data($0) }
        let bobKeyData = bobKey.withUnsafeBytes { Data($0) }
        #expect(aliceKeyData == bobKeyData)
    }
    
    // MARK: - ChaCha20-Poly1305 Encryption Tests
    
    @Test("ChaCha20-Poly1305 encryption and decryption roundtrip")
    func testEncryptionRoundtrip() throws {
        let message = "Hello, secure world!"
        let messageData = Data(message.utf8)
        let key = SymmetricKey(size: .bits256)
        
        // Encrypt
        let sealedBox = try ChaChaPoly.seal(messageData, using: key)
        
        // Decrypt
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)
        
        #expect(decryptedMessage == message)
    }
    
    @Test("Decryption fails with wrong key")
    func testDecryptionWithWrongKey() throws {
        let message = "Secret message"
        let messageData = Data(message.utf8)
        let correctKey = SymmetricKey(size: .bits256)
        let wrongKey = SymmetricKey(size: .bits256)
        
        // Encrypt with correct key
        let sealedBox = try ChaChaPoly.seal(messageData, using: correctKey)
        
        // Try to decrypt with wrong key - should fail
        #expect(throws: CryptoKitError.self) {
            _ = try ChaChaPoly.open(sealedBox, using: wrongKey)
        }
    }
    
    @Test("Tampering with ciphertext causes decryption failure")
    func testTamperDetection() throws {
        let message = "Authenticated message"
        let messageData = Data(message.utf8)
        let key = SymmetricKey(size: .bits256)

        // Encrypt
        let sealedBox = try ChaChaPoly.seal(messageData, using: key)

        // Tamper with ciphertext - convert to Data first for mutation
        var tamperedCiphertext = Data(sealedBox.ciphertext)
        if tamperedCiphertext.count > 0 {
            tamperedCiphertext[tamperedCiphertext.startIndex] ^= 0xFF // Flip bits
        }

        // Create tampered sealed box
        let tamperedBox = try ChaChaPoly.SealedBox(
            nonce: sealedBox.nonce,
            ciphertext: tamperedCiphertext,
            tag: sealedBox.tag
        )

        // Decryption should fail due to authentication
        #expect(throws: CryptoKitError.self) {
            _ = try ChaChaPoly.open(tamperedBox, using: key)
        }
    }
    
    // MARK: - Signing Tests
    
    @Test("Ed25519 signature verification")
    func testSignatureVerification() throws {
        let message = "Sign this message"
        let messageData = Data(message.utf8)
        
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Sign
        let signature = try privateKey.signature(for: messageData)
        
        // Verify
        let isValid = publicKey.isValidSignature(signature, for: messageData)
        #expect(isValid == true)
    }
    
    @Test("Signature verification fails for tampered message")
    func testSignatureTamperDetection() throws {
        let originalMessage = "Original message"
        let tamperedMessage = "Tampered message"
        
        let privateKey = Curve25519.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        
        // Sign original
        let signature = try privateKey.signature(for: Data(originalMessage.utf8))
        
        // Verify against tampered - should fail
        let isValid = publicKey.isValidSignature(signature, for: Data(tamperedMessage.utf8))
        #expect(isValid == false)
    }
    
    // MARK: - EncryptedEnvelope Tests
    
    @Test("EncryptedEnvelope serialization roundtrip")
    func testEnvelopeSerialization() throws {
        let envelope = EncryptionService.EncryptedEnvelope(
            messageId: UUID(),
            senderPublicKey: Data(repeating: 0xAB, count: 32),
            ephemeralPublicKey: Data(repeating: 0xCD, count: 32),
            ciphertext: Data(repeating: 0xEF, count: 64),
            nonce: Data(repeating: 0x12, count: 12),
            timestamp: Date()
        )
        
        // Serialize
        let data = try envelope.toData()
        
        // Deserialize
        let restored = try EncryptionService.EncryptedEnvelope.fromData(data)
        
        #expect(restored.messageId == envelope.messageId)
        #expect(restored.senderPublicKey == envelope.senderPublicKey)
        #expect(restored.ephemeralPublicKey == envelope.ephemeralPublicKey)
        #expect(restored.ciphertext == envelope.ciphertext)
        #expect(restored.nonce == envelope.nonce)
        #expect(restored.version == 1)
    }
    
    // MARK: - Forward Secrecy Tests
    
    @Test("Ephemeral keys provide forward secrecy")
    func testForwardSecrecy() throws {
        let recipientPrivate = Curve25519.KeyAgreement.PrivateKey()
        let recipientPublic = recipientPrivate.publicKey
        
        // Simulate two messages with different ephemeral keys
        let ephemeral1 = Curve25519.KeyAgreement.PrivateKey()
        let ephemeral2 = Curve25519.KeyAgreement.PrivateKey()
        
        // Derive secrets from different ephemeral keys
        let secret1 = try ephemeral1.sharedSecretFromKeyAgreement(with: recipientPublic)
        let secret2 = try ephemeral2.sharedSecretFromKeyAgreement(with: recipientPublic)
        
        // Derive symmetric keys
        let key1 = secret1.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        let key2 = secret2.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data(),
            outputByteCount: 32
        )
        
        // Keys should be different (forward secrecy)
        let key1Data = key1.withUnsafeBytes { Data($0) }
        let key2Data = key2.withUnsafeBytes { Data($0) }
        #expect(key1Data != key2Data)
    }
    
    // MARK: - HKDF Tests
    
    @Test("HKDF produces consistent keys")
    func testHKDFConsistency() throws {
        let secret1 = Curve25519.KeyAgreement.PrivateKey()
        let secret2 = Curve25519.KeyAgreement.PrivateKey()
        let sharedSecret = try secret1.sharedSecretFromKeyAgreement(with: secret2.publicKey)
        
        let key1 = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("salt".utf8),
            sharedInfo: Data("info".utf8),
            outputByteCount: 32
        )
        
        let key2 = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data("salt".utf8),
            sharedInfo: Data("info".utf8),
            outputByteCount: 32
        )
        
        let key1Data = key1.withUnsafeBytes { Data($0) }
        let key2Data = key2.withUnsafeBytes { Data($0) }
        #expect(key1Data == key2Data)
    }
    
    @Test("HKDF produces different keys with different info")
    func testHKDFDifferentInfo() throws {
        let secret1 = Curve25519.KeyAgreement.PrivateKey()
        let secret2 = Curve25519.KeyAgreement.PrivateKey()
        let sharedSecret = try secret1.sharedSecretFromKeyAgreement(with: secret2.publicKey)
        
        let key1 = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("info1".utf8),
            outputByteCount: 32
        )
        
        let key2 = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: Data("info2".utf8),
            outputByteCount: 32
        )
        
        let key1Data = key1.withUnsafeBytes { Data($0) }
        let key2Data = key2.withUnsafeBytes { Data($0) }
        #expect(key1Data != key2Data)
    }
}
