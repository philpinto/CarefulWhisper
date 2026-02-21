import Testing
import Foundation
import CryptoKit
@testable import CarefulWhisper

@Suite("Contact Tests")
struct ContactTests {
    
    @Test("Contact initialization sets properties correctly")
    func testContactInit() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let contact = Contact(
            displayName: "Alice",
            publicKey: publicKey,
            peerId: "peer123"
        )
        
        #expect(contact.displayName == "Alice")
        #expect(contact.publicKey == publicKey)
        #expect(contact.peerId == "peer123")
        #expect(contact.isOnline == false)
        #expect(contact.isPersistentConnection == false)
        #expect(contact.conversations.isEmpty)
    }
    
    @Test("Public key fingerprint formats correctly")
    func testPublicKeyFingerprint() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let contact = Contact(
            displayName: "Alice",
            publicKey: publicKey,
            peerId: "peer123"
        )

        let fingerprint = contact.publicKeyFingerprint

        // Fingerprint should be uppercase hex with spaces every 4 characters
        #expect(fingerprint.contains(" "))
        #expect(fingerprint == fingerprint.uppercased())
        // Should be 64 hex chars + spaces (SHA256 = 32 bytes = 64 hex chars)
        // With spaces every 4 chars: 64 chars + 15 spaces = 79 total
        #expect(fingerprint.count == 79)
    }
}
