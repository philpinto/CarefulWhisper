import SwiftUI
import SwiftData

/// Root view that handles navigation between onboarding and main app
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appServices) private var appServices
    @Query private var profiles: [UserProfile]
    @State private var onboardingViewModel: OnboardingViewModel?
    
    private var hasCompletedOnboarding: Bool {
        !profiles.isEmpty
    }
    
    private var currentProfile: UserProfile? {
        profiles.first
    }
    
    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else if let vm = onboardingViewModel {
                if vm.isOnboardingComplete {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            } else {
                // Loading state while we check for existing profile
                ProgressView()
                    .onAppear {
                        onboardingViewModel = OnboardingViewModel(modelContext: modelContext)
                    }
            }
        }
        .animation(.easeInOut, value: hasCompletedOnboarding)
        .task {
            // Start P2P network when user is logged in
            if let profile = currentProfile {
                try? await appServices?.startNetwork(profile: profile)
            }
        }
    }
}

#Preview("New User") {
    RootView()
        .modelContainer(for: [UserProfile.self, Contact.self, Conversation.self, Message.self, EncryptionKeys.self])
}

#Preview("Existing User") {
    let container = try! ModelContainer(for: UserProfile.self, Contact.self, Conversation.self, Message.self, EncryptionKeys.self)
    
    // Create a sample profile
    let profile = UserProfile(
        displayName: "Alice",
        publicKey: Data(repeating: 0xAB, count: 32),
        peerId: "peer123"
    )
    container.mainContext.insert(profile)
    
    return RootView()
        .modelContainer(container)
}
