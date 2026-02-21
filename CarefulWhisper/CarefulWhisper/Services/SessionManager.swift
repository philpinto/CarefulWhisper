import Foundation
import CryptoKit
import SwiftData

/// Manages encrypted sessions with contacts
/// Handles session state, message sequence numbers, and prepares for future Double Ratchet support
actor SessionManager {
    
    // MARK: - Types
    
    /// Represents an active session with a contact
    struct Session: Codable, Sendable {
        let contactId: UUID
        let contactPublicKey: Data
        let createdAt: Date
        var lastMessageAt: Date
        var messagesSent: UInt64
        var messagesReceived: UInt64
        var sessionKey: Data // Derived session key for this contact
    }
    
    /// Session state stored for persistence
    private struct SessionStore: Codable {
        var sessions: [UUID: Session]
    }
    
    // MARK: - Errors
    
    enum SessionError: Error {
        case sessionNotFound
        case sessionCreationFailed
        case invalidContactKey
        case storageFailed
    }
    
    // MARK: - Constants
    
    private enum StorageKeys {
        static let sessionsKey = "sessions.store"
    }
    
    // MARK: - Properties
    
    private var activeSessions: [UUID: Session] = [:]
    private let keyManagementService: KeyManagementService
    
    // MARK: - Singleton
    
    static let shared = SessionManager()
    
    // MARK: - Initialization
    
    init(keyManagementService: KeyManagementService = .shared) {
        self.keyManagementService = keyManagementService
    }
    
    // MARK: - Session Management
    
    /// Creates or retrieves a session for a contact
    /// - Parameters:
    ///   - contactId: The contact's unique identifier
    ///   - contactPublicKey: The contact's Curve25519 public key
    /// - Returns: The session for this contact
    func getOrCreateSession(for contactId: UUID, publicKey contactPublicKey: Data) async throws -> Session {
        // Return existing session if available
        if let existingSession = activeSessions[contactId] {
            return existingSession
        }
        
        // Create new session
        return try await createSession(for: contactId, publicKey: contactPublicKey)
    }
    
    /// Creates a new session for a contact
    private func createSession(for contactId: UUID, publicKey contactPublicKey: Data) async throws -> Session {
        // Validate contact's public key
        guard let _ = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: contactPublicKey) else {
            throw SessionError.invalidContactKey
        }
        
        // Derive a session key using our identity key and contact's public key
        let sharedSecret = try await keyManagementService.deriveSharedSecret(with: contactPublicKey)
        
        // Derive session-specific key
        var info = Data("CarefulWhisper-session-v1".utf8)
        info.append(contactId.uuidString.data(using: .utf8) ?? Data())
        
        let sessionKey = sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: Data(),
            sharedInfo: info,
            outputByteCount: 32
        )
        
        // Extract raw key data
        let sessionKeyData = sessionKey.withUnsafeBytes { Data($0) }
        
        let session = Session(
            contactId: contactId,
            contactPublicKey: contactPublicKey,
            createdAt: Date(),
            lastMessageAt: Date(),
            messagesSent: 0,
            messagesReceived: 0,
            sessionKey: sessionKeyData
        )
        
        activeSessions[contactId] = session
        try saveSessionsToDisk()
        
        return session
    }
    
    /// Retrieves an existing session
    func getSession(for contactId: UUID) -> Session? {
        activeSessions[contactId]
    }
    
    /// Checks if a session exists for a contact
    func hasSession(for contactId: UUID) -> Bool {
        activeSessions[contactId] != nil
    }
    
    /// Updates session after sending a message
    func recordMessageSent(for contactId: UUID) async throws {
        guard var session = activeSessions[contactId] else {
            throw SessionError.sessionNotFound
        }
        
        session.messagesSent += 1
        session.lastMessageAt = Date()
        activeSessions[contactId] = session
        try saveSessionsToDisk()
    }
    
    /// Updates session after receiving a message
    func recordMessageReceived(for contactId: UUID) async throws {
        guard var session = activeSessions[contactId] else {
            throw SessionError.sessionNotFound
        }
        
        session.messagesReceived += 1
        session.lastMessageAt = Date()
        activeSessions[contactId] = session
        try saveSessionsToDisk()
    }
    
    /// Deletes a session (e.g., when removing a contact)
    func deleteSession(for contactId: UUID) throws {
        activeSessions.removeValue(forKey: contactId)
        try saveSessionsToDisk()
    }
    
    /// Deletes all sessions
    func deleteAllSessions() throws {
        activeSessions.removeAll()
        try saveSessionsToDisk()
    }
    
    // MARK: - Session Statistics
    
    /// Returns total number of active sessions
    var activeSessionCount: Int {
        activeSessions.count
    }
    
    /// Returns all active contact IDs
    var activeContactIds: [UUID] {
        Array(activeSessions.keys)
    }
    
    /// Returns session statistics for a contact
    func getSessionStats(for contactId: UUID) -> (sent: UInt64, received: UInt64)? {
        guard let session = activeSessions[contactId] else {
            return nil
        }
        return (session.messagesSent, session.messagesReceived)
    }
    
    // MARK: - Persistence
    
    /// Saves sessions to disk using Keychain for security
    private func saveSessionsToDisk() throws {
        let store = SessionStore(sessions: activeSessions)
        
        do {
            let data = try JSONEncoder().encode(store)
            try KeychainHelper.save(
                data,
                account: StorageKeys.sessionsKey,
                accessibility: .afterFirstUnlockThisDeviceOnly
            )
        } catch {
            throw SessionError.storageFailed
        }
    }
    
    /// Loads sessions from disk
    func loadSessionsFromDisk() {
        do {
            let data = try KeychainHelper.load(account: StorageKeys.sessionsKey)
            let store = try JSONDecoder().decode(SessionStore.self, from: data)
            activeSessions = store.sessions
        } catch {
            // No existing sessions or load failed - start fresh
            activeSessions = [:]
        }
    }
    
    // MARK: - Session Refresh
    
    /// Refreshes a session key (for security rotation)
    func refreshSession(for contactId: UUID) async throws -> Session {
        guard let existingSession = activeSessions[contactId] else {
            throw SessionError.sessionNotFound
        }
        
        // Create new session with fresh key derivation
        activeSessions.removeValue(forKey: contactId)
        return try await createSession(for: contactId, publicKey: existingSession.contactPublicKey)
    }
    
    /// Checks if a session should be refreshed (e.g., after X messages or time)
    func shouldRefreshSession(for contactId: UUID, messageThreshold: UInt64 = 1000, dayThreshold: Int = 7) -> Bool {
        guard let session = activeSessions[contactId] else {
            return false
        }
        
        // Refresh if too many messages
        if session.messagesSent + session.messagesReceived > messageThreshold {
            return true
        }
        
        // Refresh if too old
        let daysSinceCreation = Calendar.current.dateComponents(
            [.day],
            from: session.createdAt,
            to: Date()
        ).day ?? 0
        
        return daysSinceCreation >= dayThreshold
    }
}
