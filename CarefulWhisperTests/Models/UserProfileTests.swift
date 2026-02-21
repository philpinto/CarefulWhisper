import Testing
import Foundation
@testable import CarefulWhisper

@Suite("UserProfile Tests")
struct UserProfileTests {
    
    @Test("UserProfile initialization sets properties correctly")
    func testUserProfileInit() {
        let publicKey = Data(repeating: 0xCD, count: 32)
        let profile = UserProfile(
            displayName: "Alice",
            publicKey: publicKey,
            peerId: "peer123"
        )
        
        #expect(profile.displayName == "Alice")
        #expect(profile.publicKey == publicKey)
        #expect(profile.peerId == "peer123")
        #expect(profile.autoDeleteEnabled == false)
        #expect(profile.autoDeleteDays == nil)
    }
    
    @Test("qrCodeData formats correctly")
    func testQRCodeData() {
        let publicKey = Data(repeating: 0xCD, count: 32)
        let profile = UserProfile(
            displayName: "Alice",
            publicKey: publicKey,
            peerId: "peer123"
        )
        
        let qrData = profile.qrCodeData
        
        #expect(qrData.hasPrefix("carefulwhisper://contact?"))
        #expect(qrData.contains("name=Alice"))
        #expect(qrData.contains("peer=peer123"))
        #expect(qrData.contains("key="))
    }
    
    @Test("qrCodeData handles special characters in name")
    func testQRCodeDataSpecialCharacters() {
        let publicKey = Data(repeating: 0xCD, count: 32)
        let profile = UserProfile(
            displayName: "Alice Bob",
            publicKey: publicKey,
            peerId: "peer123"
        )

        let qrData = profile.qrCodeData

        // Spaces should be URL encoded
        #expect(qrData.contains("Alice%20Bob"))
    }
}
