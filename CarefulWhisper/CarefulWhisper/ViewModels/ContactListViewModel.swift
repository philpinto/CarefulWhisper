import Foundation
import SwiftData
import Observation

/// Manages contact list display and operations
@Observable
@MainActor
final class ContactListViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    var contacts: [Contact] = []
    var searchText: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
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
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadContacts()
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
    
    /// Adds a contact from parsed QR code data
    func addContact(displayName: String, publicKey: Data, peerId: String) -> Contact? {
        // Check if contact already exists
        let existingDescriptor = FetchDescriptor<Contact>(
            predicate: #Predicate { $0.peerId == peerId }
        )
        
        if let existing = try? modelContext.fetch(existingDescriptor), !existing.isEmpty {
            errorMessage = "Contact already exists"
            return nil
        }
        
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
