import Foundation
import SwiftData
import CryptoKit

@Model
class Contact {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var publicKey: Data
    var peerId: String
    var dateAdded: Date
    var lastSeen: Date?
    var isOnline: Bool
    var isPersistentConnection: Bool
    
    @Relationship(deleteRule: .cascade) var conversations: [Conversation]
    
    init(displayName: String, publicKey: Data, peerId: String) {
        self.id = UUID()
        self.displayName = displayName
        self.publicKey = publicKey
        self.peerId = peerId
        self.dateAdded = Date()
        self.isOnline = false
        self.isPersistentConnection = false
        self.conversations = []
    }
    
    var publicKeyFingerprint: String {
        let hash = SHA256.hash(data: publicKey)
        let hexString = hash.map { String(format: "%02x", $0) }.joined()
        
        var formatted = ""
        for (index, char) in hexString.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted.append(char)
        }
        
        return formatted.uppercased()
    }
}
