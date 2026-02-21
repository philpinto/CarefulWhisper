import SwiftUI
import SwiftData

/// Profile setup screen for entering display name
struct ProfileSetupView: View {
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Create Your Profile")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Choose a display name that your contacts will see")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Name input
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Name")
                    .font(.headline)
                
                TextField("Enter your name", text: $viewModel.displayName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
                    .autocorrectionDisabled()
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if viewModel.canProceed {
                            createProfile()
                        }
                    }
                
                Text("This can be changed later in settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            
            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Info about what happens next
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                
                Text("Your encryption keys will be generated automatically")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            
            // Continue button
            Button {
                createProfile()
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Continue")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.canProceed ? Color.blue : Color.gray)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canProceed)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(viewModel.isLoading)
        .onAppear {
            isNameFieldFocused = true
        }
    }
    
    private func createProfile() {
        Task {
            await viewModel.createProfile()
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSetupView(viewModel: OnboardingViewModel(
            modelContext: try! ModelContainer(for: UserProfile.self).mainContext
        ))
    }
}
