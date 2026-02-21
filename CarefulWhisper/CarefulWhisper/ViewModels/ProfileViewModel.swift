import Foundation
import SwiftData
import Observation

/// Manages user profile display and editing
@Observable
@MainActor
final class ProfileViewModel {
    // MARK: - Properties
    
    private let modelContext: ModelContext
    
    var userProfile: UserProfile?
    var isLoading: Bool = false
    var errorMessage: String?
    
    // MARK: - Computed Properties
    
    var displayName: String {
        userProfile?.displayName ?? "Unknown"
    }
    
    var publicKeyFingerprint: String {
        guard let profile = userProfile else { return "" }
        return formatFingerprint(profile.publicKey.sha256.hexString)
    }
    
    var peerId: String {
        userProfile?.peerId ?? ""
    }
    
    var qrCodeData: String {
        userProfile?.qrCodeData ?? ""
    }
    
    var profileCreatedAt: Date {
        userProfile?.createdAt ?? Date()
    }
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadProfile()
    }
    
    // MARK: - Public Methods
    
    func loadProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        
        if let profiles = try? modelContext.fetch(descriptor) {
            userProfile = profiles.first
        }
    }
    
    func updateDisplayName(_ newName: String) {
        guard let profile = userProfile else { return }
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        profile.displayName = trimmedName
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update name: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    private func formatFingerprint(_ hex: String) -> String {
        // Format as groups of 4 characters separated by spaces
        var result = ""
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 4, limitedBy: hex.endIndex) ?? hex.endIndex
            if !result.isEmpty {
                result += " "
            }
            result += String(hex[index..<nextIndex])
            index = nextIndex
        }
        
        return result.uppercased()
    }
}
