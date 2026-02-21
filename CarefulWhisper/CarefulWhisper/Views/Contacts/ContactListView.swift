import SwiftUI
import SwiftData

/// Displays the list of contacts
struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var appServices
    
    @Query(sort: \ContactRequest.receivedAt, order: .reverse)
    private var allRequests: [ContactRequest]
    
    @Query(sort: \Contact.displayName)
    private var contacts: [Contact]
    
    private var pendingRequests: [ContactRequest] {
        allRequests.filter { $0.isIncoming && $0.status == .pending }
    }
    
    @State private var viewModel: ContactListViewModel?
    @State private var showAddContact = false
    @State private var selectedContact: Contact?
    @State private var searchText = ""
    
    private var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if !contacts.isEmpty || !pendingRequests.isEmpty {
                    contactList
                } else {
                    emptyState
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddContact = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search contacts")
            .sheet(isPresented: $showAddContact, onDismiss: nil) {
                AddContactView(viewModel: getOrCreateViewModel())
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact, onDelete: {
                    viewModel?.deleteContact(contact)
                    selectedContact = nil
                })
            }
        }
        .onAppear {
            _ = getOrCreateViewModel()
        }
    }
    
    private func getOrCreateViewModel() -> ContactListViewModel {
        if let vm = viewModel {
            return vm
        }
        let vm = ContactListViewModel(modelContext: modelContext)
        if let service = appServices?.contactRequestService {
            vm.setContactRequestService(service)
        }
        viewModel = vm
        return vm
    }
    
    // MARK: - Contact List
    
    private var contactList: some View {
        List {
            // Pending contact requests section
            if !pendingRequests.isEmpty {
                Section {
                    ForEach(pendingRequests) { request in
                        ContactRequestRow(
                            request: request,
                            onAccept: {
                                Task {
                                    await appServices?.contactRequestService.acceptRequest(request)
                                }
                            },
                            onDecline: {
                                Task {
                                    await appServices?.contactRequestService.declineRequest(request)
                                }
                            }
                        )
                    }
                } header: {
                    Label("Contact Requests", systemImage: "person.badge.plus")
                }
            }
            
            // Contacts section
            if !filteredContacts.isEmpty {
                Section {
                    ForEach(filteredContacts) { contact in
                        ContactRow(contact: contact)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedContact = contact
                            }
                    }
                    .onDelete { offsets in
                        deleteContacts(at: offsets)
                    }
                } header: {
                    if !pendingRequests.isEmpty {
                        Text("Contacts")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = filteredContacts[index]
            viewModel?.deleteContact(contact)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Contacts", systemImage: "person.2.fill")
        } description: {
            Text("Add contacts by scanning their QR code or entering their ID manually")
        } actions: {
            Button {
                showAddContact = true
            } label: {
                Text("Add Contact")
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

/// Row displaying a single contact
struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(avatarColor)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(initials)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            
            // Name and status
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(contact.isOnline ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(contact.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    private var initials: String {
        let components = contact.displayName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(contact.displayName.prefix(2)).uppercased()
    }
    
    private var avatarColor: Color {
        // Generate consistent color from name
        let hash = contact.displayName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
}

/// Row displaying a pending contact request with accept/decline actions
struct ContactRequestRow: View {
    let request: ContactRequest
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                Circle()
                    .fill(avatarColor)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Text(initials)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                
                // Name and time
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.senderName)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    Text("Wants to connect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Time ago
                Text(timeAgo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onDecline()
                } label: {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
                
                Button {
                    onAccept()
                } label: {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var initials: String {
        let components = request.senderName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(request.senderName.prefix(2)).uppercased()
    }
    
    private var avatarColor: Color {
        let hash = request.senderName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: request.receivedAt, relativeTo: Date())
    }
}

#Preview {
    ContactListView()
        .modelContainer(for: [Contact.self, Conversation.self, Message.self, UserProfile.self, EncryptionKeys.self, ContactRequest.self])
}
