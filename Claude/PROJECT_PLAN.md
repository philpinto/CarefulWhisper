# CarefulWhisper - Project Plan

## Overview
CarefulWhisper is a fully decentralized, peer-to-peer encrypted messaging app for iOS and watchOS. Messages are stored only on user devices with zero server-side data storage. Built for privacy-conscious users, technical experts, journalists, activists, and anyone handling sensitive communications.

## Quick Links
| Document | Purpose |
|----------|---------|
| `TECHNICAL_SPEC.md` | Complete technical specifications for encryption, P2P networking, and data models |
| `AGENT_TASKS.md` | Granular task breakdown for execution |
| `WORKFLOW.md` | Development workflow and coding standards |

## Target Platform
- **iOS**: 18.0+
- **watchOS**: 11.0+ (companion app)
- **Architecture**: Universal Binary (ARM64 + Intel for Simulator)
- **Key Frameworks**: SwiftUI, SwiftData, CryptoKit, libp2p, Signal Protocol (libsignal-client)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                        │
│  (Contacts, Messages, Chat, Profile, Settings)          │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                  View Models                            │
│  (@Observable, business logic, UI state)                │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│                   Services Layer                        │
│  ┌──────────────┬──────────────┬──────────────────────┐ │
│  │ Encryption   │ P2P Network  │ Storage Service      │ │
│  │ Service      │ Service      │ (SwiftData)          │ │
│  └──────────────┴──────────────┴──────────────────────┘ │
└─────────────────┬───────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────┐
│              Core Frameworks                            │
│  Signal Protocol │ libp2p │ SwiftData │ CryptoKit       │
└─────────────────────────────────────────────────────────┘
```

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Architecture Pattern** | MVVM with @Observable | Modern SwiftUI pattern, clear separation of concerns, testable |
| **Encryption** | Signal Protocol | Battle-tested (WhatsApp, Signal), perfect forward secrecy, handles offline messaging |
| **P2P Networking** | libp2p + Multipeer Connectivity | Fully decentralized DHT, no servers, local + internet hybrid |
| **Data Persistence** | SwiftData | Modern, Swift-native, iOS 18+ optimized |
| **Identity Model** | Public key as unique ID, username as display name | Cryptographically secure, changeable display names |
| **UI Framework** | SwiftUI | Native iOS, declarative, rapid development |
| **Message Queue** | Local queue with background delivery | Offline support, reliable delivery without servers |

## Phase Summary

| Phase | Name | Tasks | Key Deliverable | Status |
|-------|------|-------|-----------------|--------|
| 1 | Foundation & Data Models | 1.1-1.7 | SwiftData models, project structure | Complete |
| 2 | Encryption Layer | 2.1-2.6 | CryptoKit encryption, key management | Complete |
| 3 | P2P Networking | 3.1-3.6 | Multipeer Connectivity, message transport, offline queue | Complete |
| 4 | Core UI - Onboarding & Profile | 4.1-4.6 | First-run experience, profile setup, QR codes, tab navigation | Complete |
| 5 | Core UI - Contacts | 5.1-5.5 | Contact list, add contact, QR scanning, contact detail | Complete |
| 6 | Core UI - Messaging | 6.1-6.6 | Conversation list, chat view, message sending | Complete |
| 7 | Message Delivery & Status | 7.1-7.4 | Delivery confirmation, read receipts, online status | Pending |
| 8 | watchOS Companion | 8.1-8.4 | Watch UI, notifications, quick replies | Pending |
| 9 | Polish & Settings | 9.1-9.5 | Auto-delete settings, dark mode, accessibility | Pending |

## Phase Details

### Phase 1: Foundation & Data Models
**Status**: Complete ✓

Establish the project structure and core data models using SwiftData. This phase creates the foundation that all other phases build upon.

**Exit Criteria**:
- [x] SwiftData models defined: Contact, Conversation, Message, EncryptionKeys, UserProfile
- [x] Model relationships properly configured
- [x] Unit tests for model initialization and relationships (27 tests passing)
- [x] Project builds without warnings

**Files Created**:
- `Models/Contact.swift`
- `Models/Conversation.swift`
- `Models/Message.swift`
- `Models/EncryptionKeys.swift`
- `Models/UserProfile.swift`
- `Models/MessageStatus.swift` (enum)
- `Models/ConversationType.swift` (enum)
- `Models/SignalMessageType.swift` (enum)
- `Services/DataService.swift`
- `Utilities/Extensions/Data+Extensions.swift`
- `Utilities/Extensions/String+Extensions.swift`
- Tests: `ContactTests.swift`, `ConversationTests.swift`, `MessageTests.swift`, `EncryptionKeysTests.swift`, `UserProfileTests.swift`, `DataExtensionsTests.swift`, `StringExtensionsTests.swift`

**Notes**:
- All 27 unit tests passing
- Project structure organized with Models/, ViewModels/, Views/, Services/, Utilities/ folders
- ModelContainer configured in CarefulWhisperApp.swift

---

### Phase 2: Encryption Layer
**Status**: Complete ✓

End-to-end encryption using Apple CryptoKit with Signal Protocol-compatible algorithms (X25519 key agreement, ChaCha20-Poly1305 encryption, HKDF key derivation).

**Exit Criteria**:
- [x] Curve25519 key pair generation (X25519 for key agreement, Ed25519 for signing)
- [x] Secure key storage in iOS Keychain
- [x] Message encryption with ephemeral keys (forward secrecy)
- [x] Message decryption and verification
- [x] Session management for contacts
- [x] Unit tests for all encryption operations (13 tests passing)
- [x] Project builds without warnings

**Files Created**:
- `Utilities/KeychainHelper.swift` - Secure Keychain storage wrapper
- `Services/KeyManagementService.swift` - Key generation, storage, derivation
- `Services/EncryptionService.swift` - Message encryption/decryption
- `Services/SessionManager.swift` - Contact session management
- Tests: `EncryptionTests.swift`

**Technical Notes**:
- Uses CryptoKit instead of libsignal (no CocoaPods dependency)
- X25519 Diffie-Hellman key agreement (same as Signal Protocol)
- ChaCha20-Poly1305 authenticated encryption (same as Signal Protocol)
- HKDF-SHA256 for key derivation
- Ephemeral keys per message provide forward secrecy
- Future: Can integrate full Signal Protocol with Double Ratchet when needed

---

### Phase 3: P2P Networking
**Status**: Complete ✓

Peer-to-peer networking using Multipeer Connectivity for local network discovery and messaging. Abstraction layer prepared for future libp2p internet connectivity.

**Exit Criteria**:
- [x] Multipeer Connectivity for local network
- [x] Peer discovery and connection management
- [x] Encrypted transport layer (uses existing encryption service)
- [x] Offline message queue with exponential backoff retry
- [x] Message transport service coordinating encryption + P2P
- [x] Unit tests for P2P models and queue (21 new tests, 61 total passing)
- [x] Project builds without warnings
- [ ] libp2p integrated for internet DHT (deferred - swift-libp2p not production-ready)
- [ ] Connection persistence for frequent contacts (deferred to Phase 7)

**Files Created**:
- `Models/PeerInfo.swift` - PeerInfo, P2PMessageEnvelope, QueuedMessage structs
- `Services/MultipeerService.swift` - Apple Multipeer Connectivity wrapper
- `Services/P2PNetworkService.swift` - Unified P2P abstraction layer
- `Services/MessageQueueService.swift` - Offline queue with persistence
- `Services/MessageTransportService.swift` - Encryption + P2P coordinator
- Tests: `PeerInfoTests.swift`, `MessageQueueTests.swift`

**Technical Notes**:
- swift-libp2p is experimental (v0.3.0, "not production-ready") - deferred for now
- Multipeer Connectivity handles local network P2P effectively
- P2PNetworkService abstraction allows adding libp2p transport later
- MessageQueueService persists to Documents/message_queue.json
- Exponential backoff: 1s, 2s, 4s... up to 60s max, 10 retries max

---

### Phase 4: Core UI - Onboarding & Profile
**Status**: Complete ✓

First-run experience with profile setup and QR code sharing. Tab-based navigation for the main app.

**Exit Criteria**:
- [x] Onboarding flow (first launch detection via UserProfile query)
- [x] Profile setup screen (username/display name entry)
- [x] Automatic key generation during setup
- [x] Profile screen with QR code display
- [x] QR code generation from user's public key
- [x] UI matches iOS design guidelines
- [x] Dark mode support (uses system colors)
- [x] Project builds without warnings
- [x] All 61 tests pass

**Files Created**:
- `Views/Onboarding/OnboardingView.swift` - Welcome screen with feature highlights
- `Views/Onboarding/ProfileSetupView.swift` - Display name entry
- `Views/Profile/ProfileView.swift` - Profile info with QR code and fingerprint
- `Views/RootView.swift` - Onboarding/main app router
- `Views/MainTabView.swift` - Tab navigation (Contacts, Messages, Profile)
- `ViewModels/OnboardingViewModel.swift` - Profile creation and first-run detection
- `ViewModels/ProfileViewModel.swift` - Profile data management
- `Utilities/QRCodeGenerator.swift` - QR code generation + QRCodeView

**Technical Notes**:
- Uses @Query to detect existing UserProfile for first-run check
- QR code encodes: carefulwhisper://contact?name=X&key=Y&peer=Z
- Fingerprint is SHA256 of public key formatted as spaced hex groups
- Copy fingerprint to clipboard with visual toast feedback

---

### Phase 5: Core UI - Contacts
**Status**: Complete ✓

Contact management with QR code scanning and manual entry support.

**Exit Criteria**:
- [x] Contact list view with search and swipe-to-delete
- [x] Add contact button → modal with QR scan + manual entry tabs
- [x] QR code scanner (AVFoundation, camera permission handling)
- [x] Manual ID entry (paste contact URL)
- [x] Contact detail view with avatar, info, fingerprint
- [x] Delete contact with confirmation dialog
- [x] Empty state with ContentUnavailableView
- [x] Unit tests for QR parser (9 new tests, 70 total passing)
- [x] Project builds without warnings

**Files Created**:
- `Views/Contacts/ContactListView.swift` - List with search, swipe delete
- `Views/Contacts/AddContactView.swift` - Segmented QR/Manual tabs
- `Views/Contacts/QRScannerView.swift` - AVFoundation camera scanner
- `Views/Contacts/ContactDetailView.swift` - Full contact details + actions
- `ViewModels/ContactListViewModel.swift` - CRUD operations, search
- `Utilities/ContactQRParserTests.swift` - QR URL parsing tests

**Technical Notes**:
- ContactQRParser extracts name, publicKey, peerId from carefulwhisper:// URLs
- Avatars use deterministic color from name hash
- QR scanner uses AVCaptureMetadataOutput for QR detection
- Camera permission gracefully handled with Settings redirect

---

### Phase 6: Core UI - Messaging
**Status**: Complete ✓

Build the core messaging experience: conversation list, chat view, send/receive messages.

**Exit Criteria**:
- [x] Conversation list view (iOS Messages style)
- [x] Chat view with message bubbles (sent/received styling)
- [x] Text input and send button
- [x] Message sending triggers encryption + P2P transport
- [x] Incoming messages displayed in real-time
- [x] Scroll to bottom on new message
- [x] Empty state for no conversations
- [x] Timestamp display with date section headers
- [x] Project builds without warnings
- [x] All 70 tests pass

**Files Created**:
- `Views/Conversations/ConversationListView.swift` - List with search, unread badges, online status
- `Views/Conversations/ChatView.swift` - Full chat interface with messages and input
- `Views/Conversations/MessageBubbleView.swift` - Sent/received bubble styling with status icons
- `Views/Conversations/MessageInputView.swift` - Text field with send button
- `Views/Conversations/ContactInfoFromChatView.swift` - Contact info accessible from chat
- `ViewModels/ConversationListViewModel.swift` - Conversation CRUD, search, formatting
- `ViewModels/ChatViewModel.swift` - Message sending, receiving, status updates
- `Services/AppServices.swift` - Central service container with environment injection

**Technical Notes**:
- AppServices injected via SwiftUI environment for easy access to MessageTransportService
- BubbleShape custom Shape for iOS Messages-style bubbles with tails
- Message status icons: clock (sending), checkmark (sent), blue checkmark (delivered), double blue checkmarks (read), red exclamation (failed)
- Date section headers group messages by Today/Yesterday/Weekday/Date
- Context menu on messages: copy, retry (if failed), delete
- New conversation picker filters contacts, shows online status

---

### Phase 7: Message Delivery & Status
**Status**: Pending

Implement message status indicators: sent, delivered, read receipts, online/offline status.

**Exit Criteria**:
- [ ] Message status enum: sending, sent, delivered, read, failed
- [ ] Status indicators in chat bubbles (checkmarks, etc.)
- [ ] Delivery confirmation sent back to sender
- [ ] Read receipt mechanism (mark message as read when viewed)
- [ ] Online/offline status detection
- [ ] Status displayed in contact list and chat header
- [ ] Retry mechanism for failed messages
- [ ] Project builds without warnings

**Files to Create**:
- `Views/Messages/MessageStatusView.swift`
- `Services/MessageStatusService.swift`
- `Services/PresenceService.swift`

---

### Phase 8: watchOS Companion
**Status**: Pending

Build the Apple Watch companion app for viewing recent messages, quick replies, and notifications.

**Exit Criteria**:
- [ ] watchOS target created and configured
- [ ] Recent messages list view
- [ ] Message detail view (read-only)
- [ ] Quick reply UI (predefined responses)
- [ ] Voice dictation for message replies
- [ ] Push notifications for new messages
- [ ] Shared SwiftData container between iOS and watchOS
- [ ] Watch app builds and runs on simulator/device
- [ ] Project builds without warnings

**Files to Create**:
- `CarefulWhisperWatch/Views/MessageListView.swift`
- `CarefulWhisperWatch/Views/MessageDetailView.swift`
- `CarefulWhisperWatch/Views/QuickReplyView.swift`
- `CarefulWhisperWatch/CarefulWhisperWatchApp.swift`

---

### Phase 9: Polish & Settings
**Status**: Pending

Final polish: settings, auto-delete configuration, accessibility improvements, performance optimization.

**Exit Criteria**:
- [ ] Settings screen with all options
- [ ] Auto-delete configuration (never, 7 days, 30 days, 90 days, custom)
- [ ] Auto-delete background task implementation
- [ ] Dark mode fully tested
- [ ] VoiceOver support tested
- [ ] Dynamic Type support verified
- [ ] Performance optimization (message list scrolling, large conversations)
- [ ] App icon and branding finalized
- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] Project builds without warnings

**Files to Create**:
- `Views/Settings/SettingsView.swift`
- `Views/Settings/AutoDeleteSettingsView.swift`
- `ViewModels/SettingsViewModel.swift`
- `Services/AutoDeleteService.swift`
- `Services/BackgroundTaskService.swift`

---

## Testing Strategy

### What to Test

| Layer | Test Focus | Priority |
|-------|------------|----------|
| **Models** | Initialization, relationships, encoding/decoding, computed properties | High |
| **Encryption** | Encrypt/decrypt roundtrip, key generation, key storage/retrieval | Critical |
| **P2P Networking** | Connection establishment, message transport, peer discovery | High |
| **Services** | Business logic, state transitions, error handling | High |
| **ViewModels** | Data transformations, actions, computed properties | Medium |
| **UI** | User flows (onboarding, add contact, send message) | Medium |

### What NOT to Unit Test
- SwiftUI view rendering (use Previews instead)
- External library internals (trust Signal Protocol, libp2p)
- Framework behavior (trust SwiftData, CryptoKit)

### Test File Organization
```
CarefulWhisperTests/
├── Models/
│   ├── ContactTests.swift
│   ├── ConversationTests.swift
│   └── MessageTests.swift
├── Services/
│   ├── EncryptionServiceTests.swift
│   ├── P2PNetworkServiceTests.swift
│   └── DataServiceTests.swift
└── ViewModels/
    ├── ChatViewModelTests.swift
    └── ContactListViewModelTests.swift
```

### Performance Targets
- Message list scroll: 60fps with 1000+ messages
- Message send latency: < 100ms (encryption + network send)
- App launch time: < 2 seconds cold start
- Memory footprint: < 100MB with 10 active conversations

---

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| **libp2p complexity / limited Swift support** | Evaluate Swift bindings early (Phase 3). Fallback: use WebRTC + minimal signaling server if libp2p unusable |
| **Signal Protocol integration difficulty** | Use well-maintained library (libsignal-client or SignalProtocolKit). Extensive testing in Phase 2 |
| **NAT traversal failures** | Implement multiple transport options (Multipeer for local, STUN/TURN fallback for internet) |
| **Offline message delivery unreliable** | Implement persistent message queue with retry logic and exponential backoff |
| **Battery drain from persistent connections** | Limit persistent connections to top contacts, use iOS background tasks efficiently |
| **SwiftData sync issues between iOS/watchOS** | Test shared container early, implement conflict resolution |
| **User confusion about P2P concept** | Clear onboarding explaining how it works, visual indicators for connection status |

---

## Future Phases (Post-MVP)

### Phase 10: Group Messaging
- Invite-only groups (creator adds members via QR/ID)
- Signal Protocol Sender Keys for group encryption
- Group admin controls (add/remove members, promote admins)
- Group profile and settings

### Phase 11: Media Attachments
- Photo/video attachments (encrypted transfer)
- Document sharing (PDF, etc.)
- Voice messages
- 100MB file size limit
- Chunked transfer for large files

---

## Success Criteria

The project is complete and ready for release when:

1. **Core functionality works**:
   - Users can add contacts via QR code or manual ID
   - Users can send and receive encrypted messages in real-time
   - Message delivery status works (sent, delivered, read)
   - Messages stored locally with no server dependency

2. **Platform support complete**:
   - iOS app fully functional
   - watchOS companion app working (view, reply, notifications)

3. **Security verified**:
   - All messages encrypted end-to-end with Signal Protocol
   - Keys stored securely in Keychain
   - No data transmitted to or stored on servers
   - Security audit passes (or peer review by security experts)

4. **Quality standards met**:
   - All unit tests pass
   - All UI tests pass
   - No compiler warnings
   - Performance targets met (60fps scrolling, < 100ms send latency)
   - Dark mode works throughout
   - Accessibility tested with VoiceOver

5. **User experience polished**:
   - Onboarding clear and simple
   - UI matches iOS design guidelines
   - Error states handled gracefully
   - App doesn't crash under normal usage

6. **Ready for distribution**:
   - App Store submission materials ready
   - Privacy policy reflects true P2P architecture
   - TestFlight beta tested by real users
   - Critical bugs resolved

---

## Known Limitations

- Each device is independent (no cross-device sync for a single user)
- No cloud backup (by design—messages only on device)
- Group messaging and media attachments deferred to post-MVP
- Depends on at least one peer being online for delivery (no relay servers)

---

## Changelog

### 2026-02-20 - Project Initialized
- Discovery phase completed
- Project plan created
- 9 phases defined (Foundation → Polish)
- Technical stack decided: Signal Protocol, libp2p, SwiftData, SwiftUI
