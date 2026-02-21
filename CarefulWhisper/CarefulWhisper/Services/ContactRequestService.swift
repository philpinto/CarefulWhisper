import Foundation
import SwiftData
import Observation

/// Payload for contact request messages
struct ContactRequestPayload: Codable {
    let senderName: String
    let senderPeerId: String
    let senderPublicKey: Data
    let requestType: RequestType
    
    enum RequestType: String, Codable {
        case request
        case accept
        case decline
    }
}

/// Service for managing contact requests
@Observable
@MainActor
final class ContactRequestService {
    // MARK: - Properties
    
    private var modelContext: ModelContext?
    private weak var p2pService: P2PNetworkService?
    private var userProfile: UserProfile?
    
    /// Pending incoming requests
    private(set) var pendingRequests: [ContactRequest] = []
    
    /// Callback when a new request is received
    var onRequestReceived: ((ContactRequest) -> Void)?
    
    /// Callback when a request is accepted (contact added)
    var onRequestAccepted: ((Contact) -> Void)?
    
    // MARK: - Configuration
    
    func configure(modelContext: ModelContext, p2pService: P2PNetworkService) {
        self.modelContext = modelContext
        self.p2pService = p2pService
        loadPendingRequests()
        loadUserProfile()
        print("[ContactRequest] Configured - profile: \(userProfile?.displayName ?? "nil"), p2p: \(p2pService)")
    }
    
    func loadUserProfile() {
        guard let context = modelContext else {
            print("[ContactRequest] loadUserProfile: No model context")
            return
        }
        let descriptor = FetchDescriptor<UserProfile>()
        userProfile = try? context.fetch(descriptor).first
        print("[ContactRequest] loadUserProfile: \(userProfile?.displayName ?? "nil")")
    }
    
    private func loadPendingRequests() {
        guard let context = modelContext else { return }
        let pendingStatus = ContactRequestStatus.pending
        let descriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.isIncoming && $0.status == pendingStatus }
        )
        pendingRequests = (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Sending Requests
    
    /// Send a contact request to a peer
    func sendContactRequest(to peerId: String, peerName: String, peerPublicKey: Data) async {
        // Reload profile if needed
        if userProfile == nil {
            print("[ContactRequest] Profile is nil, reloading...")
            loadUserProfile()
        }
        
        guard let profile = userProfile else {
            print("[ContactRequest] Cannot send - no profile (profile: \(userProfile?.displayName ?? "nil"))")
            return
        }
        guard let p2p = p2pService else {
            print("[ContactRequest] Cannot send - no p2p service")
            return
        }
        
        // Find the peer by their public key - this handles cases where the peer's
        // current peer ID differs from what was in the QR code
        let computedPeerId = peerPublicKey.sha256.hexString
        let actualPeerId = p2p.findPeerByPublicKey(peerPublicKey) ?? computedPeerId
        
        print("[ContactRequest] Computed peerId from public key: \(computedPeerId.prefix(16))...")
        if actualPeerId != computedPeerId {
            print("[ContactRequest] Found peer with different peerId: \(actualPeerId.prefix(16))...")
        }
        
        // First, ensure we're connected to the peer
        if !p2p.isConnected(to: actualPeerId) {
            print("[ContactRequest] Not connected to \(peerName) (peerId: \(actualPeerId.prefix(16))...), initiating connection...")
            
            if p2p.findPeerByPublicKey(peerPublicKey) == nil {
                print("[ContactRequest] WARNING: Peer not yet discovered on network")
                print("[ContactRequest] Discovered peers: \(p2p.discoveredPeers.map { "\($0.displayName) (\($0.id.prefix(16))...)" })")
            }
            
            do {
                // Connect using public key - this will find the peer by their public key
                try await p2p.connectByPublicKey(peerPublicKey)
                // Wait for the connection to establish
                print("[ContactRequest] Connection invitation sent, waiting for connection...")
                
                // Poll for connection (up to 3 seconds)
                // Re-check the actual peer ID in case it was discovered during connection
                for _ in 0..<6 {
                    try? await Task.sleep(for: .milliseconds(500))
                    let currentPeerId = p2p.findPeerByPublicKey(peerPublicKey) ?? actualPeerId
                    if p2p.isConnected(to: currentPeerId) {
                        print("[ContactRequest] Connected to \(peerName)!")
                        break
                    }
                }
                
                let finalPeerId = p2p.findPeerByPublicKey(peerPublicKey) ?? actualPeerId
                if !p2p.isConnected(to: finalPeerId) {
                    print("[ContactRequest] Connection not established yet, will queue message")
                }
            } catch {
                print("[ContactRequest] Failed to connect to \(peerName): \(error)")
                // Continue anyway - message will be queued
            }
        } else {
            print("[ContactRequest] Already connected to \(peerName)")
        }
        
        let payload = ContactRequestPayload(
            senderName: profile.displayName,
            senderPeerId: profile.peerId,
            senderPublicKey: profile.publicKey,
            requestType: .request
        )
        
        guard let data = try? JSONEncoder().encode(payload) else { return }
        
        // Use the actual discovered peer ID for sending
        let sendToPeerId = p2p.findPeerByPublicKey(peerPublicKey) ?? actualPeerId
        
        print("[ContactRequest] Sending contact request to \(peerName) (peerId: \(sendToPeerId.prefix(16))...)")
        let result = await p2p.send(
            encryptedPayload: data,
            to: sendToPeerId,
            messageType: .contactRequest
        )
        
        switch result {
        case .sent:
            print("[ContactRequest] Contact request sent successfully to \(peerName)")
        case .queued:
            print("[ContactRequest] Contact request queued for \(peerName) (will send when connected)")
        case .failed(let error):
            print("[ContactRequest] Failed to send contact request to \(peerName): \(error)")
        }
        
        // Save outgoing request with the peer ID we actually used
        let request = ContactRequest(
            senderName: peerName,
            senderPeerId: sendToPeerId,
            senderPublicKey: peerPublicKey,
            isIncoming: false
        )
        modelContext?.insert(request)
        try? modelContext?.save()
    }
    
    // MARK: - Receiving Requests
    
    /// Handle an incoming contact request
    func handleIncomingRequest(_ envelope: P2PMessageEnvelope) {
        print("[ContactRequest] handleIncomingRequest called, messageType: \(envelope.messageType)")
        
        guard let payload = try? JSONDecoder().decode(ContactRequestPayload.self, from: envelope.encryptedPayload) else {
            print("[ContactRequest] Failed to decode request payload")
            return
        }
        
        print("[ContactRequest] Decoded payload - type: \(payload.requestType), from: \(payload.senderName)")
        
        switch payload.requestType {
        case .request:
            handleNewRequest(payload)
        case .accept:
            print("[ContactRequest] Processing ACCEPT from \(payload.senderName)")
            handleAcceptedRequest(payload)
        case .decline:
            handleDeclinedRequest(payload)
        }
    }
    
    private func handleNewRequest(_ payload: ContactRequestPayload) {
        guard let context = modelContext else { return }
        
        // Check if we already have this contact
        let peerId = payload.senderPeerId
        let existingContactDescriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        if let _ = try? context.fetch(existingContactDescriptor).first {
            print("[ContactRequest] Already have contact for \(payload.senderName)")
            return
        }
        
        // Check if we already have a pending request from this person
        let pendingStatus = ContactRequestStatus.pending
        let existingRequestDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.senderPeerId == peerId && $0.status == pendingStatus }
        )
        if let _ = try? context.fetch(existingRequestDescriptor).first {
            print("[ContactRequest] Already have pending request from \(payload.senderName)")
            return
        }
        
        // Delete any old non-pending requests from this sender (allows re-adding after delete)
        let allRequestsDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.senderPeerId == peerId }
        )
        if let oldRequests = try? context.fetch(allRequestsDescriptor) {
            for oldRequest in oldRequests {
                print("[ContactRequest] Removing old request with status: \(oldRequest.status)")
                context.delete(oldRequest)
            }
        }
        
        // Create new incoming request
        let request = ContactRequest(
            senderName: payload.senderName,
            senderPeerId: payload.senderPeerId,
            senderPublicKey: payload.senderPublicKey,
            isIncoming: true
        )
        
        context.insert(request)
        try? context.save()
        
        pendingRequests.append(request)
        
        print("[ContactRequest] Received contact request from \(payload.senderName)")
        onRequestReceived?(request)
    }
    
    private func handleAcceptedRequest(_ payload: ContactRequestPayload) {
        print("[ContactRequest] handleAcceptedRequest called for \(payload.senderName)")
        
        guard let context = modelContext else {
            print("[ContactRequest] ERROR: No model context in handleAcceptedRequest")
            return
        }
        
        // Check if contact already exists
        let peerId = payload.senderPeerId
        let existingDescriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        if let _ = try? context.fetch(existingDescriptor).first {
            print("[ContactRequest] Contact already exists for \(payload.senderName), skipping insert")
            return
        }
        
        // They accepted our request - add them as a contact
        let contact = Contact(
            displayName: payload.senderName,
            publicKey: payload.senderPublicKey,
            peerId: payload.senderPeerId
        )
        
        context.insert(contact)
        print("[ContactRequest] Inserted contact: \(contact.displayName)")
        
        // Mark our outgoing request as accepted
        let requestDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.senderPeerId == peerId && !$0.isIncoming }
        )
        if let request = try? context.fetch(requestDescriptor).first {
            request.status = .accepted
            print("[ContactRequest] Marked outgoing request as accepted")
        } else {
            print("[ContactRequest] No outgoing request found for peerId: \(peerId.prefix(16))...")
        }
        
        do {
            try context.save()
            print("[ContactRequest] Saved contact successfully")
        } catch {
            print("[ContactRequest] ERROR saving: \(error)")
        }
        
        print("[ContactRequest] \(payload.senderName) accepted our contact request!")
        onRequestAccepted?(contact)
    }
    
    private func handleDeclinedRequest(_ payload: ContactRequestPayload) {
        guard let context = modelContext else { return }
        
        // They declined our request
        let peerId = payload.senderPeerId
        let descriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.senderPeerId == peerId && !$0.isIncoming }
        )
        if let request = try? context.fetch(descriptor).first {
            request.status = .declined
        }
        
        try? context.save()
        print("[ContactRequest] \(payload.senderName) declined our contact request")
    }
    
    // MARK: - Responding to Requests
    
    /// Accept an incoming contact request
    func acceptRequest(_ request: ContactRequest) async {
        print("[ContactRequest] acceptRequest called for: \(request.senderName)")
        
        guard let context = modelContext else {
            print("[ContactRequest] ERROR: No model context")
            return
        }
        guard let profile = userProfile else {
            print("[ContactRequest] ERROR: No user profile - reloading...")
            loadUserProfile()
            guard let profile = userProfile else {
                print("[ContactRequest] ERROR: Still no user profile after reload")
                return
            }
            await acceptRequestWithProfile(request, context: context, profile: profile)
            return
        }
        guard let p2p = p2pService else {
            print("[ContactRequest] ERROR: No P2P service")
            return
        }
        
        await acceptRequestInternal(request, context: context, profile: profile, p2p: p2p)
    }
    
    private func acceptRequestWithProfile(_ request: ContactRequest, context: ModelContext, profile: UserProfile) async {
        guard let p2p = p2pService else {
            print("[ContactRequest] ERROR: No P2P service in acceptRequestWithProfile")
            return
        }
        await acceptRequestInternal(request, context: context, profile: profile, p2p: p2p)
    }
    
    private func acceptRequestInternal(_ request: ContactRequest, context: ModelContext, profile: UserProfile, p2p: P2PNetworkService) async {
        print("[ContactRequest] Adding contact: \(request.senderName)")
        
        // Re-fetch the request from database to ensure we have the managed object
        let requestId = request.id
        let requestDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.id == requestId }
        )
        guard let managedRequest = try? context.fetch(requestDescriptor).first else {
            print("[ContactRequest] ERROR: Could not find request in database")
            return
        }
        
        // Check if contact already exists
        let peerId = managedRequest.senderPeerId
        let existingDescriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        
        var contact: Contact?
        if let existingContact = try? context.fetch(existingDescriptor).first {
            print("[ContactRequest] Contact already exists for \(managedRequest.senderName), skipping insert")
            contact = existingContact
        } else {
            // Add them as a contact
            let newContact = Contact(
                displayName: managedRequest.senderName,
                publicKey: managedRequest.senderPublicKey,
                peerId: managedRequest.senderPeerId
            )
            context.insert(newContact)
            contact = newContact
            print("[ContactRequest] Inserted new contact: \(newContact.displayName)")
        }
        
        // Update request status on the managed object
        managedRequest.status = .accepted
        print("[ContactRequest] Updated request status to accepted")
        
        // Remove from pending
        pendingRequests.removeAll { $0.id == managedRequest.id }
        
        do {
            try context.save()
            print("[ContactRequest] Contact saved successfully")
        } catch {
            print("[ContactRequest] ERROR saving contact: \(error)")
        }
        
        // Send acceptance message
        let payload = ContactRequestPayload(
            senderName: profile.displayName,
            senderPeerId: profile.peerId,
            senderPublicKey: profile.publicKey,
            requestType: .accept
        )
        
        guard let data = try? JSONEncoder().encode(payload) else {
            print("[ContactRequest] ERROR: Failed to encode payload")
            return
        }
        
        print("[ContactRequest] Sending acceptance to \(managedRequest.senderName)")
        let result = await p2p.send(
            encryptedPayload: data,
            to: managedRequest.senderPeerId,
            messageType: .contactAccept
        )
        print("[ContactRequest] Send result: \(result)")
        
        if let contact = contact {
            onRequestAccepted?(contact)
        }
    }
    
    /// Decline an incoming contact request
    func declineRequest(_ request: ContactRequest) async {
        guard let context = modelContext, let profile = userProfile, let p2p = p2pService else { return }
        
        // Re-fetch the request from database to ensure we have the managed object
        let requestId = request.id
        let requestDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.id == requestId }
        )
        guard let managedRequest = try? context.fetch(requestDescriptor).first else {
            print("[ContactRequest] ERROR: Could not find request in database for decline")
            return
        }
        
        // Update request status
        managedRequest.status = .declined
        
        // Remove from pending
        pendingRequests.removeAll { $0.id == managedRequest.id }
        
        try? context.save()
        
        // Send decline
        let payload = ContactRequestPayload(
            senderName: profile.displayName,
            senderPeerId: profile.peerId,
            senderPublicKey: profile.publicKey,
            requestType: .decline
        )
        
        guard let data = try? JSONEncoder().encode(payload) else { return }
        
        print("[ContactRequest] Declining request from \(managedRequest.senderName)")
        _ = await p2p.send(
            encryptedPayload: data,
            to: managedRequest.senderPeerId,
            messageType: .contactDecline
        )
    }
}
