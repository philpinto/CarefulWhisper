import SwiftUI
import SwiftData

/// Welcome screen shown on first launch
struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: OnboardingViewModel?
    @State private var showProfileSetup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                // App icon/logo area
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("CarefulWhisper")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Private. Secure. Decentralized.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                // Feature highlights
                VStack(alignment: .leading, spacing: 20) {
                    FeatureRow(
                        icon: "lock.shield.fill",
                        title: "End-to-End Encrypted",
                        description: "Your messages are encrypted so only you and your contacts can read them"
                    )
                    
                    FeatureRow(
                        icon: "network",
                        title: "Peer-to-Peer",
                        description: "Messages travel directly between devices with no servers in between"
                    )
                    
                    FeatureRow(
                        icon: "iphone.gen3",
                        title: "Local Storage Only",
                        description: "Your conversations stay on your device, never uploaded anywhere"
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Get started button
                Button {
                    showProfileSetup = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $showProfileSetup) {
                if let vm = viewModel {
                    ProfileSetupView(viewModel: vm)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = OnboardingViewModel(modelContext: modelContext)
            }
        }
    }
}

/// Individual feature row for onboarding
private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(for: [UserProfile.self, Contact.self, Conversation.self, Message.self, EncryptionKeys.self])
}
