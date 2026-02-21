import SwiftUI
import SwiftData

/// Main conversation list view (Messages-style)
struct ConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ConversationListViewModel()
    @State private var showingNewConversation = false
    @State private var selectedConversation: Conversation?
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if viewModel.filteredConversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
            .navigationTitle("Messages")
            .searchable(text: $viewModel.searchText, prompt: "Search conversations")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewConversation = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewConversation) {
                NewConversationView { contact in
                    if let conversation = viewModel.getOrCreateConversation(with: contact) {
                        selectedConversation = conversation
                    }
                    showingNewConversation = false
                }
            }
            .navigationDestination(item: $selectedConversation) { conversation in
                ChatView(conversation: conversation)
            }
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Conversations", systemImage: "bubble.left.and.bubble.right")
        } description: {
            Text("Start a new conversation by tapping the compose button.")
        } actions: {
            Button("New Conversation") {
                showingNewConversation = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var conversationList: some View {
        List {
            ForEach(viewModel.filteredConversations) { conversation in
                ConversationRowView(
                    conversation: conversation,
                    displayName: viewModel.displayName(for: conversation),
                    lastMessage: viewModel.lastMessagePreview(for: conversation),
                    time: viewModel.formattedTime(for: conversation),
                    unreadCount: viewModel.unreadCount(for: conversation),
                    isOnline: conversation.participants.first?.isOnline ?? false
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedConversation = conversation
                }
            }
            .onDelete(perform: viewModel.deleteConversations)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.loadConversations()
        }
    }
}

// MARK: - Conversation Row View

struct ConversationRowView: View {
    let conversation: Conversation
    let displayName: String
    let lastMessage: String
    let time: String
    let unreadCount: Int
    let isOnline: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with online indicator
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(String(displayName.prefix(1)).uppercased())
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                    }
                
                if isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay {
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        }
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(displayName)
                        .font(.headline)
                        .fontWeight(unreadCount > 0 ? .bold : .semibold)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fontWeight(unreadCount > 0 ? .medium : .regular)
                    
                    Spacer()
                    
                    if unreadCount > 0 {
                        Text("\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    private var accessibilityDescription: String {
        var description = "Conversation with \(displayName)"
        if isOnline {
            description += ", online"
        }
        if unreadCount > 0 {
            description += ", \(unreadCount) unread message\(unreadCount == 1 ? "" : "s")"
        }
        description += ". Last message: \(lastMessage), \(time)"
        return description
    }
}

// MARK: - New Conversation View

struct NewConversationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Contact.displayName) private var contacts: [Contact]
    @State private var searchText = ""
    
    let onSelectContact: (Contact) -> Void
    
    var filteredContacts: [Contact] {
        guard !searchText.isEmpty else { return contacts }
        return contacts.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if contacts.isEmpty {
                    ContentUnavailableView {
                        Label("No Contacts", systemImage: "person.crop.circle.badge.plus")
                    } description: {
                        Text("Add contacts first to start a conversation.")
                    }
                } else if filteredContacts.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredContacts) { contact in
                        Button {
                            onSelectContact(contact)
                        } label: {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 40, height: 40)
                                    .overlay {
                                        Text(String(contact.displayName.prefix(1)).uppercased())
                                            .font(.headline)
                                    }
                                
                                VStack(alignment: .leading) {
                                    Text(contact.displayName)
                                        .font(.body)
                                        .foregroundStyle(.primary)
                                    
                                    if contact.isOnline {
                                        Text("Online")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                    }
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Conversation")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search contacts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ConversationListView()
        .modelContainer(for: [Conversation.self, Contact.self, Message.self])
}
