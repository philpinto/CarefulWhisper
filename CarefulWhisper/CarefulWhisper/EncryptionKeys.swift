import Foundation
import SwiftData

@Model
class EncryptionKeys {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var identityKeyPairId: String
    var registrationId: UInt32
    var preKeysGenerated: Date
    var preKeysLastRotated: Date?
    
    init(userId: UUID, identityKeyPairId: String, registrationId: UInt32) {
        self.id = UUID()
        self.userId = userId
        self.identityKeyPairId = identityKeyPairId
        self.registrationId = registrationId
        self.preKeysGenerated = Date()
    }
    
    var shouldRotatePreKeys: Bool {
        guard let lastRotated = preKeysLastRotated else { return true }
        let thirtyDaysInSeconds: TimeInterval = 30 * 24 * 60 * 60
        return Date().timeIntervalSince(lastRotated) > thirtyDaysInSeconds
    }
}
