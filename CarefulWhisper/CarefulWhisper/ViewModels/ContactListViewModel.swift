import Foundation
import SwiftData
import Observation

/// Manages contact list display and operations
@Observable
@MainActor
final class ContactListViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private var contactRequestService: ContactRequestService?
    
    var contacts: [Contact] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?
    
    // MARK: - Computed Properties
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts.sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
        }
        return contacts
            .filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
            .sorted { $0.displayName.lowercased() < $1.displayName.lowercased() }
    }
    
    var hasContacts: Bool {
        !contacts.isEmpty
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, contactRequestService: ContactRequestService? = nil) {
        self.modelContext = modelContext
        self.contactRequestService = contactRequestService
        loadContacts()
    }
    
    func setContactRequestService(_ service: ContactRequestService) {
        self.contactRequestService = service
    }
    
    // MARK: - Public Methods
    
    func loadContacts() {
        let descriptor = FetchDescriptor<Contact>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        
        do {
            contacts = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to load contacts: \(error.localizedDescription)"
        }
    }
    
    func deleteContact(_ contact: Contact) {
        // Also delete any associated contact requests
        let peerId = contact.peerId
        let requestDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.senderPeerId == peerId }
        )
        if let requests = try? modelContext.fetch(requestDescriptor) {
            for request in requests {
                modelContext.delete(request)
            }
        }
        
        modelContext.delete(contact)
        
        do {
            try modelContext.save()
            loadContacts()
        } catch {
            errorMessage = "Failed to delete contact: \(error.localizedDescription)"
        }
    }
    
    func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = filteredContacts[index]
            modelContext.delete(contact)
        }
        
        do {
            try modelContext.save()
            loadContacts()
        } catch {
            errorMessage = "Failed to delete contacts: \(error.localizedDescription)"
        }
    }
    
    /// Sends a contact request from parsed QR code data
    func sendContactRequest(displayName: String, publicKey: Data, peerId: String) async -> Bool {
        // Check if contact already exists
        let existingDescriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        
        if let existing = try? modelContext.fetch(existingDescriptor), !existing.isEmpty {
            errorMessage = "Contact already exists"
            return false
        }
        
        // Check if we already have a pending request (ignore accepted/declined ones)
        let pendingStatus = ContactRequestStatus.pending
        let existingRequestDescriptor = FetchDescriptor<ContactRequest>(
            predicate: #Predicate { $0.senderPeerId == peerId && $0.status == pendingStatus }
        )
        
        if let existing = try? modelContext.fetch(existingRequestDescriptor), !existing.isEmpty {
            errorMessage = "Contact request already sent"
            return false
        }
        
        guard let service = contactRequestService else {
            errorMessage = "Service not available"
            return false
        }
        
        await service.sendContactRequest(to: peerId, peerName: displayName, peerPublicKey: publicKey)
        successMessage = "Contact request sent to \(displayName)"
        return true
    }
    
    /// Directly adds a contact (used when accepting requests)
    func addContact(displayName: String, publicKey: Data, peerId: String) -> Contact? {
        let contact = Contact(
            displayName: displayName,
            publicKey: publicKey,
            peerId: peerId
        )
        
        modelContext.insert(contact)
        
        do {
            try modelContext.save()
            loadContacts()
            return contact
        } catch {
            errorMessage = "Failed to add contact: \(error.localizedDescription)"
            return nil
        }
    }
}
