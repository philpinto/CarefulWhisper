import Foundation
import SwiftData

@MainActor
class DataService {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    // MARK: - Contact Operations
    
    func fetchContacts() throws -> [Contact] {
        let descriptor = FetchDescriptor<Contact>(
            sortBy: [SortDescriptor(\.displayName, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchContact(id: UUID) throws -> Contact? {
        let descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { contact in
                contact.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func saveContact(_ contact: Contact) throws {
        modelContext.insert(contact)
        try modelContext.save()
    }
    
    func deleteContact(_ contact: Contact) throws {
        modelContext.delete(contact)
        try modelContext.save()
    }
    
    // MARK: - Conversation Operations
    
    func fetchConversations() throws -> [Conversation] {
        let descriptor = FetchDescriptor<Conversation>(
            sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func fetchConversation(id: UUID) throws -> Conversation? {
        let descriptor = FetchDescriptor<Conversation>(
            predicate: #Predicate { conversation in
                conversation.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }
    
    func saveConversation(_ conversation: Conversation) throws {
        modelContext.insert(conversation)
        try modelContext.save()
    }
    
    func deleteConversation(_ conversation: Conversation) throws {
        modelContext.delete(conversation)
        try modelContext.save()
    }
    
    // MARK: - Message Operations
    
    func fetchMessages(for conversationId: UUID) throws -> [Message] {
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { message in
                message.conversation?.id == conversationId
            },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    func saveMessage(_ message: Message) throws {
        modelContext.insert(message)
        try modelContext.save()
    }
    
    func deleteMessage(_ message: Message) throws {
        modelContext.delete(message)
        try modelContext.save()
    }
    
    // MARK: - UserProfile Operations
    
    func fetchUserProfile() throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfile>()
        return try modelContext.fetch(descriptor).first
    }
    
    func saveUserProfile(_ profile: UserProfile) throws {
        modelContext.insert(profile)
        try modelContext.save()
    }
    
    // MARK: - EncryptionKeys Operations
    
    func fetchEncryptionKeys() throws -> EncryptionKeys? {
        let descriptor = FetchDescriptor<EncryptionKeys>()
        return try modelContext.fetch(descriptor).first
    }
    
    func saveEncryptionKeys(_ keys: EncryptionKeys) throws {
        modelContext.insert(keys)
        try modelContext.save()
    }
}
