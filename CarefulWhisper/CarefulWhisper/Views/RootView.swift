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
        .onChange(of: currentProfile) { oldProfile, newProfile in
            // Start network when profile becomes available
            if let profile = newProfile, oldProfile == nil {
                print("[RootView] Profile loaded: \(profile.displayName), starting network...")
                Task {
                    do {
                        try await appServices?.startNetwork(profile: profile)
                        print("[RootView] Network started successfully")
                    } catch {
                        print("[RootView] ERROR: Failed to start network: \(error)")
                    }
                }
            }
        }
        .task {
            // Also try on initial load in case query is already populated
            print("[RootView] Task starting, profile: \(currentProfile?.displayName ?? "nil")")
            if let profile = currentProfile {
                do {
                    try await appServices?.startNetwork(profile: profile)
                    print("[RootView] Network started successfully")
                } catch {
                    print("[RootView] ERROR: Failed to start network: \(error)")
                }
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
