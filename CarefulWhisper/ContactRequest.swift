import Foundation
import SwiftData

/// Represents a pending contact request (incoming or outgoing)
@Model
class ContactRequest {
    @Attribute(.unique) var id: UUID
    var senderName: String
    var senderPeerId: String
    var senderPublicKey: Data
    var receivedAt: Date
    var isIncoming: Bool
    var status: ContactRequestStatus
    
    init(
        senderName: String,
        senderPeerId: String,
        senderPublicKey: Data,
        isIncoming: Bool
    ) {
        self.id = UUID()
        self.senderName = senderName
        self.senderPeerId = senderPeerId
        self.senderPublicKey = senderPublicKey
        self.receivedAt = Date()
        self.isIncoming = isIncoming
        self.status = .pending
    }
}

/// Status of a contact request
enum ContactRequestStatus: String, Codable {
    case pending
    case accepted
    case declined
}
