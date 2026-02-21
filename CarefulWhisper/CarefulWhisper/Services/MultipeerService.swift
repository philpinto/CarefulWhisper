import Foundation
import MultipeerConnectivity
import Observation

/// Protocol for receiving P2P network events
protocol P2PNetworkDelegate: AnyObject {
    func didDiscoverPeer(_ peer: PeerInfo)
    func didLosePeer(_ peerId: String)
    func didConnectToPeer(_ peerId: String)
    func didDisconnectFromPeer(_ peerId: String)
    func didReceiveMessage(_ envelope: P2PMessageEnvelope)
    func didFailToSendMessage(_ messageId: UUID, error: Error)
}

/// Errors that can occur during P2P operations
enum MultipeerError: Error, LocalizedError {
    case notStarted
    case peerNotFound
    case connectionFailed
    case sendFailed
    case encodingFailed
    case decodingFailed
    case invalidPeerData
    
    var errorDescription: String? {
        switch self {
        case .notStarted: return "Multipeer service not started"
        case .peerNotFound: return "Peer not found"
        case .connectionFailed: return "Failed to connect to peer"
        case .sendFailed: return "Failed to send message"
        case .encodingFailed: return "Failed to encode message"
        case .decodingFailed: return "Failed to decode message"
        case .invalidPeerData: return "Invalid peer data received"
        }
    }
}

/// Service for local network P2P communication using Apple's Multipeer Connectivity
@Observable
final class MultipeerService: NSObject {
    // MARK: - Properties
    
    private let serviceType = "carefulwhisper"
    private var peerId: MCPeerID?
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private(set) var isRunning = false
    private(set) var discoveredPeers: [String: PeerInfo] = [:]
    private(set) var connectedPeers: Set<String> = []
    
    weak var delegate: P2PNetworkDelegate?
    
    private var localDisplayName: String = ""
    private var localPublicKey: Data = Data()
    
    // Map MCPeerID to our peer ID string
    private var mcPeerIdMap: [MCPeerID: String] = [:]
    private var reversePeerIdMap: [String: MCPeerID] = [:]
    
    // MARK: - Lifecycle
    
    func start(displayName: String, publicKey: Data) throws {
        guard !isRunning else { return }
        
        print("[MultipeerService] Starting with displayName: \(displayName)")
        
        localDisplayName = displayName
        localPublicKey = publicKey
        
        // Create peer ID with display name
        peerId = MCPeerID(displayName: displayName)
        
        // Create session
        session = MCSession(
            peer: peerId!,
            securityIdentity: nil,
            encryptionPreference: .required
        )
        session?.delegate = self
        
        // Create discovery info with public key
        let discoveryInfo: [String: String] = [
            "publicKey": publicKey.base64EncodedString(),
            "version": "1.0"
        ]
        
        // Start advertising
        advertiser = MCNearbyServiceAdvertiser(
            peer: peerId!,
            discoveryInfo: discoveryInfo,
            serviceType: serviceType
        )
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        // Start browsing
        browser = MCNearbyServiceBrowser(
            peer: peerId!,
            serviceType: serviceType
        )
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isRunning = true
        print("[MultipeerService] Started - advertising and browsing for service type: \(serviceType)")
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        
        advertiser = nil
        browser = nil
        session = nil
        peerId = nil
        
        discoveredPeers.removeAll()
        connectedPeers.removeAll()
        mcPeerIdMap.removeAll()
        reversePeerIdMap.removeAll()
        
        isRunning = false
    }
    
    // MARK: - Connection Management
    
    func connect(to peerId: String) throws {
        guard isRunning else { throw MultipeerError.notStarted }
        guard let mcPeerId = reversePeerIdMap[peerId] else {
            print("[MultipeerService] Cannot connect - peer not found in map: \(peerId.prefix(16))...")
            throw MultipeerError.peerNotFound
        }
        
        // Check if already connected
        if connectedPeers.contains(peerId) {
            print("[MultipeerService] Already connected to peer: \(mcPeerId.displayName)")
            return
        }
        
        print("[MultipeerService] Sending invitation to peer: \(mcPeerId.displayName)")
        browser?.invitePeer(
            mcPeerId,
            to: session!,
            withContext: localPublicKey,
            timeout: 30
        )
    }
    
    func disconnect(from peerId: String) {
        // Multipeer Connectivity doesn't support disconnecting from individual peers
        // The peer will be removed when they disconnect or go out of range
    }
    
    // MARK: - Messaging
    
    func send(_ envelope: P2PMessageEnvelope) throws {
        guard isRunning else { throw MultipeerError.notStarted }
        guard let mcPeerId = reversePeerIdMap[envelope.recipientId] else {
            throw MultipeerError.peerNotFound
        }
        guard let session = session, session.connectedPeers.contains(mcPeerId) else {
            throw MultipeerError.peerNotFound
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(envelope) else {
            throw MultipeerError.encodingFailed
        }
        
        do {
            try session.send(data, toPeers: [mcPeerId], with: .reliable)
        } catch {
            throw MultipeerError.sendFailed
        }
    }
    
    func sendToAllConnected(_ envelope: P2PMessageEnvelope) throws {
        guard isRunning else { throw MultipeerError.notStarted }
        guard let session = session, !session.connectedPeers.isEmpty else {
            throw MultipeerError.peerNotFound
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(envelope) else {
            throw MultipeerError.encodingFailed
        }
        
        try session.send(data, toPeers: session.connectedPeers, with: .reliable)
    }
    
    // MARK: - Peer Info
    
    func getPeerInfo(for peerId: String) -> PeerInfo? {
        discoveredPeers[peerId]
    }
    
    func isConnected(to peerId: String) -> Bool {
        connectedPeers.contains(peerId)
    }
    
    /// Find a discovered peer by their public key
    /// Returns the peerId if found
    func findPeerByPublicKey(_ publicKey: Data) -> String? {
        // First try direct hash lookup (fast path)
        let targetPeerId = publicKey.sha256.hexString
        if discoveredPeers[targetPeerId] != nil {
            return targetPeerId
        }
        
        // Also check if we have it in the reverse map
        if reversePeerIdMap[targetPeerId] != nil {
            return targetPeerId
        }
        
        // Fall back to searching by comparing actual public key bytes
        // This handles cases where the peer's key might be stored differently
        for (peerId, peerInfo) in discoveredPeers {
            if peerInfo.publicKey == publicKey {
                return peerId
            }
        }
        
        return nil
    }
    
    /// Connect to a peer using their public key
    /// This finds the peer by public key and initiates connection
    func connectByPublicKey(_ publicKey: Data) throws {
        guard isRunning else { throw MultipeerError.notStarted }
        
        // First try to find by hash
        var targetPeerId = publicKey.sha256.hexString
        var mcPeerId = reversePeerIdMap[targetPeerId]
        
        // If not found by hash, search by comparing actual public key bytes
        if mcPeerId == nil {
            for (peerId, peerInfo) in discoveredPeers {
                if peerInfo.publicKey == publicKey {
                    targetPeerId = peerId
                    mcPeerId = reversePeerIdMap[peerId]
                    print("[MultipeerService] Found peer by public key comparison: \(peerId.prefix(16))...")
                    break
                }
            }
        }
        
        guard let foundMcPeerId = mcPeerId else {
            print("[MultipeerService] Cannot connect by public key - peer not discovered. Target: \(targetPeerId.prefix(16))...")
            print("[MultipeerService] Known peers: \(reversePeerIdMap.keys.map { String($0.prefix(16)) + "..." })")
            throw MultipeerError.peerNotFound
        }
        
        // Check if already connected
        if connectedPeers.contains(targetPeerId) {
            print("[MultipeerService] Already connected to peer via public key")
            return
        }
        
        print("[MultipeerService] Connecting to peer by public key: \(foundMcPeerId.displayName)")
        browser?.invitePeer(
            foundMcPeerId,
            to: session!,
            withContext: localPublicKey,
            timeout: 30
        )
    }
    
    // MARK: - Private Helpers
    
    private func peerIdString(from mcPeerId: MCPeerID, publicKey: Data) -> String {
        // Create a unique ID from the public key hash
        publicKey.sha256.hexString
    }
}

// MARK: - MCSessionDelegate

extension MultipeerService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        guard let ourPeerId = mcPeerIdMap[peerID] else {
            // Peer not in map yet - this can happen during initial connection handshake
            // The peer will be added to the map when browser discovers them or advertiser receives invitation
            print("[MultipeerService] Session state changed for unmapped peer: \(peerID.displayName) - state: \(state.rawValue)")
            return
        }
        
        Task { @MainActor in
            switch state {
            case .connected:
                print("[MultipeerService] Connected to peer: \(peerID.displayName)")
                connectedPeers.insert(ourPeerId)
                if var peerInfo = discoveredPeers[ourPeerId] {
                    peerInfo.isConnected = true
                    discoveredPeers[ourPeerId] = peerInfo
                }
                delegate?.didConnectToPeer(ourPeerId)
                
            case .notConnected:
                print("[MultipeerService] Disconnected from peer: \(peerID.displayName)")
                connectedPeers.remove(ourPeerId)
                if var peerInfo = discoveredPeers[ourPeerId] {
                    peerInfo.isConnected = false
                    discoveredPeers[ourPeerId] = peerInfo
                }
                delegate?.didDisconnectFromPeer(ourPeerId)
                
            case .connecting:
                print("[MultipeerService] Connecting to peer: \(peerID.displayName)")
                
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(P2PMessageEnvelope.self, from: data) else {
            return
        }
        
        Task { @MainActor in
            delegate?.didReceiveMessage(envelope)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used - we use data messages
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used for MVP - future: file transfers
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used for MVP - future: file transfers
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Accept all invitations for now
        // In future: verify the peer's public key matches a known contact
        
        if let publicKeyData = context {
            let ourPeerId = peerIdString(from: peerID, publicKey: publicKeyData)
            mcPeerIdMap[peerID] = ourPeerId
            reversePeerIdMap[ourPeerId] = peerID
            
            // Create or update peer info
            let peerInfo = PeerInfo(
                id: ourPeerId,
                displayName: peerID.displayName,
                publicKey: publicKeyData,
                connectionType: .multipeer
            )
            
            Task { @MainActor in
                discoveredPeers[ourPeerId] = peerInfo
            }
        }
        
        invitationHandler(true, session)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[MultipeerService] ERROR: Failed to start advertising: \(error.localizedDescription)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        guard let publicKeyString = info?["publicKey"],
              let publicKeyData = Data(base64Encoded: publicKeyString) else {
            print("[MultipeerService] Found peer without valid public key: \(peerID.displayName)")
            return
        }
        
        let ourPeerId = peerIdString(from: peerID, publicKey: publicKeyData)
        mcPeerIdMap[peerID] = ourPeerId
        reversePeerIdMap[ourPeerId] = peerID
        
        print("[MultipeerService] Discovered peer: \(peerID.displayName) (peerId: \(ourPeerId.prefix(16))...)")
        
        let peerInfo = PeerInfo(
            id: ourPeerId,
            displayName: peerID.displayName,
            publicKey: publicKeyData,
            connectionType: .multipeer
        )
        
        Task { @MainActor in
            discoveredPeers[ourPeerId] = peerInfo
            delegate?.didDiscoverPeer(peerInfo)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let ourPeerId = mcPeerIdMap[peerID] else { return }
        
        Task { @MainActor in
            discoveredPeers.removeValue(forKey: ourPeerId)
            connectedPeers.remove(ourPeerId)
            mcPeerIdMap.removeValue(forKey: peerID)
            reversePeerIdMap.removeValue(forKey: ourPeerId)
            delegate?.didLosePeer(ourPeerId)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[MultipeerService] ERROR: Failed to start browsing: \(error.localizedDescription)")
    }
}
