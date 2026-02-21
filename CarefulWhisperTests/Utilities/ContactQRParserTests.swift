import Testing
import Foundation
@testable import CarefulWhisper

@Suite("ContactQRParser Tests")
struct ContactQRParserTests {
    
    @Test("Parses valid carefulwhisper URL")
    func testParseValidURL() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let base64Key = publicKey.base64EncodedString()
        let url = "carefulwhisper://contact?name=Alice&key=\(base64Key)&peer=peer123"
        
        let result = ContactQRParser.parse(url)
        
        #expect(result != nil)
        #expect(result?.name == "Alice")
        #expect(result?.publicKey == publicKey)
        #expect(result?.peerId == "peer123")
    }
    
    @Test("Parses URL with encoded spaces in name")
    func testParseURLWithEncodedSpaces() {
        let publicKey = Data(repeating: 0xCD, count: 32)
        let base64Key = publicKey.base64EncodedString()
        let url = "carefulwhisper://contact?name=Alice%20Bob&key=\(base64Key)&peer=peer456"
        
        let result = ContactQRParser.parse(url)
        
        #expect(result != nil)
        #expect(result?.name == "Alice Bob")
    }
    
    @Test("Returns nil for invalid scheme")
    func testInvalidScheme() {
        let result = ContactQRParser.parse("https://example.com/contact?name=Alice")
        #expect(result == nil)
    }
    
    @Test("Returns nil for missing name")
    func testMissingName() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let base64Key = publicKey.base64EncodedString()
        let url = "carefulwhisper://contact?key=\(base64Key)&peer=peer123"
        
        let result = ContactQRParser.parse(url)
        #expect(result == nil)
    }
    
    @Test("Returns nil for missing key")
    func testMissingKey() {
        let url = "carefulwhisper://contact?name=Alice&peer=peer123"
        
        let result = ContactQRParser.parse(url)
        #expect(result == nil)
    }
    
    @Test("Returns nil for missing peer")
    func testMissingPeer() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let base64Key = publicKey.base64EncodedString()
        let url = "carefulwhisper://contact?name=Alice&key=\(base64Key)"
        
        let result = ContactQRParser.parse(url)
        #expect(result == nil)
    }
    
    @Test("Returns nil for invalid base64 key")
    func testInvalidBase64Key() {
        let url = "carefulwhisper://contact?name=Alice&key=not-valid-base64!!!&peer=peer123"
        
        let result = ContactQRParser.parse(url)
        #expect(result == nil)
    }
    
    @Test("Returns nil for empty string")
    func testEmptyString() {
        let result = ContactQRParser.parse("")
        #expect(result == nil)
    }
    
    @Test("Returns nil for random string")
    func testRandomString() {
        let result = ContactQRParser.parse("just some random text")
        #expect(result == nil)
    }
}
