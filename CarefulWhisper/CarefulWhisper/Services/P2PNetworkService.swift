import Foundation
import Observation

/// Connection status for a peer
enum PeerConnectionStatus {
    case disconnected
    case connecting
    case connected
    case failed(Error)
}

/// Result of sending a message
enum SendResult {
    case sent
    case queued
    case failed(Error)
}

/// Unified P2P networking service that abstracts transport layers
/// Currently supports: Multipeer Connectivity (local network)
/// Future: libp2p (internet DHT)
@Observable
final class P2PNetworkService: P2PNetworkDelegate {
    // MARK: - Properties
    
    private let multipeerService: MultipeerService
    private let messageQueueService: MessageQueueService
    
    private(set) var isRunning = false
    private(set) var localPeerId: String = ""
    
    // Callbacks for UI/ViewModels
    var onPeerDiscovered: ((PeerInfo) -> Void)?
    var onPeerLost: ((String) -> Void)?
    var onPeerConnected: ((String) -> Void)?
    var onPeerDisconnected: ((String) -> Void)?
    var onMessageReceived: ((P2PMessageEnvelope) -> Void)?
    var onMessageSent: ((UUID) -> Void)?
    var onMessageFailed: ((UUID, Error) -> Void)?
    
    // MARK: - Computed Properties
    
    var discoveredPeers: [PeerInfo] {
        Array(multipeerService.discoveredPeers.values)
    }
    
    var connectedPeerIds: [String] {
        Array(multipeerService.connectedPeers)
    }
    
    private(set) var queuedMessageCount: Int = 0
    
    func refreshQueuedMessageCount() async {
        queuedMessageCount = await messageQueueService.queuedCount
    }
    
    // MARK: - Initialization
    
    init() {
        self.multipeerService = MultipeerService()
        self.messageQueueService = MessageQueueService()
        
        multipeerService.delegate = self
        
        // Set up message queue callback
        Task {
            await messageQueueService.setOnMessageReady { [weak self] envelope in
                Task { @MainActor in
                    self?.attemptSend(envelope)
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    func start(displayName: String, publicKey: Data) async throws {
        guard !isRunning else { return }
        
        // Generate local peer ID from public key
        localPeerId = publicKey.sha256.hexString
        
        // Start multipeer for local network
        try multipeerService.start(displayName: displayName, publicKey: publicKey)
        
        // Start message queue processor
        await messageQueueService.start()
        
        isRunning = true
    }
    
    func stop() async {
        multipeerService.stop()
        await messageQueueService.stop()
        isRunning = false
    }
    
    // MARK: - Connection Management
    
    func connect(to peerId: String) async throws {
        try multipeerService.connect(to: peerId)
    }
    
    func isConnected(to peerId: String) -> Bool {
        multipeerService.isConnected(to: peerId)
    }
    
    func getPeerInfo(for peerId: String) -> PeerInfo? {
        multipeerService.getPeerInfo(for: peerId)
    }
    
    /// Find a discovered peer by their public key
    func findPeerByPublicKey(_ publicKey: Data) -> String? {
        multipeerService.findPeerByPublicKey(publicKey)
    }
    
    /// Connect to a peer using their public key
    func connectByPublicKey(_ publicKey: Data) async throws {
        try multipeerService.connectByPublicKey(publicKey)
    }
    
    // MARK: - Messaging
    
    /// Send a message to a peer
    /// If the peer is connected, sends immediately
    /// Otherwise, queues for later delivery
    func send(
        encryptedPayload: Data,
        to recipientId: String,
        messageType: P2PMessageEnvelope.P2PMessageType = .message
    ) async -> SendResult {
        let envelope = P2PMessageEnvelope(
            senderId: localPeerId,
            recipientId: recipientId,
            encryptedPayload: encryptedPayload,
            messageType: messageType
        )
        
        // Try to send immediately if connected
        if multipeerService.isConnected(to: recipientId) {
            do {
                try multipeerService.send(envelope)
                onMessageSent?(envelope.id)
                return .sent
            } catch {
                // Failed to send, queue it
                await messageQueueService.enqueue(envelope)
                return .queued
            }
        } else {
            // Not connected, queue for later
            await messageQueueService.enqueue(envelope)
            return .queued
        }
    }
    
    /// Send a delivery receipt
    func sendDeliveryReceipt(for messageId: UUID, to recipientId: String) async {
        let receiptData = try? JSONEncoder().encode(["messageId": messageId.uuidString])
        guard let data = receiptData else { return }
        
        _ = await send(
            encryptedPayload: data,
            to: recipientId,
            messageType: .deliveryReceipt
        )
    }
    
    /// Send a read receipt
    func sendReadReceipt(for messageId: UUID, to recipientId: String) async {
        let receiptData = try? JSONEncoder().encode(["messageId": messageId.uuidString])
        guard let data = receiptData else { return }
        
        _ = await send(
            encryptedPayload: data,
            to: recipientId,
            messageType: .readReceipt
        )
    }
    
    // MARK: - Private Helpers
    
    private func attemptSend(_ envelope: P2PMessageEnvelope) {
        guard multipeerService.isConnected(to: envelope.recipientId) else {
            return
        }
        
        do {
            try multipeerService.send(envelope)
            Task {
                await messageQueueService.markDelivered(envelope.id)
            }
            onMessageSent?(envelope.id)
        } catch {
            onMessageFailed?(envelope.id, error)
        }
    }
    
    // MARK: - P2PNetworkDelegate
    
    func didDiscoverPeer(_ peer: PeerInfo) {
        onPeerDiscovered?(peer)
        
        // Try to deliver any queued messages for this peer
        Task {
            await messageQueueService.processQueue(for: peer.id)
        }
    }
    
    func didLosePeer(_ peerId: String) {
        onPeerLost?(peerId)
    }
    
    func didConnectToPeer(_ peerId: String) {
        onPeerConnected?(peerId)
        
        // Try to deliver any queued messages for this peer
        Task {
            await messageQueueService.processQueue(for: peerId)
        }
    }
    
    func didDisconnectFromPeer(_ peerId: String) {
        onPeerDisconnected?(peerId)
    }
    
    func didReceiveMessage(_ envelope: P2PMessageEnvelope) {
        onMessageReceived?(envelope)
    }
    
    func didFailToSendMessage(_ messageId: UUID, error: Error) {
        onMessageFailed?(messageId, error)
    }
}
