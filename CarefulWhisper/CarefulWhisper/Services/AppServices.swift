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
    let autoDeleteService: AutoDeleteService
    let contactRequestService: ContactRequestService
    
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
        self.autoDeleteService = AutoDeleteService()
        self.contactRequestService = ContactRequestService()
    }
    
    // MARK: - Configuration
    
    /// Configure services with the model context
    func configure(with modelContext: ModelContext) {
        guard !isInitialized else { return }
        
        self.modelContext = modelContext
        messageTransportService.setModelContext(modelContext)
        messageTransportService.presenceService = presenceService
        messageTransportService.contactRequestService = contactRequestService
        presenceService.configure(modelContext: modelContext, p2pService: p2pNetworkService)
        autoDeleteService.configure(modelContext: modelContext)
        contactRequestService.configure(modelContext: modelContext, p2pService: p2pNetworkService)
        isInitialized = true
        
        // Perform auto-delete cleanup on app launch
        Task {
            await autoDeleteService.performCleanup()
        }
    }
    
    // MARK: - Network Lifecycle
    
    /// Start the P2P network with the user's profile
    func startNetwork(profile: UserProfile) async throws {
        print("[AppServices] startNetwork called - isInitialized: \(isInitialized), isNetworkRunning: \(isNetworkRunning)")
        guard isInitialized else {
            print("[AppServices] ERROR: Not initialized, cannot start network")
            return
        }
        guard !isNetworkRunning else {
            print("[AppServices] Network already running, skipping")
            return
        }
        
        print("[AppServices] Starting network for profile: \(profile.displayName)")
        try await messageTransportService.start(
            displayName: profile.displayName,
            publicKey: profile.publicKey
        )
        isNetworkRunning = true
        print("[AppServices] Network started successfully")
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
