import Foundation
import SwiftData
import Observation

/// Auto-delete time period options
enum AutoDeletePeriod: Int, CaseIterable, Identifiable {
    case never = 0
    case sevenDays = 7
    case thirtyDays = 30
    case ninetyDays = 90
    case oneYear = 365
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .never: return "Never"
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        case .ninetyDays: return "90 Days"
        case .oneYear: return "1 Year"
        }
    }
    
    var description: String {
        switch self {
        case .never: return "Messages will never be automatically deleted"
        case .sevenDays: return "Messages older than 7 days will be deleted"
        case .thirtyDays: return "Messages older than 30 days will be deleted"
        case .ninetyDays: return "Messages older than 90 days will be deleted"
        case .oneYear: return "Messages older than 1 year will be deleted"
        }
    }
    
    static func from(days: Int?) -> AutoDeletePeriod {
        guard let days = days else { return .never }
        return AutoDeletePeriod(rawValue: days) ?? .never
    }
}

/// ViewModel for app settings
@Observable
@MainActor
final class SettingsViewModel {
    // MARK: - Properties
    
    private var modelContext: ModelContext
    private var userProfile: UserProfile?
    
    // Auto-delete settings
    var autoDeleteEnabled: Bool = false {
        didSet {
            saveAutoDeleteSettings()
        }
    }
    
    var selectedAutoDeletePeriod: AutoDeletePeriod = .never {
        didSet {
            saveAutoDeleteSettings()
        }
    }
    
    // App info
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // Statistics
    var totalContacts: Int = 0
    var totalConversations: Int = 0
    var totalMessages: Int = 0
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserProfile()
        loadStatistics()
    }
    
    // MARK: - Data Loading
    
    private func loadUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        
        if let profile = try? modelContext.fetch(descriptor).first {
            self.userProfile = profile
            self.autoDeleteEnabled = profile.autoDeleteEnabled
            self.selectedAutoDeletePeriod = AutoDeletePeriod.from(days: profile.autoDeleteDays)
        }
    }
    
    private func loadStatistics() {
        // Count contacts
        let contactDescriptor = FetchDescriptor<Contact>()
        totalContacts = (try? modelContext.fetchCount(contactDescriptor)) ?? 0
        
        // Count conversations
        let conversationDescriptor = FetchDescriptor<Conversation>()
        totalConversations = (try? modelContext.fetchCount(conversationDescriptor)) ?? 0
        
        // Count messages
        let messageDescriptor = FetchDescriptor<Message>()
        totalMessages = (try? modelContext.fetchCount(messageDescriptor)) ?? 0
    }
    
    // MARK: - Settings Management
    
    private func saveAutoDeleteSettings() {
        guard let profile = userProfile else { return }
        
        profile.autoDeleteEnabled = autoDeleteEnabled
        profile.autoDeleteDays = autoDeleteEnabled ? selectedAutoDeletePeriod.rawValue : nil
        
        try? modelContext.save()
    }
    
    /// Delete all messages and conversations
    func deleteAllData() {
        // Delete all messages
        let messageDescriptor = FetchDescriptor<Message>()
        if let messages = try? modelContext.fetch(messageDescriptor) {
            for message in messages {
                modelContext.delete(message)
            }
        }
        
        // Delete all conversations
        let conversationDescriptor = FetchDescriptor<Conversation>()
        if let conversations = try? modelContext.fetch(conversationDescriptor) {
            for conversation in conversations {
                modelContext.delete(conversation)
            }
        }
        
        // Delete all contacts
        let contactDescriptor = FetchDescriptor<Contact>()
        if let contacts = try? modelContext.fetch(contactDescriptor) {
            for contact in contacts {
                modelContext.delete(contact)
            }
        }
        
        try? modelContext.save()
        loadStatistics()
    }
    
    /// Export user's public key and peer ID for backup
    func exportIdentity() -> String {
        guard let profile = userProfile else { return "" }
        
        let exportData: [String: String] = [
            "displayName": profile.displayName,
            "publicKey": profile.publicKey.base64EncodedString(),
            "peerId": profile.peerId,
            "exportDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return ""
    }
    
    /// Refresh statistics
    func refreshStatistics() {
        loadStatistics()
    }
}
