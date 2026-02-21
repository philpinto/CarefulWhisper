# Changelog

All notable changes to CarefulWhisper will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Relay server for internet messaging (when not on same network)
- watchOS companion app with quick replies
- Push notifications via APNs
- Group messaging support

---

## [1.0.1] - 2026-02-20

### Added
- Local notifications for incoming messages when app is in background
- Contact request notifications

### Changed
- Removed online/offline status indicators from UI

### Fixed
- Contact request handling when re-adding deleted contacts
- Conversation lookup by public key when peer ID changes
- Sheet presentation for contact request acceptance

---

## [1.0.0] - 2026-02-20

### Added

#### Phase 9: Polish & Settings
- Settings screen with privacy, storage, appearance, and about sections
- Auto-delete message configuration (Never, 7 days, 30 days, 90 days, 1 year)
- AutoDeleteService for automatic message cleanup
- BackgroundTaskService for scheduled cleanup operations
- Identity export for backup and verification
- Delete all data functionality with confirmation
- VoiceOver accessibility labels for messages and conversations
- App statistics (contacts, conversations, messages count)

#### Phase 7: Message Delivery & Status
- PresenceService for tracking contact online/offline status
- Read receipt sending when messages are viewed
- Delivery confirmation via P2P network
- Real-time status updates (sending, sent, delivered, read, failed)
- Contact online indicator in conversations

#### Phase 6: Core UI - Messaging
- ConversationListView with search and unread badges
- ChatView with message bubbles and real-time updates
- MessageBubbleView with iOS Messages-style design
- MessageInputView with send button
- Date section headers (Today, Yesterday, weekday, date)
- Message status icons (clock, checkmark, double checkmarks)
- Context menu on messages (copy, retry, delete)
- New conversation picker with contact selection
- Scroll to bottom on new message
- Empty state for no conversations

#### Phase 5: Core UI - Contacts
- ContactListView with search and online status
- ContactDetailView with fingerprint verification
- AddContactView with QR scanner and manual entry
- QRScannerView with camera permission handling
- Contact deletion with swipe actions
- Avatar with deterministic color from name hash

#### Phase 4: Core UI - Onboarding & Profile
- OnboardingView with welcome slides
- ProfileSetupView for display name entry
- ProfileView with QR code display
- QRCodeGenerator utility
- Tab-based navigation (Contacts, Messages, Profile, Settings)
- RootView with onboarding flow management

#### Phase 3: P2P Networking
- P2PNetworkService using Multipeer Connectivity
- MultipeerService for browser/advertiser management
- MessageTransportService coordinating encryption and transport
- MessageQueueService for offline message storage
- Delivery and read receipt handling
- Peer discovery and connection management
- Automatic reconnection on disconnect

#### Phase 2: Encryption Layer
- EncryptionService with CryptoKit integration
- X25519 key exchange (Curve25519)
- ChaCha20-Poly1305 authenticated encryption
- HKDF-SHA256 key derivation
- Ed25519 signatures for message authentication
- Ephemeral keys for forward secrecy
- KeyManagementService for key lifecycle
- SessionManager for encryption sessions
- KeychainHelper for secure key storage

#### Phase 1: Foundation & Data Models
- SwiftData models: Contact, Conversation, Message, UserProfile, EncryptionKeys
- MessageStatus enum (sending, sent, delivered, read, failed)
- ConversationType enum (oneToOne, group)
- PeerInfo for network peer representation
- Data extensions for SHA256 and hex encoding
- String extensions for URL encoding
- Project structure and architecture setup

### Technical Details
- iOS 18.0+ deployment target
- SwiftUI with @Observable for state management
- SwiftData for local persistence
- CryptoKit for all cryptographic operations
- Multipeer Connectivity for P2P networking
- MVVM architecture with services layer
- 70 unit tests covering core functionality

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.1 | 2026-02-20 | Local notifications, bug fixes |
| 1.0.0 | 2026-02-20 | Initial release with full messaging functionality |

---

## Migration Notes

### From Pre-1.0 to 1.0.0
This is the initial release. No migration required.

---

## Contributors

- Development assisted by Claude (Anthropic)
