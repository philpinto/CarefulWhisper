import Testing
import Foundation
@testable import CarefulWhisper

@Suite("String Extensions Tests")
struct StringExtensionsTests {
    
    @Test("urlEncoded handles basic strings")
    func testURLEncodedBasic() {
        let string = "HelloWorld"
        let encoded = string.urlEncoded
        
        #expect(encoded == "HelloWorld")
    }
    
    @Test("urlEncoded handles spaces")
    func testURLEncodedSpaces() {
        let string = "Hello World"
        let encoded = string.urlEncoded
        
        #expect(encoded.contains("%20"))
    }
    
    @Test("urlEncoded handles special characters")
    func testURLEncodedSpecialCharacters() {
        let string = "Hello World"
        let encoded = string.urlEncoded

        // Space gets encoded
        #expect(encoded.contains("%20"))
        // & is allowed in urlQueryAllowed, so test with #
        let string2 = "Test#Value"
        let encoded2 = string2.urlEncoded
        #expect(encoded2.contains("%23"))
    }
    
    @Test("urlEncoded handles emoji")
    func testURLEncodedEmoji() {
        let string = "Hello 👋"
        let encoded = string.urlEncoded
        
        #expect(encoded != string)
        #expect(encoded.contains("%"))
    }
    
    @Test("urlEncoded preserves alphanumeric characters")
    func testURLEncodedAlphanumeric() {
        let string = "ABC123xyz"
        let encoded = string.urlEncoded
        
        #expect(encoded == "ABC123xyz")
    }
}
