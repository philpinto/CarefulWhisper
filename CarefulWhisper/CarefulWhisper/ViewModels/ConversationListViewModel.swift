import Foundation
import SwiftData
import Observation

/// ViewModel for the conversation list screen
@Observable
@MainActor
final class ConversationListViewModel {
    // MARK: - Properties
    
    var conversations: [Conversation] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    // MARK: - Computed Properties
    
    var filteredConversations: [Conversation] {
        guard !searchText.isEmpty else {
            return sortedConversations
        }
        
        return sortedConversations.filter { conversation in
            // Search by participant names
            conversation.participants.contains { contact in
                contact.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private var sortedConversations: [Conversation] {
        conversations.sorted { first, second in
            let firstDate = first.lastMessageAt ?? first.createdAt
            let secondDate = second.lastMessageAt ?? second.createdAt
            return firstDate > secondDate
        }
    }
    
    // MARK: - Initialization
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadConversations()
    }
    
    // MARK: - Data Loading
    
    func loadConversations() {
        guard let context = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let descriptor = FetchDescriptor<Conversation>(
                sortBy: [SortDescriptor(\.lastMessageAt, order: .reverse)]
            )
            conversations = try context.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load conversations"
        }
        
        isLoading = false
    }
    
    // MARK: - Conversation Management
    
    /// Get or create a one-to-one conversation with a contact
    func getOrCreateConversation(with contact: Contact) -> Conversation? {
        // Check if conversation already exists
        if let existing = contact.conversations.first(where: { $0.type == .oneToOne }) {
            return existing
        }
        
        // Create new conversation
        guard let context = modelContext else { return nil }
        
        let conversation = Conversation(type: .oneToOne, participants: [contact])
        context.insert(conversation)
        
        do {
            try context.save()
            loadConversations()
            return conversation
        } catch {
            errorMessage = "Failed to create conversation"
            return nil
        }
    }
    
    /// Delete a conversation
    func deleteConversation(_ conversation: Conversation) {
        guard let context = modelContext else { return }
        
        context.delete(conversation)
        
        do {
            try context.save()
            loadConversations()
        } catch {
            errorMessage = "Failed to delete conversation"
        }
    }
    
    /// Delete conversations at specific offsets (for swipe-to-delete)
    func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = filteredConversations[index]
            deleteConversation(conversation)
        }
    }
    
    // MARK: - Helpers
    
    /// Get display name for a conversation
    func displayName(for conversation: Conversation) -> String {
        switch conversation.type {
        case .oneToOne:
            return conversation.participants.first?.displayName ?? "Unknown"
        case .group:
            return conversation.groupName ?? "Group"
        }
    }
    
    /// Get preview text for the last message
    func lastMessagePreview(for conversation: Conversation) -> String {
        guard let lastMessage = conversation.lastMessage else {
            return "No messages yet"
        }
        
        if lastMessage.isFromMe {
            return "You: \(lastMessage.content)"
        } else {
            return lastMessage.content
        }
    }
    
    /// Format timestamp for display
    func formattedTime(for conversation: Conversation) -> String {
        guard let date = conversation.lastMessageAt ?? conversation.messages.last?.timestamp else {
            return ""
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M/d/yy"
            return formatter.string(from: date)
        }
    }
    
    /// Check if conversation has unread messages
    func hasUnreadMessages(_ conversation: Conversation) -> Bool {
        conversation.messages.contains { message in
            !message.isFromMe && message.status != .read
        }
    }
    
    /// Get unread count for a conversation
    func unreadCount(for conversation: Conversation) -> Int {
        conversation.messages.filter { message in
            !message.isFromMe && message.status != .read
        }.count
    }
}
