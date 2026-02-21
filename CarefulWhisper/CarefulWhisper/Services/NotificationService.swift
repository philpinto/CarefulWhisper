import Foundation
import UserNotifications
import UIKit

/// Service for managing local notifications
@MainActor
final class NotificationService: NSObject {
    static let shared = NotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private(set) var isAuthorized = false
    
    override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Authorization
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("[Notifications] Authorization error: \(error)")
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }
    
    // MARK: - Sending Notifications
    
    /// Show notification for a new message (only when app is in background)
    func showMessageNotification(from senderName: String, messagePreview: String, conversationId: UUID) async {
        guard isAuthorized else { return }
        guard UIApplication.shared.applicationState != .active else { return }
        
        let content = UNMutableNotificationContent()
        content.title = senderName
        content.body = messagePreview
        content.sound = .default
        content.threadIdentifier = conversationId.uuidString
        content.userInfo = ["conversationId": conversationId.uuidString]
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to show message notification: \(error)")
        }
    }
    
    /// Show notification for a contact request
    func showContactRequestNotification(from senderName: String) async {
        guard isAuthorized else { return }
        guard UIApplication.shared.applicationState != .active else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Contact Request"
        content.body = "\(senderName) wants to connect"
        content.sound = .default
        content.categoryIdentifier = "CONTACT_REQUEST"
        
        let request = UNNotificationRequest(
            identifier: "contact-request-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to show contact request notification: \(error)")
        }
    }
    
    // MARK: - Badge Management
    
    /// Update app badge with unread count
    func updateBadge(count: Int) async {
        guard isAuthorized else { return }
        await MainActor.run {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
    
    /// Clear notifications for a specific conversation
    func clearNotifications(for conversationId: UUID) {
        notificationCenter.getDeliveredNotifications { notifications in
            let idsToRemove = notifications
                .filter { $0.request.content.threadIdentifier == conversationId.uuidString }
                .map { $0.request.identifier }
            
            self.notificationCenter.removeDeliveredNotifications(withIdentifiers: idsToRemove)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground (don't show it)
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Don't show notifications when app is active
        return []
    }
    
    /// Handle notification tap
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        
        if let conversationIdString = userInfo["conversationId"] as? String,
           let _ = UUID(uuidString: conversationIdString) {
            // Post notification to navigate to conversation
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .openConversation,
                    object: nil,
                    userInfo: userInfo
                )
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openConversation = Notification.Name("openConversation")
}
