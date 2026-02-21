import Testing
import Foundation
import CryptoKit
@testable import CarefulWhisper

@Suite("Data Extensions Tests")
struct DataExtensionsTests {
    
    @Test("sha256 produces 32-byte hash")
    func testSHA256HashLength() {
        let data = Data("Hello, World!".utf8)
        let hash = data.sha256
        
        #expect(hash.count == 32)
    }
    
    @Test("sha256 produces consistent hash")
    func testSHA256Consistency() {
        let data = Data("Test".utf8)
        let hash1 = data.sha256
        let hash2 = data.sha256
        
        #expect(hash1 == hash2)
    }
    
    @Test("sha256 produces different hashes for different inputs")
    func testSHA256Different() {
        let data1 = Data("Input1".utf8)
        let data2 = Data("Input2".utf8)
        
        let hash1 = data1.sha256
        let hash2 = data2.sha256
        
        #expect(hash1 != hash2)
    }
    
    @Test("hexString formats correctly")
    func testHexString() {
        let data = Data([0xAB, 0xCD, 0xEF, 0x01, 0x23])
        let hex = data.hexString
        
        #expect(hex == "ABCDEF0123")
    }
    
    @Test("hexString is uppercase")
    func testHexStringUppercase() {
        let data = Data([0xab, 0xcd, 0xef])
        let hex = data.hexString
        
        #expect(hex == hex.uppercased())
    }
}
