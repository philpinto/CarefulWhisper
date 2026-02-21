import Foundation
import SwiftData
import Observation

/// ViewModel for the chat/conversation detail screen
@Observable
@MainActor
final class ChatViewModel {
    // MARK: - Properties
    
    let conversation: Conversation
    var messages: [Message] = []
    var messageText: String = ""
    var isLoading: Bool = false
    var isSending: Bool = false
    var errorMessage: String?
    
    private var modelContext: ModelContext?
    private var messageTransportService: MessageTransportService?
    
    // MARK: - Computed Properties
    
    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }
    
    var recipient: Contact? {
        conversation.participants.first
    }
    
    var recipientName: String {
        recipient?.displayName ?? "Unknown"
    }
    
    var isRecipientOnline: Bool {
        recipient?.isOnline ?? false
    }
    
    // MARK: - Initialization
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self.messages = conversation.messages
    }
    
    // MARK: - Configuration
    
    func configure(modelContext: ModelContext, transportService: MessageTransportService?) {
        self.modelContext = modelContext
        self.messageTransportService = transportService
        loadMessages()
        setupCallbacks()
    }
    
    // MARK: - Data Loading
    
    func loadMessages() {
        messages = conversation.messages
    }
    
    // MARK: - Sending Messages
    
    func sendMessage() async {
        let content = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard let recipient = recipient else {
            errorMessage = "No recipient found"
            return
        }
        
        isSending = true
        messageText = ""
        errorMessage = nil
        
        do {
            if let transportService = messageTransportService {
                // Use transport service for encrypted P2P sending
                let message = try await transportService.sendMessage(
                    content: content,
                    to: recipient,
                    in: conversation
                )
                messages.append(message)
            } else {
                // Fallback: create local message only (for testing/offline)
                let message = Message(
                    content: content,
                    conversation: conversation,
                    isFromMe: true,
                    status: .sent
                )
                modelContext?.insert(message)
                conversation.messages.append(message)
                conversation.lastMessageAt = Date()
                try? modelContext?.save()
                messages.append(message)
            }
        } catch {
            errorMessage = "Failed to send message"
            // Restore the message text so user can retry
            messageText = content
        }
        
        isSending = false
    }
    
    // MARK: - Message Actions
    
    func retryMessage(_ message: Message) async {
        guard message.status == .failed, let recipient = recipient else { return }
        
        do {
            try await messageTransportService?.retryMessage(message, to: recipient)
        } catch {
            errorMessage = "Failed to retry message"
        }
    }
    
    func deleteMessage(_ message: Message) {
        guard let context = modelContext else { return }
        
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages.remove(at: index)
        }
        
        if let index = conversation.messages.firstIndex(where: { $0.id == message.id }) {
            conversation.messages.remove(at: index)
        }
        
        context.delete(message)
        try? context.save()
    }
    
    // MARK: - Read Receipts
    
    func markMessagesAsRead() {
        var messagesToMarkRead: [Message] = []
        
        for message in messages where !message.isFromMe && message.status != .read {
            message.status = .read
            messagesToMarkRead.append(message)
        }
        
        if !messagesToMarkRead.isEmpty {
            try? modelContext?.save()
            
            // Send read receipts via P2P
            if let recipient = recipient {
                let messageIds = messagesToMarkRead.map { $0.id }
                Task {
                    await messageTransportService?.sendReadReceipts(for: messageIds, to: recipient)
                }
            }
        }
    }
    
    // MARK: - Callbacks
    
    private func setupCallbacks() {
        messageTransportService?.onMessageReceived = { [weak self] message in
            Task { @MainActor in
                guard let self = self else { return }
                if message.conversation?.id == self.conversation.id {
                    if !self.messages.contains(where: { $0.id == message.id }) {
                        self.messages.append(message)
                    }
                }
            }
        }
        
        messageTransportService?.onMessageStatusChanged = { [weak self] messageId, status in
            Task { @MainActor in
                guard let self = self else { return }
                if let message = self.messages.first(where: { $0.id == messageId }) {
                    message.status = status
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    /// Group messages by date for section headers
    func groupedMessages() -> [(date: Date, messages: [Message])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sortedMessages) { message in
            calendar.startOfDay(for: message.timestamp)
        }
        
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, messages: $0.value) }
    }
    
    /// Format date for section header
    func formatSectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    /// Format timestamp for individual message
    func formatMessageTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
