import Foundation
import BackgroundTasks
import SwiftData

/// Service for managing background tasks like auto-delete cleanup
final class BackgroundTaskService {
    // MARK: - Constants
    
    static let autoDeleteTaskIdentifier = "com.carefulwhisper.autodelete"
    
    // MARK: - Properties
    
    private var modelContainer: ModelContainer?
    
    // MARK: - Singleton
    
    static let shared = BackgroundTaskService()
    
    private init() { }
    
    // MARK: - Configuration
    
    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Task Registration
    
    /// Register all background tasks with the system
    /// Call this in AppDelegate or App init
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.autoDeleteTaskIdentifier,
            using: nil
        ) { task in
            self.handleAutoDeleteTask(task as! BGProcessingTask)
        }
    }
    
    // MARK: - Task Scheduling
    
    /// Schedule the auto-delete background task
    func scheduleAutoDeleteTask() {
        let request = BGProcessingTaskRequest(identifier: Self.autoDeleteTaskIdentifier)
        
        // Run at least 1 hour from now, preferably during low activity
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule auto-delete task: \(error)")
        }
    }
    
    /// Cancel scheduled auto-delete task
    func cancelAutoDeleteTask() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.autoDeleteTaskIdentifier)
    }
    
    // MARK: - Task Handling
    
    @MainActor
    private func handleAutoDeleteTask(_ task: BGProcessingTask) {
        // Schedule the next occurrence
        scheduleAutoDeleteTask()
        
        // Create a task to perform the cleanup
        let cleanupTask = Task {
            guard let container = modelContainer else {
                task.setTaskCompleted(success: false)
                return
            }
            
            let autoDeleteService = AutoDeleteService()
            autoDeleteService.configure(modelContext: container.mainContext)
            
            let deletedCount = await autoDeleteService.performCleanup()
            
            if deletedCount > 0 {
                print("Auto-delete cleanup: removed \(deletedCount) messages")
            }
            
            task.setTaskCompleted(success: true)
        }
        
        // Handle task expiration
        task.expirationHandler = {
            cleanupTask.cancel()
            task.setTaskCompleted(success: false)
        }
    }
    
    // MARK: - Manual Cleanup
    
    /// Perform cleanup immediately (for app launch or foreground)
    @MainActor
    func performImmediateCleanup() async {
        guard let container = modelContainer else { return }
        
        let autoDeleteService = AutoDeleteService()
        autoDeleteService.configure(modelContext: container.mainContext)
        
        let deletedCount = await autoDeleteService.performCleanup()
        
        if deletedCount > 0 {
            print("Immediate cleanup: removed \(deletedCount) messages")
        }
    }
}
