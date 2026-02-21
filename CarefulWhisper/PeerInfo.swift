import Foundation

/// Represents information about a discovered peer in the P2P network
struct PeerInfo: Identifiable, Equatable, Hashable, Codable {
    let id: String
    let displayName: String
    let publicKey: Data
    var lastSeen: Date
    var isConnected: Bool
    var connectionType: ConnectionType
    
    enum ConnectionType: String, Codable {
        case multipeer    // Local network via Multipeer Connectivity
        case libp2p       // Internet via libp2p (future)
        case unknown
    }
    
    init(id: String, displayName: String, publicKey: Data, connectionType: ConnectionType = .unknown) {
        self.id = id
        self.displayName = displayName
        self.publicKey = publicKey
        self.lastSeen = Date()
        self.isConnected = false
        self.connectionType = connectionType
    }
    
    static func == (lhs: PeerInfo, rhs: PeerInfo) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Message envelope for P2P transport
struct P2PMessageEnvelope: Codable {
    let id: UUID
    let senderId: String
    let recipientId: String
    let encryptedPayload: Data
    let timestamp: Date
    let messageType: P2PMessageType
    
    enum P2PMessageType: String, Codable {
        case message          // Regular encrypted message
        case deliveryReceipt  // Delivery confirmation
        case readReceipt      // Read confirmation
        case presence         // Online/offline status
        case handshake        // Initial connection handshake
    }
    
    init(id: UUID = UUID(), senderId: String, recipientId: String, encryptedPayload: Data, messageType: P2PMessageType = .message) {
        self.id = id
        self.senderId = senderId
        self.recipientId = recipientId
        self.encryptedPayload = encryptedPayload
        self.timestamp = Date()
        self.messageType = messageType
    }
}

/// Queued message for offline delivery
struct QueuedMessage: Codable, Identifiable, Sendable {
    let id: UUID
    let envelope: P2PMessageEnvelope
    let createdAt: Date
    var retryCount: Int
    var lastRetryAt: Date?
    
    init(envelope: P2PMessageEnvelope) {
        self.id = envelope.id
        self.envelope = envelope
        self.createdAt = Date()
        self.retryCount = 0
        self.lastRetryAt = nil
    }
    
    var shouldRetry: Bool {
        retryCount < 10 // Max 10 retries
    }
    
    var retryDelay: TimeInterval {
        // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s, 60s, 60s...
        min(pow(2.0, Double(retryCount)), 60.0)
    }
}
