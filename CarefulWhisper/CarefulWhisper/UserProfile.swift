import Foundation
import SwiftData

@Model
class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var createdAt: Date
    var publicKey: Data
    var peerId: String
    
    // Settings
    var autoDeleteEnabled: Bool
    var autoDeleteDays: Int?
    
    init(displayName: String, publicKey: Data, peerId: String) {
        self.id = UUID()
        self.displayName = displayName
        self.publicKey = publicKey
        self.peerId = peerId
        self.createdAt = Date()
        self.autoDeleteEnabled = false
    }
    
    var qrCodeData: String {
        let encodedName = displayName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? displayName
        let encodedKey = publicKey.base64EncodedString()
        return "carefulwhisper://contact?name=\(encodedName)&key=\(encodedKey)&peer=\(peerId)"
    }
}
