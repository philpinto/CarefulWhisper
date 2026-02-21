import Foundation
import SwiftData

@Model
class Conversation {
    @Attribute(.unique) var id: UUID
    var type: ConversationType
    var createdAt: Date
    var lastMessageAt: Date?
    
    @Relationship(deleteRule: .nullify) var participants: [Contact]
    @Relationship(deleteRule: .cascade) var messages: [Message]
    
    // Group-specific properties
    var groupName: String?
    
    // Stored as JSON data since SwiftData can't directly persist Array<UUID>
    private var groupAdminIdsData: Data?
    
    var groupAdminIds: [UUID]? {
        get {
            guard let data = groupAdminIdsData else { return nil }
            return try? JSONDecoder().decode([UUID].self, from: data)
        }
        set {
            groupAdminIdsData = try? JSONEncoder().encode(newValue)
        }
    }
    
    init(type: ConversationType, participants: [Contact] = []) {
        self.id = UUID()
        self.type = type
        self.participants = participants
        self.createdAt = Date()
        self.messages = []
    }
    
    var lastMessage: Message? {
        messages.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
}
