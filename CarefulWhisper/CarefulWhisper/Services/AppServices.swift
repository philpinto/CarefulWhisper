import Foundation
import SwiftUI
import SwiftData
import Observation

/// Central service container that manages app-wide services
/// Injected via SwiftUI environment for easy access in views
@Observable
@MainActor
final class AppServices {
    // MARK: - Services
    
    let encryptionService: EncryptionService
    let p2pNetworkService: P2PNetworkService
    let messageTransportService: MessageTransportService
    let presenceService: PresenceService
    
    // MARK: - State
    
    private(set) var isInitialized = false
    private(set) var isNetworkRunning = false
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {
        // Initialize services
        self.encryptionService = EncryptionService()
        self.p2pNetworkService = P2PNetworkService()
        self.messageTransportService = MessageTransportService(
            encryptionService: encryptionService,
            p2pService: p2pNetworkService
        )
        self.presenceService = PresenceService()
    }
    
    // MARK: - Configuration
    
    /// Configure services with the model context
    func configure(with modelContext: ModelContext) {
        guard !isInitialized else { return }
        
        self.modelContext = modelContext
        messageTransportService.setModelContext(modelContext)
        presenceService.configure(modelContext: modelContext, p2pService: p2pNetworkService)
        isInitialized = true
    }
    
    // MARK: - Network Lifecycle
    
    /// Start the P2P network with the user's profile
    func startNetwork(profile: UserProfile) async throws {
        guard isInitialized, !isNetworkRunning else { return }
        
        try await messageTransportService.start(
            displayName: profile.displayName,
            publicKey: profile.publicKey
        )
        isNetworkRunning = true
    }
    
    /// Stop the P2P network
    func stopNetwork() async {
        guard isNetworkRunning else { return }
        
        await messageTransportService.stop()
        isNetworkRunning = false
    }
}

// MARK: - Environment Key

private struct AppServicesKey: EnvironmentKey {
    static let defaultValue: AppServices? = nil
}

extension EnvironmentValues {
    var appServices: AppServices? {
        get { self[AppServicesKey.self] }
        set { self[AppServicesKey.self] = newValue }
    }
}
