import SwiftUI
import SwiftData

/// Displays the list of contacts
struct ContactListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ContactListViewModel?
    @State private var showAddContact = false
    @State private var selectedContact: Contact?
    
    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.hasContacts {
                        contactList(vm)
                    } else {
                        emptyState
                    }
                } else {
                    ProgressView()
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
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), prompt: "Search contacts")
            .sheet(isPresented: $showAddContact) {
                if let vm = viewModel {
                    AddContactView(viewModel: vm)
                }
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact, onDelete: {
                    viewModel?.deleteContact(contact)
                    selectedContact = nil
                })
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ContactListViewModel(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - Contact List
    
    private func contactList(_ vm: ContactListViewModel) -> some View {
        List {
            ForEach(vm.filteredContacts) { contact in
                ContactRow(contact: contact)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedContact = contact
                    }
            }
            .onDelete { offsets in
                vm.deleteContacts(at: offsets)
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            vm.loadContacts()
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

#Preview {
    ContactListView()
        .modelContainer(for: [Contact.self, Conversation.self, Message.self, UserProfile.self, EncryptionKeys.self])
}
