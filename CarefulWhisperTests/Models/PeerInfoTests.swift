import Testing
import Foundation
@testable import CarefulWhisper

@Suite("PeerInfo Tests")
struct PeerInfoTests {
    
    @Test("PeerInfo initialization sets properties correctly")
    func testPeerInfoInit() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let peerInfo = PeerInfo(
            id: "peer123",
            displayName: "Alice",
            publicKey: publicKey,
            connectionType: .multipeer
        )
        
        #expect(peerInfo.id == "peer123")
        #expect(peerInfo.displayName == "Alice")
        #expect(peerInfo.publicKey == publicKey)
        #expect(peerInfo.connectionType == .multipeer)
        #expect(peerInfo.isConnected == false)
    }
    
    @Test("PeerInfo equality is based on id")
    func testPeerInfoEquality() {
        let publicKey1 = Data(repeating: 0xAB, count: 32)
        let publicKey2 = Data(repeating: 0xCD, count: 32)
        
        let peer1 = PeerInfo(
            id: "peer123",
            displayName: "Alice",
            publicKey: publicKey1
        )
        
        let peer2 = PeerInfo(
            id: "peer123",
            displayName: "Bob", // Different name
            publicKey: publicKey2 // Different key
        )
        
        let peer3 = PeerInfo(
            id: "peer456",
            displayName: "Alice",
            publicKey: publicKey1
        )
        
        #expect(peer1 == peer2) // Same ID = equal
        #expect(peer1 != peer3) // Different ID = not equal
    }
    
    @Test("PeerInfo is hashable")
    func testPeerInfoHashable() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let peer1 = PeerInfo(
            id: "peer123",
            displayName: "Alice",
            publicKey: publicKey
        )
        
        let peer2 = PeerInfo(
            id: "peer123",
            displayName: "Alice",
            publicKey: publicKey
        )
        
        var set = Set<PeerInfo>()
        set.insert(peer1)
        set.insert(peer2)
        
        #expect(set.count == 1) // Same ID, should only have one entry
    }
    
    @Test("PeerInfo is codable")
    func testPeerInfoCodable() throws {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let original = PeerInfo(
            id: "peer123",
            displayName: "Alice",
            publicKey: publicKey,
            connectionType: .multipeer
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PeerInfo.self, from: data)
        
        #expect(decoded.id == original.id)
        #expect(decoded.displayName == original.displayName)
        #expect(decoded.publicKey == original.publicKey)
        #expect(decoded.connectionType == original.connectionType)
    }
}

@Suite("P2PMessageEnvelope Tests")
struct P2PMessageEnvelopeTests {
    
    @Test("P2PMessageEnvelope initialization sets properties correctly")
    func testEnvelopeInit() {
        let payload = Data("encrypted message".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender123",
            recipientId: "recipient456",
            encryptedPayload: payload,
            messageType: .message
        )
        
        #expect(envelope.senderId == "sender123")
        #expect(envelope.recipientId == "recipient456")
        #expect(envelope.encryptedPayload == payload)
        #expect(envelope.messageType == .message)
    }
    
    @Test("P2PMessageEnvelope is codable")
    func testEnvelopeCodable() throws {
        let payload = Data("encrypted message".utf8)
        let original = P2PMessageEnvelope(
            senderId: "sender123",
            recipientId: "recipient456",
            encryptedPayload: payload,
            messageType: .deliveryReceipt
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(P2PMessageEnvelope.self, from: data)
        
        #expect(decoded.id == original.id)
        #expect(decoded.senderId == original.senderId)
        #expect(decoded.recipientId == original.recipientId)
        #expect(decoded.encryptedPayload == original.encryptedPayload)
        #expect(decoded.messageType == original.messageType)
    }
    
    @Test("P2PMessageEnvelope message types are distinct")
    func testMessageTypes() {
        let payload = Data()
        
        let message = P2PMessageEnvelope(
            senderId: "s",
            recipientId: "r",
            encryptedPayload: payload,
            messageType: .message
        )
        
        let delivery = P2PMessageEnvelope(
            senderId: "s",
            recipientId: "r",
            encryptedPayload: payload,
            messageType: .deliveryReceipt
        )
        
        let read = P2PMessageEnvelope(
            senderId: "s",
            recipientId: "r",
            encryptedPayload: payload,
            messageType: .readReceipt
        )
        
        #expect(message.messageType != delivery.messageType)
        #expect(delivery.messageType != read.messageType)
        #expect(message.messageType != read.messageType)
    }
}

@Suite("QueuedMessage Tests")
struct QueuedMessageTests {
    
    @Test("QueuedMessage initialization from envelope")
    func testQueuedMessageInit() {
        let payload = Data("test".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "recipient",
            encryptedPayload: payload
        )
        
        let queued = QueuedMessage(envelope: envelope)
        
        #expect(queued.id == envelope.id)
        #expect(queued.envelope.senderId == "sender")
        #expect(queued.retryCount == 0)
        #expect(queued.lastRetryAt == nil)
        #expect(queued.shouldRetry == true)
    }
    
    @Test("QueuedMessage retry logic")
    func testQueuedMessageRetry() {
        let payload = Data("test".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "recipient",
            encryptedPayload: payload
        )
        
        var queued = QueuedMessage(envelope: envelope)
        
        // Initial state
        #expect(queued.shouldRetry == true)
        #expect(queued.retryDelay == 1.0) // 2^0 = 1
        
        // After some retries
        queued.retryCount = 3
        #expect(queued.shouldRetry == true)
        #expect(queued.retryDelay == 8.0) // 2^3 = 8
        
        // After more retries
        queued.retryCount = 6
        #expect(queued.shouldRetry == true)
        #expect(queued.retryDelay == 60.0) // min(2^6, 60) = 60
        
        // After max retries
        queued.retryCount = 10
        #expect(queued.shouldRetry == false)
    }
    
    @Test("QueuedMessage is codable")
    func testQueuedMessageCodable() throws {
        let payload = Data("test".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "recipient",
            encryptedPayload: payload
        )
        
        var original = QueuedMessage(envelope: envelope)
        original.retryCount = 3
        original.lastRetryAt = Date()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(QueuedMessage.self, from: data)
        
        #expect(decoded.id == original.id)
        #expect(decoded.retryCount == original.retryCount)
        #expect(decoded.envelope.senderId == original.envelope.senderId)
    }
}
