import Foundation
import SwiftData

@Model
class Message {
    @Attribute(.unique) var id: UUID
    var content: String
    var timestamp: Date
    var status: MessageStatus
    var isFromMe: Bool
    
    @Relationship(deleteRule: .nullify) var conversation: Conversation?
    @Relationship(deleteRule: .nullify) var sender: Contact?
    
    // Encryption metadata
    var encryptedPayload: Data?
    var signalMessageType: SignalMessageType
    
    init(content: String, sender: Contact? = nil, conversation: Conversation? = nil, isFromMe: Bool, status: MessageStatus = .sending) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.status = status
        self.sender = sender
        self.conversation = conversation
        self.isFromMe = isFromMe
        self.signalMessageType = .normal
    }
}
