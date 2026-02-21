import Foundation
import SwiftData
import Observation

/// Manages onboarding state and user profile creation
@Observable
@MainActor
final class OnboardingViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let keyManagementService: KeyManagementService
    
    var displayName: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var isOnboardingComplete: Bool = false
    
    // MARK: - Computed Properties
    
    var canProceed: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    var trimmedDisplayName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, keyManagementService: KeyManagementService = .shared) {
        self.modelContext = modelContext
        self.keyManagementService = keyManagementService
        
        // Check if user profile already exists
        checkExistingProfile()
    }
    
    // MARK: - Public Methods
    
    /// Creates the user profile with generated encryption keys
    func createProfile() async {
        guard canProceed else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Generate identity keys
            let keyPair = try await keyManagementService.generateAndStoreIdentityKeys()
            
            // Generate peer ID from public key
            let peerId = keyPair.publicKeyData.sha256.hexString
            
            // Create user profile
            let profile = UserProfile(
                displayName: trimmedDisplayName,
                publicKey: keyPair.publicKeyData,
                peerId: peerId
            )
            
            // Save to SwiftData
            modelContext.insert(profile)
            try modelContext.save()
            
            isOnboardingComplete = true
            
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func checkExistingProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        
        if let profiles = try? modelContext.fetch(descriptor), !profiles.isEmpty {
            isOnboardingComplete = true
        }
    }
}
