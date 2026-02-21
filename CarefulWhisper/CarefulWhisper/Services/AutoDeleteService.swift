import Foundation
import SwiftData

/// Service responsible for deleting old messages based on auto-delete settings
@MainActor
final class AutoDeleteService {
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() { }
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Public Methods
    
    /// Run the auto-delete cleanup process
    /// - Returns: Number of messages deleted
    @discardableResult
    func performCleanup() async -> Int {
        guard let context = modelContext else { return 0 }
        
        // Get user profile to check auto-delete settings
        let profileDescriptor = FetchDescriptor<UserProfile>()
        guard let profile = try? context.fetch(profileDescriptor).first,
              profile.autoDeleteEnabled,
              let days = profile.autoDeleteDays,
              days > 0 else {
            return 0
        }
        
        // Calculate cutoff date
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        // Fetch old messages
        let messageDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.timestamp < cutoffDate
            }
        )
        
        guard let oldMessages = try? context.fetch(messageDescriptor) else {
            return 0
        }
        
        let deleteCount = oldMessages.count
        
        // Delete old messages
        for message in oldMessages {
            // Remove from conversation's messages array
            if let conversation = message.conversation {
                conversation.messages.removeAll { $0.id == message.id }
            }
            
            context.delete(message)
        }
        
        // Clean up empty conversations (optional)
        cleanupEmptyConversations(context: context)
        
        try? context.save()
        
        return deleteCount
    }
    
    /// Delete messages older than a specific date
    /// - Parameters:
    ///   - date: Delete messages before this date
    /// - Returns: Number of messages deleted
    @discardableResult
    func deleteMessages(before date: Date) async -> Int {
        guard let context = modelContext else { return 0 }
        
        let messageDescriptor = FetchDescriptor<Message>(
            predicate: #Predicate<Message> { message in
                message.timestamp < date
            }
        )
        
        guard let oldMessages = try? context.fetch(messageDescriptor) else {
            return 0
        }
        
        let deleteCount = oldMessages.count
        
        for message in oldMessages {
            if let conversation = message.conversation {
                conversation.messages.removeAll { $0.id == message.id }
            }
            context.delete(message)
        }
        
        try? context.save()
        
        return deleteCount
    }
    
    /// Delete messages for a specific conversation
    /// - Parameters:
    ///   - conversation: The conversation to clean up
    ///   - days: Delete messages older than this many days
    /// - Returns: Number of messages deleted
    @discardableResult
    func deleteMessages(in conversation: Conversation, olderThan days: Int) -> Int {
        guard let context = modelContext else { return 0 }
        
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let messagesToDelete = conversation.messages.filter { $0.timestamp < cutoffDate }
        let deleteCount = messagesToDelete.count
        
        for message in messagesToDelete {
            conversation.messages.removeAll { $0.id == message.id }
            context.delete(message)
        }
        
        try? context.save()
        
        return deleteCount
    }
    
    // MARK: - Private Methods
    
    /// Remove conversations that have no messages
    private func cleanupEmptyConversations(context: ModelContext) {
        let conversationDescriptor = FetchDescriptor<Conversation>()
        
        guard let conversations = try? context.fetch(conversationDescriptor) else {
            return
        }
        
        for conversation in conversations {
            if conversation.messages.isEmpty {
                context.delete(conversation)
            }
        }
    }
}
