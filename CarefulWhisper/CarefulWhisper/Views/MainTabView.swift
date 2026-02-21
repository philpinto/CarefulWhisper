import SwiftUI
import SwiftData

/// Main tab-based navigation for the app
struct MainTabView: View {
    @State private var selectedTab: Tab = .messages
    
    enum Tab: Hashable {
        case contacts
        case messages
        case profile
        case settings
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Contacts tab
            ContactListView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
                .tag(Tab.contacts)
            
            // Messages tab
            ConversationListView()
                .tabItem {
                    Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
                }
                .tag(Tab.messages)
            
            // Profile tab
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(Tab.profile)
            
            // Settings tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}

/// Placeholder for Contacts view (Phase 5)
struct ContactsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("Contacts")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Your contacts will appear here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Add contact action (Phase 5)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

/// Placeholder for Messages view (Phase 6)
struct MessagesPlaceholderView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)
                
                Text("No Messages Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start a conversation by adding a contact")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Messages")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [UserProfile.self, Contact.self, Conversation.self, Message.self, EncryptionKeys.self])
}
