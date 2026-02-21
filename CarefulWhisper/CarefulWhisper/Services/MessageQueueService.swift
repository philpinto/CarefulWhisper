import Foundation

/// Service for managing offline message queue with persistent storage
/// Messages are queued when recipient is offline and retried with exponential backoff
actor MessageQueueService {
    // MARK: - Properties
    
    private var queue: [UUID: QueuedMessage] = [:]
    private var isRunning = false
    private var processingTask: Task<Void, Never>?
    
    private let persistenceURL: URL
    
    private var onMessageReady: (@Sendable (P2PMessageEnvelope) -> Void)?
    
    var queuedCount: Int {
        queue.count
    }
    
    func setOnMessageReady(_ handler: @escaping @Sendable (P2PMessageEnvelope) -> Void) {
        onMessageReady = handler
    }
    
    // MARK: - Initialization
    
    init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        persistenceURL = documentsPath.appendingPathComponent("message_queue.json")
    }
    
    // MARK: - Lifecycle
    
    func start() async {
        guard !isRunning else { return }
        isRunning = true
        
        // Load persisted queue
        await loadQueue()
        
        // Start background processing
        processingTask = Task {
            await processLoop()
        }
    }
    
    func stop() {
        isRunning = false
        processingTask?.cancel()
        processingTask = nil
        
        // Persist current queue
        Task {
            await saveQueue()
        }
    }
    
    // MARK: - Queue Operations
    
    func enqueue(_ envelope: P2PMessageEnvelope) {
        let queuedMessage = QueuedMessage(envelope: envelope)
        queue[envelope.id] = queuedMessage
        
        Task {
            await saveQueue()
        }
    }
    
    func markDelivered(_ messageId: UUID) {
        queue.removeValue(forKey: messageId)
        
        Task {
            await saveQueue()
        }
    }
    
    func getQueuedMessages(for recipientId: String) -> [QueuedMessage] {
        queue.values.filter { $0.envelope.recipientId == recipientId }
    }
    
    func processQueue(for recipientId: String) {
        let messages = getQueuedMessages(for: recipientId)
        for message in messages {
            onMessageReady?(message.envelope)
        }
    }
    
    // MARK: - Background Processing
    
    private func processLoop() async {
        while isRunning && !Task.isCancelled {
            // Check for messages ready to retry
            let now = Date()
            
            for (id, var message) in queue {
                guard message.shouldRetry else {
                    // Max retries exceeded, remove from queue
                    queue.removeValue(forKey: id)
                    continue
                }
                
                // Check if enough time has passed since last retry
                let timeSinceLastRetry: TimeInterval
                if let lastRetry = message.lastRetryAt {
                    timeSinceLastRetry = now.timeIntervalSince(lastRetry)
                } else {
                    timeSinceLastRetry = now.timeIntervalSince(message.createdAt)
                }
                
                if timeSinceLastRetry >= message.retryDelay {
                    // Time to retry
                    message.retryCount += 1
                    message.lastRetryAt = now
                    queue[id] = message
                    
                    // Notify that message is ready for sending
                    onMessageReady?(message.envelope)
                }
            }
            
            // Save queue periodically
            await saveQueue()
            
            // Sleep for a bit before next check
            try? await Task.sleep(for: .seconds(5))
        }
    }
    
    // MARK: - Persistence
    
    private func loadQueue() async {
        guard FileManager.default.fileExists(atPath: persistenceURL.path) else {
            return
        }
        
        do {
            let data = try Data(contentsOf: persistenceURL)
            let decoder = JSONDecoder()
            let messages = try decoder.decode([QueuedMessage].self, from: data)
            
            queue = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        } catch {
            print("Failed to load message queue: \(error)")
        }
    }
    
    private func saveQueue() async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(Array(queue.values))
            try data.write(to: persistenceURL, options: .atomic)
        } catch {
            print("Failed to save message queue: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    func clearOldMessages(olderThan days: Int = 7) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        queue = queue.filter { $0.value.createdAt > cutoffDate }
        
        Task {
            await saveQueue()
        }
    }
}
