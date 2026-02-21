import Testing
import Foundation
@testable import CarefulWhisper

@Suite("EncryptionKeys Tests")
struct EncryptionKeysTests {
    
    @Test("EncryptionKeys initialization sets properties correctly")
    func testEncryptionKeysInit() {
        let userId = UUID()
        let keys = EncryptionKeys(
            userId: userId,
            identityKeyPairId: "key123",
            registrationId: 12345
        )
        
        #expect(keys.userId == userId)
        #expect(keys.identityKeyPairId == "key123")
        #expect(keys.registrationId == 12345)
        #expect(keys.preKeysLastRotated == nil)
    }
    
    @Test("shouldRotatePreKeys returns true when never rotated")
    func testShouldRotatePreKeysNeverRotated() {
        let keys = EncryptionKeys(
            userId: UUID(),
            identityKeyPairId: "key123",
            registrationId: 12345
        )
        
        #expect(keys.shouldRotatePreKeys == true)
    }
    
    @Test("shouldRotatePreKeys returns false when rotated recently")
    func testShouldRotatePreKeysRecentlyRotated() {
        let keys = EncryptionKeys(
            userId: UUID(),
            identityKeyPairId: "key123",
            registrationId: 12345
        )
        keys.preKeysLastRotated = Date()
        
        #expect(keys.shouldRotatePreKeys == false)
    }
    
    @Test("shouldRotatePreKeys returns true when rotated over 30 days ago")
    func testShouldRotatePreKeysOld() {
        let keys = EncryptionKeys(
            userId: UUID(),
            identityKeyPairId: "key123",
            registrationId: 12345
        )
        // Set last rotation to 31 days ago
        keys.preKeysLastRotated = Date().addingTimeInterval(-31 * 24 * 60 * 60)
        
        #expect(keys.shouldRotatePreKeys == true)
    }
}
