# CarefulWhisper - Development Workflow

## Code Style & Conventions

### Swift Code Style

**Naming Conventions**:
- **Types** (classes, structs, enums, protocols): PascalCase
  - Examples: `Contact`, `MessageStatus`, `EncryptionService`
- **Properties, methods, variables**: camelCase
  - Examples: `displayName`, `sendMessage()`, `isOnline`
- **Constants**: camelCase (not SCREAMING_SNAKE_CASE)
  - Examples: `maxFileSize`, `defaultTimeout`
- **Enums**: PascalCase for type, camelCase for cases
  ```swift
  enum MessageStatus {
      case sending
      case sent
      case delivered
  }
  ```

**Property Wrappers**:
- Use `@State private var` for SwiftUI local state
- Use `@Binding var` for passed-in state
- Use `@Observable` for ViewModels (not `@ObservableObject`)
- Use `@Model` for SwiftData models
- Use `@Relationship` for SwiftData relationships

**Formatting**:
- **Indentation**: 4 spaces (no tabs)
- **Line length**: 120 characters max (soft limit, can exceed for readability)
- **Braces**: Opening brace on same line
  ```swift
  func sendMessage() {
      // code
  }
  ```
- **Spacing**: One blank line between methods, two between types

**Imports**:
- Group imports: Foundation first, then Apple frameworks, then third-party, then local
- Alphabetize within groups
- Remove unused imports
  ```swift
  import Foundation
  import SwiftUI
  import SwiftData

  import CryptoKit

  import SignalProtocolKit
  ```

**Access Control**:
- Default to `private` for properties and methods
- Use `fileprivate` sparingly (usually indicates refactoring needed)
- Mark public APIs explicitly as `public` or `internal`
- ViewModels: properties should be `private` or `private(set)` unless bindable

**Optionals**:
- Avoid force-unwrapping (`!`) unless you have explicit justification (document why)
- Prefer optional chaining (`?.`) and nil coalescing (`??`)
- Use `guard let` for early returns
- Use `if let` for conditional logic
  ```swift
  // Good
  guard let contact = fetchContact(id) else { return }

  // Bad
  let contact = fetchContact(id)!
  ```

**Error Handling**:
- Use `throws` for recoverable errors
- Use `Result<Success, Failure>` for async operations that can fail
- Define custom error enums for domain-specific errors
- Never use `try!` (use `do-catch` or `try?`)
  ```swift
  enum EncryptionError: Error {
      case sessionNotFound
      case invalidCiphertext
      case keyGenerationFailed
  }
  ```

---

## Architecture Patterns

### MVVM with @Observable

**Structure**:
```
Views/ (SwiftUI)
    ├─> ViewModels/ (@Observable, business logic)
            ├─> Services/ (networking, encryption, data)
                    └─> Models/ (SwiftData, domain types)
```

**View**:
- Pure SwiftUI
- No business logic (just presentation logic)
- Calls ViewModel methods for actions
- Observes ViewModel state for updates
  ```swift
  struct ChatView: View {
      @State private var viewModel: ChatViewModel

      var body: some View {
          // UI only
      }
  }
  ```

**ViewModel**:
- Marked with `@Observable`
- Contains business logic and UI state
- Calls Services for data/network operations
- Exposes computed properties and methods for View
- No SwiftUI imports (except for convenience like `@Published` if needed)
  ```swift
  @Observable
  class ChatViewModel {
      private let encryptionService: EncryptionService
      private let networkService: P2PNetworkService

      var messages: [Message] = []
      var isConnected: Bool = false

      func sendMessage(_ content: String) {
          // Business logic
      }
  }
  ```

**Service**:
- Single responsibility (EncryptionService, P2PNetworkService, DataService)
- Injected into ViewModels (dependency injection)
- No SwiftUI dependencies
- Fully testable
  ```swift
  class EncryptionService {
      func encrypt(_ plaintext: String, for recipientId: UUID) throws -> Data {
          // Encryption logic
      }
  }
  ```

---

## File Organization

### Project Structure

```
CarefulWhisper/
├── App/
│   └── CarefulWhisperApp.swift (App entry point)
├── Models/
│   ├── Contact.swift
│   ├── Conversation.swift
│   ├── Message.swift
│   ├── EncryptionKeys.swift
│   └── UserProfile.swift
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── ProfileViewModel.swift
│   ├── ContactListViewModel.swift
│   ├── ChatViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingView.swift
│   │   └── ProfileSetupView.swift
│   ├── Contacts/
│   │   ├── ContactListView.swift
│   │   ├── AddContactView.swift
│   │   └── QRScannerView.swift
│   ├── Messages/
│   │   ├── ConversationListView.swift
│   │   ├── ChatView.swift
│   │   └── MessageBubbleView.swift
│   ├── Profile/
│   │   ├── ProfileView.swift
│   │   └── QRCodeView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Services/
│   ├── EncryptionService.swift
│   ├── P2PNetworkService.swift
│   ├── DataService.swift
│   ├── KeyManagementService.swift
│   └── MessageTransportService.swift
├── Utilities/
│   ├── QRCodeGenerator.swift
│   ├── KeychainHelper.swift
│   └── Extensions/
│       ├── Data+Extensions.swift
│       └── String+Extensions.swift
└── Resources/
    └── Assets.xcassets

CarefulWhisperTests/
├── Models/
├── Services/
└── ViewModels/

Claude/
├── PROJECT_PLAN.md
├── TECHNICAL_SPEC.md
├── WORKFLOW.md
└── AGENT_TASKS.md
```

---

## SwiftData Best Practices

### Model Definition
- Use `@Model` macro
- Use `@Attribute(.unique)` for unique identifiers
- Use `@Relationship(deleteRule: .cascade/.nullify)` for relationships
- Initialize all non-optional properties in `init`
  ```swift
  @Model
  class Contact {
      @Attribute(.unique) var id: UUID
      var displayName: String
      @Relationship(deleteRule: .cascade) var conversations: [Conversation]

      init(displayName: String) {
          self.id = UUID()
          self.displayName = displayName
      }
  }
  ```

### ModelContainer Setup
- Create in App entry point
- Share across views via `.modelContainer(for:)` modifier
  ```swift
  @main
  struct CarefulWhisperApp: App {
      let modelContainer: ModelContainer

      init() {
          do {
              modelContainer = try ModelContainer(for: Contact.self, Conversation.self, Message.self)
          } catch {
              fatalError("Failed to create ModelContainer: \(error)")
          }
      }

      var body: some Scene {
          WindowGroup {
              ContentView()
                  .modelContainer(modelContainer)
          }
      }
  }
  ```

### Querying Data
- Use `@Query` in Views for automatic updates
- Use `FetchDescriptor` for custom queries
- Use `#Predicate` for filtering
  ```swift
  // In View
  @Query(sort: \Contact.displayName) var contacts: [Contact]

  // In ViewModel/Service
  let descriptor = FetchDescriptor<Message>(
      predicate: #Predicate { message in
          message.conversation?.id == conversationId
      },
      sortBy: [SortDescriptor(\.timestamp, order: .forward)]
  )
  let messages = try modelContext.fetch(descriptor)
  ```

---

## SwiftUI Best Practices

### View Composition
- Break large views into small, reusable components
- Each component should have a single responsibility
- Prefer custom views over view builders for reusability
  ```swift
  // Good: Reusable component
  struct MessageBubbleView: View {
      let message: Message
      var body: some View { /* ... */ }
  }

  // Use in parent
  ForEach(messages) { message in
      MessageBubbleView(message: message)
  }
  ```

### State Management
- `@State` for local view state
- `@Binding` for passed-in state
- ViewModels for complex state and business logic
- Avoid `@EnvironmentObject` (prefer explicit dependency injection)

### Preview Providers
- Always include previews for every view
- Use sample data for realistic previews
- Test both light and dark mode
  ```swift
  #Preview("Light Mode") {
      ChatView(viewModel: ChatViewModel.preview)
  }

  #Preview("Dark Mode") {
      ChatView(viewModel: ChatViewModel.preview)
          .preferredColorScheme(.dark)
  }
  ```

---

## Security Best Practices

### Keychain Usage
- Store all private keys in Keychain
- Use `kSecAttrAccessibleAfterFirstUnlock` for encryption keys
- Never log or print private keys
  ```swift
  // Good
  KeychainHelper.save(privateKey, key: "identity-private-key", accessibility: .afterFirstUnlock)

  // Bad
  print("Private key: \(privateKey)") // NEVER DO THIS
  ```

### Secure Coding
- Validate all inputs (especially from QR codes, network)
- Use type-safe parsing (no force-casts)
- Clear sensitive data from memory when done
- Never store plaintext messages or keys in UserDefaults or files
  ```swift
  // Good: Validate QR code data
  guard let contact = try? parseContactQRCode(scannedData) else {
      throw QRCodeError.invalidFormat
  }

  // Bad: Assume format is correct
  let contact = parseContactQRCode(scannedData)! // UNSAFE
  ```

---

## Testing Guidelines

### Unit Tests
- Test models: initialization, computed properties, relationships
- Test services: business logic, error handling, edge cases
- Test ViewModels: actions, state changes
- Mock external dependencies (network, encryption)

**Test Structure**:
```swift
import Testing
@testable import CarefulWhisper

@Suite("Contact Tests")
struct ContactTests {
    @Test("Contact initialization sets properties correctly")
    func testContactInit() {
        let contact = Contact(displayName: "Alice", publicKey: Data(), peerId: "peer123")
        #expect(contact.displayName == "Alice")
        #expect(contact.peerId == "peer123")
    }

    @Test("Public key fingerprint formats correctly")
    func testPublicKeyFingerprint() {
        let publicKey = Data(repeating: 0xAB, count: 32)
        let contact = Contact(displayName: "Alice", publicKey: publicKey, peerId: "peer123")
        let fingerprint = contact.publicKeyFingerprint
        #expect(fingerprint.hasPrefix("AB"))
    }
}
```

### What NOT to Test
- SwiftUI view rendering (use Previews instead)
- Framework internals (trust SwiftData, CryptoKit, Signal Protocol)
- UI interactions (use UI tests sparingly)

---

## Git Workflow

### Commit Messages
- Use present tense ("Add feature" not "Added feature")
- First line: concise summary (50 chars max)
- Optional body: explain "why" not "what"
- Reference phase/task if applicable
  ```
  Add Contact model with SwiftData support

  Implements Phase 1, Task 1.1. Contact includes display name,
  public key, peer ID, and relationship to conversations.
  ```

### Branch Strategy
- `main`: stable, shippable code
- `phase-N/feature-name`: feature branches for each phase
- Merge to main only when phase is complete and all tests pass

### Commit Frequency
- Commit at meaningful boundaries (feature complete, task complete)
- Don't commit broken code
- Run tests before committing

---

## Performance Guidelines

### General
- Profile before optimizing (use Instruments)
- Optimize for correctness first, performance second
- Target: 60fps scrolling, < 100ms message send latency

### SwiftUI Performance
- Use `Identifiable` for list items (avoid `.id()` modifier)
- Lazy load large lists (`LazyVStack`, `LazyHStack`)
- Paginate message history (50 messages at a time)
- Avoid expensive operations in `body` (move to ViewModel)

### Networking Performance
- Batch operations (e.g., delivery confirmations every 5s)
- Reuse connections (persistent for top contacts)
- Implement backoff for retries (exponential)

### Memory Management
- Clear caches on memory warnings
- Use `weak` for delegates
- Avoid retain cycles in closures (`[weak self]`)

---

## Accessibility

### Requirements
- Support VoiceOver for all UI elements
- Support Dynamic Type (text scales with user preference)
- Minimum touch target size: 44x44 points
- Sufficient color contrast (WCAG AA)

### Implementation
- Use semantic labels for images and buttons
  ```swift
  Image(systemName: "paperplane.fill")
      .accessibilityLabel("Send message")
  ```
- Group related elements
  ```swift
  HStack {
      Text(message.content)
      Text(message.timestamp)
  }
  .accessibilityElement(children: .combine)
  ```
- Test with VoiceOver enabled (Xcode Accessibility Inspector)

---

## Code Review Checklist

Before marking any task complete:

- [ ] Code compiles without errors or warnings
- [ ] All unit tests pass
- [ ] No force-unwraps or force-casts (without justification)
- [ ] No TODOs left unresolved (within scope of task)
- [ ] No commented-out code
- [ ] No sensitive data logged or printed
- [ ] Code follows naming conventions
- [ ] Access control properly specified (private by default)
- [ ] Error handling implemented (throws or Result)
- [ ] SwiftUI previews included for views
- [ ] Documentation comments for public APIs

---

*This workflow evolves with the project. Update as new patterns emerge.*
