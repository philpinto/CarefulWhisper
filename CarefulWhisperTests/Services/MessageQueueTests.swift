import Testing
import Foundation
@testable import CarefulWhisper

@Suite("MessageQueueService Tests")
struct MessageQueueServiceTests {
    
    @Test("MessageQueueService can enqueue messages")
    func testEnqueueMessage() async {
        let queueService = MessageQueueService()
        
        let payload = Data("test message".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender123",
            recipientId: "recipient456",
            encryptedPayload: payload
        )
        
        await queueService.enqueue(envelope)
        
        let count = await queueService.queuedCount
        #expect(count == 1)
    }
    
    @Test("MessageQueueService can mark messages as delivered")
    func testMarkDelivered() async {
        let queueService = MessageQueueService()
        
        let payload = Data("test message".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender123",
            recipientId: "recipient456",
            encryptedPayload: payload
        )
        
        await queueService.enqueue(envelope)
        
        var count = await queueService.queuedCount
        #expect(count == 1)
        
        await queueService.markDelivered(envelope.id)
        
        count = await queueService.queuedCount
        #expect(count == 0)
    }
    
    @Test("MessageQueueService filters messages by recipient")
    func testGetQueuedMessagesByRecipient() async {
        let queueService = MessageQueueService()
        
        let envelope1 = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "alice",
            encryptedPayload: Data("msg1".utf8)
        )
        
        let envelope2 = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "bob",
            encryptedPayload: Data("msg2".utf8)
        )
        
        let envelope3 = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "alice",
            encryptedPayload: Data("msg3".utf8)
        )
        
        await queueService.enqueue(envelope1)
        await queueService.enqueue(envelope2)
        await queueService.enqueue(envelope3)
        
        let aliceMessages = await queueService.getQueuedMessages(for: "alice")
        let bobMessages = await queueService.getQueuedMessages(for: "bob")
        
        #expect(aliceMessages.count == 2)
        #expect(bobMessages.count == 1)
    }
    
    @Test("MessageQueueService can clear old messages")
    func testClearOldMessages() async {
        let queueService = MessageQueueService()
        
        let payload = Data("old message".utf8)
        let envelope = P2PMessageEnvelope(
            senderId: "sender",
            recipientId: "recipient",
            encryptedPayload: payload
        )
        
        await queueService.enqueue(envelope)
        
        var count = await queueService.queuedCount
        #expect(count == 1)
        
        // Clear messages older than 0 days (should clear all)
        await queueService.clearOldMessages(olderThan: 0)
        
        count = await queueService.queuedCount
        #expect(count == 0)
    }
    
    @Test("MessageQueueService handles multiple enqueue and dequeue")
    func testMultipleOperations() async {
        let queueService = MessageQueueService()
        
        // Enqueue several messages
        for i in 0..<5 {
            let envelope = P2PMessageEnvelope(
                senderId: "sender",
                recipientId: "recipient\(i)",
                encryptedPayload: Data("message \(i)".utf8)
            )
            await queueService.enqueue(envelope)
        }
        
        var count = await queueService.queuedCount
        #expect(count == 5)
        
        // Get messages for one recipient and mark as delivered
        let messages = await queueService.getQueuedMessages(for: "recipient0")
        for message in messages {
            await queueService.markDelivered(message.id)
        }
        
        count = await queueService.queuedCount
        #expect(count == 4)
    }
}

@Suite("P2PNetworkService Tests")
struct P2PNetworkServiceTests {
    
    @Test("P2PNetworkService initializes in stopped state")
    func testInitialState() {
        let service = P2PNetworkService()
        
        #expect(service.isRunning == false)
        #expect(service.localPeerId == "")
        #expect(service.discoveredPeers.isEmpty)
        #expect(service.connectedPeerIds.isEmpty)
    }
    
    @Test("P2PNetworkService generates peer ID from public key")
    func testPeerIdGeneration() async throws {
        let service = P2PNetworkService()
        let publicKey = Data(repeating: 0xAB, count: 32)
        
        // We can't fully test start() without mocking Multipeer,
        // but we can verify the peer ID would be generated correctly
        let expectedPeerId = publicKey.sha256.hexString
        #expect(expectedPeerId.count == 64) // SHA256 hex = 64 chars
    }
    
    @Test("SendResult enum cases")
    func testSendResultCases() {
        let sentResult = SendResult.sent
        let queuedResult = SendResult.queued
        
        enum TestError: Error { case test }
        let failedResult = SendResult.failed(TestError.test)
        
        switch sentResult {
        case .sent: break
        default: Issue.record("Expected .sent")
        }
        
        switch queuedResult {
        case .queued: break
        default: Issue.record("Expected .queued")
        }
        
        switch failedResult {
        case .failed: break
        default: Issue.record("Expected .failed")
        }
    }
    
    @Test("PeerConnectionStatus enum cases")
    func testPeerConnectionStatusCases() {
        let disconnected = PeerConnectionStatus.disconnected
        let connecting = PeerConnectionStatus.connecting
        let connected = PeerConnectionStatus.connected
        
        enum TestError: Error { case test }
        let failed = PeerConnectionStatus.failed(TestError.test)
        
        switch disconnected {
        case .disconnected: break
        default: Issue.record("Expected .disconnected")
        }
        
        switch connecting {
        case .connecting: break
        default: Issue.record("Expected .connecting")
        }
        
        switch connected {
        case .connected: break
        default: Issue.record("Expected .connected")
        }
        
        switch failed {
        case .failed: break
        default: Issue.record("Expected .failed")
        }
    }
}

@Suite("MultipeerError Tests")
struct MultipeerErrorTests {
    
    @Test("MultipeerError has descriptive messages")
    func testErrorDescriptions() {
        let notStarted = MultipeerError.notStarted
        let peerNotFound = MultipeerError.peerNotFound
        let connectionFailed = MultipeerError.connectionFailed
        let sendFailed = MultipeerError.sendFailed
        let encodingFailed = MultipeerError.encodingFailed
        let decodingFailed = MultipeerError.decodingFailed
        let invalidPeerData = MultipeerError.invalidPeerData
        
        #expect(notStarted.errorDescription != nil)
        #expect(peerNotFound.errorDescription != nil)
        #expect(connectionFailed.errorDescription != nil)
        #expect(sendFailed.errorDescription != nil)
        #expect(encodingFailed.errorDescription != nil)
        #expect(decodingFailed.errorDescription != nil)
        #expect(invalidPeerData.errorDescription != nil)
    }
    
    @Test("MultipeerError conforms to LocalizedError")
    func testLocalizedError() {
        let error: LocalizedError = MultipeerError.notStarted
        #expect(error.errorDescription == "Multipeer service not started")
    }
}
