import Foundation
import SwiftData
import Observation

/// Type alias for the encrypted envelope from EncryptionService
typealias EncryptedEnvelope = EncryptionService.EncryptedEnvelope

/// Coordinates message encryption, transport, and persistence
/// This is the main entry point for sending and receiving messages
@Observable
final class MessageTransportService {
    // MARK: - Properties
    
    private let encryptionService: EncryptionService
    private let p2pService: P2PNetworkService
    private var modelContext: ModelContext?
    
    private(set) var isRunning = false
    
    // Callbacks for UI updates
    var onMessageReceived: ((Message) -> Void)?
    var onMessageStatusChanged: ((UUID, MessageStatus) -> Void)?
    var onContactOnlineStatusChanged: ((String, Bool) -> Void)?
    
    // Reference to presence service for connection notifications
    weak var presenceService: PresenceService?
    
    // Reference to contact request service for handling contact requests
    weak var contactRequestService: ContactRequestService?
    
    // MARK: - Initialization
    
    init(encryptionService: EncryptionService, p2pService: P2PNetworkService) {
        self.encryptionService = encryptionService
        self.p2pService = p2pService
        
        setupCallbacks()
    }
    
    // MARK: - Configuration
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Lifecycle
    
    func start(displayName: String, publicKey: Data) async throws {
        guard !isRunning else { return }
        
        try await p2pService.start(displayName: displayName, publicKey: publicKey)
        isRunning = true
    }
    
    func stop() async {
        await p2pService.stop()
        isRunning = false
    }
    
    // MARK: - Sending Messages
    
    /// Send a text message to a contact
    /// - Parameters:
    ///   - content: The plain text message content
    ///   - contact: The recipient contact
    ///   - conversation: The conversation to add the message to
    /// - Returns: The created Message object
    @discardableResult
    func sendMessage(
        content: String,
        to contact: Contact,
        in conversation: Conversation
    ) async throws -> Message {
        // Create message with "sending" status
        let message = Message(
            content: content,
            conversation: conversation,
            isFromMe: true,
            status: .sending
        )
        
        // Persist to SwiftData
        modelContext?.insert(message)
        conversation.messages.append(message)
        conversation.lastMessageAt = Date()
        try? modelContext?.save()
        
        do {
            // Encrypt the message
            let envelope = try await encryptionService.encrypt(content, for: contact.publicKey)
            
            // Serialize encrypted envelope
            let envelopeData = try JSONEncoder().encode(envelope)
            
            // Send via P2P network
            print("[MessageTransport] Sending message to \(contact.displayName) (peerId: \(contact.peerId.prefix(16))...)")
            let result = await p2pService.send(
                encryptedPayload: envelopeData,
                to: contact.peerId,
                messageType: .message
            )
            
            // Update message status based on result
            switch result {
            case .sent:
                print("[MessageTransport] Message sent successfully")
                message.status = MessageStatus.sent
            case .queued:
                print("[MessageTransport] Message queued for later delivery (recipient offline)")
                message.status = MessageStatus.sending
            case .failed(let error):
                print("[MessageTransport] Message send failed: \(error)")
                message.status = MessageStatus.failed
                throw error
            }
            
            try? modelContext?.save()
            onMessageStatusChanged?(message.id, message.status)
            
            return message
            
        } catch {
            message.status = MessageStatus.failed
            try? modelContext?.save()
            onMessageStatusChanged?(message.id, MessageStatus.failed)
            throw error
        }
    }
    
    /// Send read receipts for messages from a contact
    /// - Parameters:
    ///   - messageIds: The IDs of messages that have been read
    ///   - contact: The sender of those messages
    func sendReadReceipts(for messageIds: [UUID], to contact: Contact) async {
        for messageId in messageIds {
            await p2pService.sendReadReceipt(for: messageId, to: contact.peerId)
        }
    }
    
    /// Retry sending a failed message
    func retryMessage(_ message: Message, to contact: Contact) async throws {
        guard message.status == MessageStatus.failed else { return }
        
        message.status = MessageStatus.sending
        try? modelContext?.save()
        onMessageStatusChanged?(message.id, MessageStatus.sending)
        
        do {
            // Re-encrypt and send
            let envelope = try await encryptionService.encrypt(message.content, for: contact.publicKey)
            let envelopeData = try JSONEncoder().encode(envelope)
            
            let result = await p2pService.send(
                encryptedPayload: envelopeData,
                to: contact.peerId,
                messageType: .message
            )
            
            switch result {
            case .sent:
                message.status = MessageStatus.sent
            case .queued:
                message.status = MessageStatus.sending
            case .failed(let error):
                message.status = MessageStatus.failed
                throw error
            }
            
            try? modelContext?.save()
            onMessageStatusChanged?(message.id, message.status)
            
        } catch {
            message.status = MessageStatus.failed
            try? modelContext?.save()
            onMessageStatusChanged?(message.id, MessageStatus.failed)
            throw error
        }
    }
    
    // MARK: - Receiving Messages
    
    private func handleIncomingMessage(_ envelope: P2PMessageEnvelope) async {
        print("[MessageTransport] Received message from: \(envelope.senderId.prefix(16))...")
        do {
            // Deserialize encrypted envelope
            let encryptedEnvelope = try EncryptedEnvelope.fromData(envelope.encryptedPayload)
            
            // Decrypt the message
            let decryptedMessage = try await encryptionService.decrypt(encryptedEnvelope)
            print("[MessageTransport] Message decrypted successfully")
            
            // Find or create conversation
            guard let (contact, conversation) = findOrCreateConversation(for: envelope.senderId) else {
                return
            }
            
            // Create message
            let message = Message(
                content: decryptedMessage.content,
                sender: contact,
                conversation: conversation,
                isFromMe: false,
                status: MessageStatus.delivered
            )
            
            // Persist
            modelContext?.insert(message)
            conversation.messages.append(message)
            conversation.lastMessageAt = Date()
            try? modelContext?.save()
            
            // Send delivery receipt
            await p2pService.sendDeliveryReceipt(for: envelope.id, to: envelope.senderId)
            
            // Show local notification if app is in background
            await NotificationService.shared.showMessageNotification(
                from: contact.displayName,
                messagePreview: decryptedMessage.content,
                conversationId: conversation.id
            )
            
            // Notify UI
            onMessageReceived?(message)
            
        } catch {
            print("Failed to handle incoming message: \(error)")
        }
    }
    
    private func handleDeliveryReceipt(_ envelope: P2PMessageEnvelope) async {
        guard let receiptData = try? JSONDecoder().decode([String: String].self, from: envelope.encryptedPayload),
              let messageIdString = receiptData["messageId"],
              let messageId = UUID(uuidString: messageIdString) else {
            return
        }
        
        // Find and update the message
        guard let message = findMessage(by: messageId) else { return }
        
        message.status = MessageStatus.delivered
        try? modelContext?.save()
        onMessageStatusChanged?(messageId, .delivered)
    }
    
    private func handleReadReceipt(_ envelope: P2PMessageEnvelope) async {
        guard let receiptData = try? JSONDecoder().decode([String: String].self, from: envelope.encryptedPayload),
              let messageIdString = receiptData["messageId"],
              let messageId = UUID(uuidString: messageIdString) else {
            return
        }
        
        // Find and update the message
        guard let message = findMessage(by: messageId) else { return }
        
        message.status = MessageStatus.read
        try? modelContext?.save()
        onMessageStatusChanged?(messageId, .read)
    }
    
    // MARK: - Private Helpers
    
    private func setupCallbacks() {
        p2pService.onMessageReceived = { [weak self] envelope in
            Task { @MainActor in
                switch envelope.messageType {
                case .message:
                    await self?.handleIncomingMessage(envelope)
                case .deliveryReceipt:
                    await self?.handleDeliveryReceipt(envelope)
                case .readReceipt:
                    await self?.handleReadReceipt(envelope)
                case .presence:
                    // Handle presence updates
                    break
                case .handshake:
                    // Handle handshake for key exchange
                    break
                case .contactRequest, .contactAccept, .contactDecline:
                    self?.contactRequestService?.handleIncomingRequest(envelope)
                }
            }
        }
        
        p2pService.onPeerConnected = { [weak self] peerId in
            Task { @MainActor in
                self?.presenceService?.handlePeerConnected(peerId)
                self?.onContactOnlineStatusChanged?(peerId, true)
            }
        }
        
        p2pService.onPeerDisconnected = { [weak self] peerId in
            Task { @MainActor in
                self?.presenceService?.handlePeerDisconnected(peerId)
                self?.onContactOnlineStatusChanged?(peerId, false)
            }
        }
        
        p2pService.onMessageSent = { [weak self] messageId in
            Task { @MainActor in
                self?.onMessageStatusChanged?(messageId, .sent)
            }
        }
        
        p2pService.onMessageFailed = { [weak self] messageId, _ in
            Task { @MainActor in
                self?.onMessageStatusChanged?(messageId, .failed)
            }
        }
    }
    
    @MainActor
    private func findOrCreateConversation(for peerId: String) -> (Contact, Conversation)? {
        guard let context = modelContext else { return nil }
        
        // Find contact by peer ID
        let contactDescriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        
        var contact = try? context.fetch(contactDescriptor).first
        
        // If not found by peer ID, try to find by public key match
        if contact == nil {
            print("[MessageTransport] Contact not found by peerId: \(peerId.prefix(16))..., searching by public key")
            
            // Get the peer info from P2P service to get the public key
            if let peerInfo = p2pService.getPeerInfo(for: peerId) {
                let publicKey = peerInfo.publicKey
                let allContactsDescriptor = FetchDescriptor<Contact>()
                if let allContacts = try? context.fetch(allContactsDescriptor) {
                    contact = allContacts.first { $0.publicKey == publicKey }
                    if let foundContact = contact {
                        print("[MessageTransport] Found contact by public key: \(foundContact.displayName)")
                        // Update the contact's peerId to match current network ID
                        foundContact.peerId = peerId
                        try? context.save()
                    }
                }
            }
        }
        
        guard let contact = contact else {
            print("[MessageTransport] No contact found for peerId: \(peerId.prefix(16))...")
            return nil
        }
        
        // Find existing conversation with this contact
        let conversationDescriptor = FetchDescriptor<Conversation>()
        if let conversations = try? context.fetch(conversationDescriptor) {
            if let existingConversation = conversations.first(where: { 
                $0.type == .oneToOne && $0.participants.contains(where: { $0.id == contact.id })
            }) {
                return (contact, existingConversation)
            }
        }
        
        // Create new conversation
        let conversation = Conversation(type: .oneToOne)
        conversation.participants.append(contact)
        context.insert(conversation)
        
        return (contact, conversation)
    }
    
    @MainActor
    private func findMessage(by id: UUID) -> Message? {
        guard let context = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<Message>(
            predicate: #Predicate { $0.id == id }
        )
        
        return try? context.fetch(descriptor).first
    }
}
