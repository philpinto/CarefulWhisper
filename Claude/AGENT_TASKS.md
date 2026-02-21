# CarefulWhisper - Agent Task Breakdown

## How to Use This Document

Each phase contains tasks designed to be:
1. **Self-contained**: All context needed is in the spec documents
2. **Testable**: Clear acceptance criteria define "done"
3. **Sequential within phase**: Tasks may have dependencies
4. **Validated at phase end**: Build + test gate before next phase

### Task Format
- **Task X.Y**: [Name]
- **Agent Type**: Plan | Explore | General-purpose | Bash
- **Dependencies**: Prerequisite tasks
- **Estimated Complexity**: Low | Medium | High
- **Description**: What needs to be done
- **Acceptance Criteria**: Specific, verifiable checkboxes
- **Files to Create/Modify**: Exact paths
- **Reference**: Spec section for implementation details

---

## Phase 1: Foundation & Data Models

**Goal**: Establish project structure and core SwiftData models that all other phases build upon.

### Task 1.1: Create Project Folder Structure
**Agent Type**: Bash
**Dependencies**: None
**Estimated Complexity**: Low

**Description**:
Create the folder structure for the CarefulWhisper project according to the organization defined in WORKFLOW.md. This establishes clear separation between Models, Views, ViewModels, Services, and Utilities.

**Implementation Requirements**:
1. Create all necessary folders in the Xcode project navigator
2. Ensure folders are groups (not file references)
3. Follow the structure defined in WORKFLOW.md File Organization section

**Folders to Create**:
- `CarefulWhisper/Models/`
- `CarefulWhisper/ViewModels/`
- `CarefulWhisper/Views/Onboarding/`
- `CarefulWhisper/Views/Contacts/`
- `CarefulWhisper/Views/Messages/`
- `CarefulWhisper/Views/Profile/`
- `CarefulWhisper/Views/Settings/`
- `CarefulWhisper/Services/`
- `CarefulWhisper/Utilities/`
- `CarefulWhisper/Utilities/Extensions/`
- `CarefulWhisper/Resources/` (if not exists)

**Acceptance Criteria**:
- [ ] All folders created in Xcode project navigator
- [ ] Folder structure matches WORKFLOW.md specification
- [ ] Project builds without errors
- [ ] No warnings introduced

**Reference**: WORKFLOW.md - File Organization

---

### Task 1.2: Define Core Data Models (Contact, Conversation, Message)
**Agent Type**: General-purpose
**Dependencies**: Task 1.1
**Estimated Complexity**: Medium

**Description**:
Create the three core SwiftData models: Contact, Conversation, and Message. These models form the foundation of the app's data layer and define relationships between users, their conversations, and messages.

**Implementation Requirements**:
1. Implement Contact model with all properties from TECHNICAL_SPEC.md
2. Implement Conversation model with support for one-to-one and group types
3. Implement Message model with encryption metadata
4. Define MessageStatus and ConversationType enums
5. Set up proper SwiftData relationships (cascade delete rules)
6. Add computed properties (e.g., publicKeyFingerprint, lastMessage)
7. Follow WORKFLOW.md coding standards (naming, access control, formatting)

**Files to Create**:
- `CarefulWhisper/Models/Contact.swift`
- `CarefulWhisper/Models/Conversation.swift`
- `CarefulWhisper/Models/Message.swift`
- `CarefulWhisper/Models/MessageStatus.swift`
- `CarefulWhisper/Models/ConversationType.swift`

**Acceptance Criteria**:
- [ ] Contact model includes: id, displayName, publicKey, peerId, dateAdded, lastSeen, isOnline, isPersistentConnection
- [ ] Contact has computed property: publicKeyFingerprint
- [ ] Contact has relationship to Conversations (cascade delete)
- [ ] Conversation model includes: id, type, createdAt, lastMessageAt, participants, messages, groupName, groupAdminIds
- [ ] Conversation has computed property: lastMessage
- [ ] Message model includes: id, content, timestamp, status, isFromMe, conversation, sender, encryptedPayload, signalMessageType
- [ ] MessageStatus enum: sending, sent, delivered, read, failed
- [ ] ConversationType enum: oneToOne, group
- [ ] All enums conform to Codable
- [ ] All models use @Model, @Attribute, @Relationship correctly
- [ ] Code compiles without errors
- [ ] No warnings

**Reference**: TECHNICAL_SPEC.md - Data Models section

---

### Task 1.3: Define Supporting Models (EncryptionKeys, UserProfile)
**Agent Type**: General-purpose
**Dependencies**: Task 1.1
**Estimated Complexity**: Low

**Description**:
Create supporting SwiftData models for encryption key management and user profile. These models handle the user's identity, encryption keys, and app settings.

**Implementation Requirements**:
1. Implement EncryptionKeys model for tracking key generation and rotation
2. Implement UserProfile model for user identity and settings
3. Add computed properties (shouldRotatePreKeys, qrCodeData)
4. Define SignalMessageType enum
5. Follow WORKFLOW.md coding standards

**Files to Create**:
- `CarefulWhisper/Models/EncryptionKeys.swift`
- `CarefulWhisper/Models/UserProfile.swift`
- `CarefulWhisper/Models/SignalMessageType.swift`

**Acceptance Criteria**:
- [ ] EncryptionKeys model includes: id, userId, identityKeyPairId, registrationId, preKeysGenerated, preKeysLastRotated
- [ ] EncryptionKeys has computed property: shouldRotatePreKeys (true if > 30 days since last rotation)
- [ ] UserProfile model includes: id, displayName, createdAt, publicKey, peerId, autoDeleteEnabled, autoDeleteDays
- [ ] UserProfile has computed property: qrCodeData (formatted URL string)
- [ ] SignalMessageType enum: preKey, normal
- [ ] All enums conform to Codable
- [ ] All models use @Model and @Attribute correctly
- [ ] Code compiles without errors
- [ ] No warnings

**Reference**: TECHNICAL_SPEC.md - Data Models section

---

### Task 1.4: Create DataService and ModelContainer Setup
**Agent Type**: General-purpose
**Dependencies**: Task 1.2, Task 1.3
**Estimated Complexity**: Medium

**Description**:
Set up the SwiftData ModelContainer in the app entry point and create a DataService to handle common data operations. This centralizes data access and provides a clean API for ViewModels to interact with SwiftData.

**Implementation Requirements**:
1. Configure ModelContainer in CarefulWhisperApp.swift
2. Create DataService with basic CRUD operations
3. Handle ModelContainer initialization errors gracefully
4. Add SwiftData container to app environment
5. Follow WORKFLOW.md SwiftData best practices

**Files to Create**:
- `CarefulWhisper/Services/DataService.swift`

**Files to Modify**:
- `CarefulWhisper/CarefulWhisperApp.swift`

**Acceptance Criteria**:
- [ ] ModelContainer created for all model types (Contact, Conversation, Message, EncryptionKeys, UserProfile)
- [ ] ModelContainer injected via .modelContainer() modifier
- [ ] DataService provides methods: fetchContacts(), fetchConversations(), saveContact(), deleteContact(), etc.
- [ ] DataService uses FetchDescriptor and #Predicate for queries
- [ ] Error handling for ModelContainer initialization (fatalError with descriptive message)
- [ ] Code follows WORKFLOW.md SwiftData best practices
- [ ] Code compiles without errors
- [ ] No warnings

**Reference**: WORKFLOW.md - SwiftData Best Practices

---

### Task 1.5: Create Utility Extensions (Data, String)
**Agent Type**: General-purpose
**Dependencies**: Task 1.1
**Estimated Complexity**: Low

**Description**:
Create utility extensions for Data and String types to support common operations like hex encoding, base64 encoding, SHA-256 hashing, and URL encoding. These utilities are used throughout the app for QR codes, fingerprints, and encryption.

**Implementation Requirements**:
1. Add Data extension with: sha256, hexString, base64EncodedString
2. Add String extension with: urlEncoded
3. Include documentation comments for public methods
4. Follow WORKFLOW.md coding standards

**Files to Create**:
- `CarefulWhisper/Utilities/Extensions/Data+Extensions.swift`
- `CarefulWhisper/Utilities/Extensions/String+Extensions.swift`

**Acceptance Criteria**:
- [ ] Data extension includes sha256 computed property (returns Data)
- [ ] Data extension includes hexString computed property (returns uppercase hex string)
- [ ] String extension includes urlEncoded computed property (percent-encodes for URLs)
- [ ] All methods have documentation comments
- [ ] Import CryptoKit in Data+Extensions for SHA-256
- [ ] Code compiles without errors
- [ ] No warnings

**Reference**: TECHNICAL_SPEC.md - Algorithms section (formatPublicKeyFingerprint, generateContactQRCode)

---

### Task 1.6: Write Unit Tests for Models
**Agent Type**: General-purpose
**Dependencies**: Task 1.2, Task 1.3, Task 1.5
**Estimated Complexity**: Medium

**Description**:
Write comprehensive unit tests for all SwiftData models and utility extensions. Tests verify initialization, computed properties, relationships, and data integrity.

**Implementation Requirements**:
1. Test Contact model initialization and computed properties
2. Test Conversation model relationships and lastMessage
3. Test Message model initialization
4. Test EncryptionKeys shouldRotatePreKeys logic
5. Test UserProfile qrCodeData formatting
6. Test Data and String extensions
7. Use Testing framework (not XCTest)
8. Follow WORKFLOW.md testing guidelines

**Files to Create**:
- `CarefulWhisperTests/Models/ContactTests.swift`
- `CarefulWhisperTests/Models/ConversationTests.swift`
- `CarefulWhisperTests/Models/MessageTests.swift`
- `CarefulWhisperTests/Models/EncryptionKeysTests.swift`
- `CarefulWhisperTests/Models/UserProfileTests.swift`
- `CarefulWhisperTests/Utilities/DataExtensionsTests.swift`
- `CarefulWhisperTests/Utilities/StringExtensionsTests.swift`

**Acceptance Criteria**:
- [ ] Contact tests: initialization, publicKeyFingerprint format
- [ ] Conversation tests: initialization, lastMessage computed property, participant relationships
- [ ] Message tests: initialization, default status is .sending
- [ ] EncryptionKeys tests: shouldRotatePreKeys (true after 30 days, false before)
- [ ] UserProfile tests: qrCodeData format matches expected URL scheme
- [ ] Data extension tests: sha256 produces 32-byte hash, hexString formats correctly
- [ ] String extension tests: urlEncoded handles special characters
- [ ] All tests use Testing framework (@Test, @Suite, #expect)
- [ ] All tests pass
- [ ] Code compiles without errors
- [ ] No warnings

**Reference**: WORKFLOW.md - Testing Guidelines

---

### Task 1.7: Phase 1 Validation
**Agent Type**: General-purpose
**Dependencies**: Task 1.1, Task 1.2, Task 1.3, Task 1.4, Task 1.5, Task 1.6
**Estimated Complexity**: Low

**Description**:
Validate that Phase 1 is complete and meets all exit criteria. Run all tests, verify build status, and update PROJECT_PLAN.md with completion status.

**Implementation Requirements**:
1. Run all unit tests and verify they pass
2. Build project and verify no errors or warnings
3. Check that all Task 1.X acceptance criteria are met
4. Update PROJECT_PLAN.md Phase 1 status to "Complete"
5. List all files created in PROJECT_PLAN.md Phase 1 section

**Files to Modify**:
- `Claude/PROJECT_PLAN.md`

**Acceptance Criteria**:
- [ ] All Phase 1 tasks (1.1-1.6) complete
- [ ] All unit tests pass (run via Xcode or xcodebuild)
- [ ] Project builds without errors
- [ ] No compiler warnings
- [ ] SwiftData models properly defined with relationships
- [ ] Sample data can be created and fetched (manual verification in tests)
- [ ] PROJECT_PLAN.md updated: Phase 1 status = "Complete", files created listed
- [ ] Ready to proceed to Phase 2 (Encryption Layer)

**Reference**: PROJECT_PLAN.md - Phase 1 Exit Criteria

---

## Phase 2: Encryption Layer

**Goal**: Integrate Signal Protocol for end-to-end encryption. Handle key generation, storage, and message encryption/decryption.

*Detailed tasks for Phase 2 will be added after Phase 1 completion. This allows us to adjust based on learnings from Phase 1 and finalize Signal Protocol library choice (libsignal-client vs SignalProtocolKit).*

**Placeholder Tasks**:
- 2.1: Integrate Signal Protocol library (Swift Package Manager)
- 2.2: Implement KeyManagementService (key generation, Keychain storage)
- 2.3: Implement EncryptionService (encrypt/decrypt messages)
- 2.4: Write unit tests for encryption roundtrip
- 2.5: Phase 2 validation

---

## Phase 3: P2P Networking

**Goal**: Implement fully decentralized peer-to-peer networking using libp2p for internet connectivity and Multipeer Connectivity for local network.

*Detailed tasks will be added after Phase 2 completion.*

**Placeholder Tasks**:
- 3.1: Evaluate and integrate libp2p (or WebRTC fallback)
- 3.2: Implement Multipeer Connectivity for local network
- 3.3: Create P2PNetworkService (connection management, message transport)
- 3.4: Implement offline message queue
- 3.5: Write integration tests for P2P message delivery
- 3.6: Phase 3 validation

---

## Phase 4-9: UI and Features

*Detailed tasks will be added as earlier phases complete. This iterative approach allows us to adapt based on technical discoveries and user feedback.*

---

## Notes

- **Task numbering**: Sequential within phase (1.1, 1.2, ... 2.1, 2.2, ...)
- **Dependencies**: Always listed explicitly (or "None")
- **Complexity estimates**: Guide for time/effort, not strict deadlines
- **Acceptance criteria**: Must ALL be checked before marking task complete
- **References**: Link to spec sections for implementation details
- **Validation tasks**: End every phase to ensure quality gates

---

*This document grows incrementally. Phase N+1 tasks defined after Phase N completes.*
