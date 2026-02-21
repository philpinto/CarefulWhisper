import Foundation
import SwiftData
import Observation

/// Manages online/offline presence status for contacts
/// Updates contact status based on P2P network connectivity
@Observable
@MainActor
final class PresenceService {
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private weak var p2pService: P2PNetworkService?
    
    /// Contacts currently online (peer IDs)
    private(set) var onlinePeerIds: Set<String> = []
    
    /// Last seen timestamps for peers
    private var lastSeenTimes: [String: Date] = [:]
    
    // MARK: - Callbacks
    
    var onContactOnlineStatusChanged: ((String, Bool) -> Void)?
    
    // MARK: - Configuration
    
    func configure(modelContext: ModelContext, p2pService: P2PNetworkService) {
        self.modelContext = modelContext
        self.p2pService = p2pService
        
        setupDiscoveryCallback()
    }
    
    /// Called by MessageTransportService when a peer connects
    func handlePeerConnected(_ peerId: String) {
        onlinePeerIds.insert(peerId)
        updateContactStatus(peerId: peerId, isOnline: true)
    }
    
    /// Called by MessageTransportService when a peer disconnects
    func handlePeerDisconnected(_ peerId: String) {
        onlinePeerIds.remove(peerId)
        updateContactStatus(peerId: peerId, isOnline: false)
    }
    
    // MARK: - Public Methods
    
    /// Check if a contact is online by peer ID
    func isOnline(_ peerId: String) -> Bool {
        onlinePeerIds.contains(peerId)
    }
    
    /// Get last seen time for a peer
    func lastSeen(for peerId: String) -> Date? {
        lastSeenTimes[peerId]
    }
    
    /// Update a contact's online status in the database
    func updateContactStatus(peerId: String, isOnline: Bool) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        
        guard let contact = try? context.fetch(descriptor).first else { return }
        
        contact.isOnline = isOnline
        
        if !isOnline {
            contact.lastSeen = Date()
            lastSeenTimes[peerId] = Date()
        }
        
        try? context.save()
        
        onContactOnlineStatusChanged?(peerId, isOnline)
    }
    
    /// Refresh all contact statuses based on current P2P connections
    func refreshAllStatuses() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Contact>()
        guard let contacts = try? context.fetch(descriptor) else { return }
        
        let connectedPeers = Set(p2pService?.connectedPeerIds ?? [])
        
        for contact in contacts {
            let shouldBeOnline = connectedPeers.contains(contact.peerId)
            
            if contact.isOnline != shouldBeOnline {
                contact.isOnline = shouldBeOnline
                
                if !shouldBeOnline {
                    contact.lastSeen = Date()
                }
                
                onContactOnlineStatusChanged?(contact.peerId, shouldBeOnline)
            }
        }
        
        onlinePeerIds = connectedPeers
        try? context.save()
    }
    
    // MARK: - Private Methods
    
    // Only hook into discovery - connection events come through MessageTransportService
    private func setupDiscoveryCallback() {
        p2pService?.onPeerDiscovered = { [weak self] peer in
            Task { @MainActor in
                // Update last seen when peer is discovered (even if not connected)
                self?.lastSeenTimes[peer.id] = Date()
                
                // Auto-connect to known contacts when discovered
                self?.autoConnectIfKnownContact(peer)
            }
        }
    }
    
    /// Automatically connect to a peer if they are a known contact
    private func autoConnectIfKnownContact(_ peer: PeerInfo) {
        guard let context = modelContext else {
            print("[PresenceService] No model context available")
            return
        }
        
        // Check if already connected
        if p2pService?.isConnected(to: peer.id) == true {
            print("[PresenceService] Already connected to peer: \(peer.displayName)")
            // Update online status since we're connected
            onlinePeerIds.insert(peer.id)
            updateContactStatus(peerId: peer.id, isOnline: true)
            return
        }
        
        // Check if this peer is a known contact
        let peerId = peer.id
        let descriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        
        guard let contact = try? context.fetch(descriptor).first else {
            print("[PresenceService] Discovered peer '\(peer.displayName)' is not a known contact (peerId: \(peer.id.prefix(16))...)")
            return
        }
        
        // It's a known contact, try to connect
        print("[PresenceService] Auto-connecting to known contact: \(contact.displayName) (peerId: \(peer.id.prefix(16))...)")
        Task {
            do {
                try await p2pService?.connect(to: peer.id)
                print("[PresenceService] Connection invitation sent to \(contact.displayName)")
            } catch {
                print("[PresenceService] Failed to auto-connect to \(contact.displayName): \(error)")
            }
        }
    }
}
