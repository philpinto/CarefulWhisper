import SwiftUI
import SwiftData

/// Chat view displaying conversation messages with input
struct ChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var appServices
    @State private var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    let conversation: Conversation
    
    init(conversation: Conversation) {
        self.conversation = conversation
        self._viewModel = State(initialValue: ChatViewModel(conversation: conversation))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            messageList
            
            Divider()
            
            MessageInputView(
                text: $viewModel.messageText,
                isSending: viewModel.isSending,
                canSend: viewModel.canSend,
                isFocused: $isInputFocused
            ) {
                Task {
                    await viewModel.sendMessage()
                }
            }
        }
        .navigationTitle(viewModel.recipientName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(viewModel.recipientName)
                        .font(.headline)
                    
                    if viewModel.isRecipientOnline {
                        Text("Online")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                if let contact = viewModel.recipient {
                    NavigationLink {
                        ContactInfoFromChatView(contact: contact)
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            }
        }
        .onAppear {
            viewModel.configure(
                modelContext: modelContext,
                transportService: appServices?.messageTransportService
            )
            viewModel.markMessagesAsRead()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
    
    // MARK: - Message List
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.groupedMessages(), id: \.date) { group in
                        Section {
                            ForEach(group.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    timeString: viewModel.formatMessageTime(message.timestamp)
                                )
                                .id(message.id)
                                .contextMenu {
                                    messageContextMenu(for: message)
                                }
                            }
                        } header: {
                            dateSectionHeader(viewModel.formatSectionDate(group.date))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.sortedMessages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                if let lastMessage = viewModel.sortedMessages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Section Header
    
    private func dateSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color(.systemBackground).opacity(0.9))
            .clipShape(Capsule())
            .padding(.vertical, 8)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func messageContextMenu(for message: Message) -> some View {
        Button {
            UIPasteboard.general.string = message.content
        } label: {
            Label("Copy", systemImage: "doc.on.doc")
        }
        
        if message.isFromMe && message.status == .failed {
            Button {
                Task {
                    await viewModel.retryMessage(message)
                }
            } label: {
                Label("Retry", systemImage: "arrow.clockwise")
            }
        }
        
        Button(role: .destructive) {
            viewModel.deleteMessage(message)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

#Preview {
    NavigationStack {
        ChatView(conversation: Conversation(type: .oneToOne))
    }
    .modelContainer(for: [Conversation.self, Contact.self, Message.self])
}
