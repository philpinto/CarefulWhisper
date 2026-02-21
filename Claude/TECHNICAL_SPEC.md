# CarefulWhisper - Technical Specification

## Table of Contents
1. [Domain Knowledge](#domain-knowledge)
2. [Encryption Architecture](#encryption-architecture)
3. [P2P Networking Architecture](#p2p-networking-architecture)
4. [Data Models](#data-models)
5. [Message Flow](#message-flow)
6. [Security Considerations](#security-considerations)
7. [Algorithms](#algorithms)

---

## Domain Knowledge

### End-to-End Encryption (E2EE)
Messages are encrypted on the sender's device and only decrypted on the recipient's device. No intermediary (including servers, if they existed) can read message content.

### Perfect Forward Secrecy (PFS)
Even if an attacker obtains a device's long-term private key, they cannot decrypt past messages. Each message uses ephemeral keys that are deleted after use.

### Peer-to-Peer (P2P)
Direct communication between devices without central servers. Devices discover each other via DHT (Distributed Hash Table) and connect directly.

### Signal Protocol
The gold-standard encryption protocol used by Signal, WhatsApp, and Facebook Messenger. Provides E2EE, PFS, and asynchronous messaging (send messages even when recipient is offline).

### libp2p
Modular networking stack for P2P applications. Used by IPFS, Filecoin, and Ethereum 2.0. Provides:
- Peer discovery via DHT (Kademlia)
- NAT traversal (hole punching, relay fallback)
- Multiple transport protocols (TCP, QUIC, WebSocket)
- Encrypted channels (Noise protocol)
- Multiplexing and stream management

### Multipeer Connectivity
Apple's framework for discovering and connecting devices on the same local network via WiFi or Bluetooth. No internet required.

---

## Encryption Architecture

### Signal Protocol Components

#### 1. Identity Keys (Long-term)
- **Generation**: Ed25519 key pair generated on first app launch
- **Storage**: Private key in iOS Keychain (kSecAttrAccessibleAfterFirstUnlock)
- **Usage**: Sign pre-keys, verify identity
- **Lifetime**: Permanent (unless user deletes app data)

#### 2. Pre-Keys (Medium-term)
- **Generation**: Set of 100 signed pre-keys, rotated monthly
- **Storage**: SwiftData (public) + Keychain (private)
- **Usage**: Establish sessions with offline users
- **Lifetime**: 30 days, then rotated

#### 3. Ephemeral Keys (Session-specific)
- **Generation**: New key pair for each session
- **Usage**: Diffie-Hellman key exchange for session setup
- **Lifetime**: Duration of session, then deleted

#### 4. Message Keys (Per-message)
- **Generation**: Derived from chain keys using KDF (Key Derivation Function)
- **Usage**: Encrypt/decrypt individual messages
- **Lifetime**: Single use, then deleted (ensures PFS)

### Double Ratchet Algorithm

The core of Signal Protocol. Two ratchets:

1. **DH Ratchet (Diffie-Hellman)**: Generates new chain keys with each message exchange
2. **Symmetric-Key Ratchet**: Derives message keys from chain keys

**Flow**:
```
Session Initialization
    ├─> DH Exchange (Identity + Ephemeral Keys)
    ├─> Generate Root Key
    └─> Derive Chain Keys

Message Sending
    ├─> Advance Sending Chain
    ├─> Derive Message Key
    ├─> Encrypt Message (AES-256-CBC + HMAC-SHA256)
    ├─> Delete Message Key
    └─> Send Encrypted Payload

Message Receiving
    ├─> Advance Receiving Chain
    ├─> Derive Message Key
    ├─> Decrypt Message
    ├─> Delete Message Key
    └─> Display Plaintext
```

### Encryption Implementation

**Library**: libsignal-client (Rust with Swift bindings) or SignalProtocolKit (native Swift)

**Recommendation**: Start with SignalProtocolKit for easier Swift integration. Fallback to libsignal-client if performance or feature parity is needed.

**Key Classes**:
- `SignalProtocolStore`: Manages keys, sessions, and pre-keys
- `SessionBuilder`: Establishes new sessions with contacts
- `SessionCipher`: Encrypts/decrypts messages
- `IdentityKeyStore`: Stores and verifies identity keys

---

## P2P Networking Architecture

### Network Layers

```
┌────────────────────────────────────────────────────────┐
│         Application Layer (Messages)                   │
├────────────────────────────────────────────────────────┤
│         Encryption Layer (Signal Protocol)             │
├────────────────────────────────────────────────────────┤
│         Transport Layer (Message Serialization)        │
├────────────────────────────────────────────────────────┤
│    P2P Network Layer (libp2p + Multipeer Connectivity) │
├────────────────────────────────────────────────────────┤
│         Network (WiFi, Bluetooth, Internet)            │
└────────────────────────────────────────────────────────┘
```

### libp2p Configuration

**Peer ID**: Derived from user's Signal Protocol identity public key (ensures cryptographic identity)

**Transports**:
- TCP for internet connections
- QUIC for low-latency internet connections
- Multipeer Connectivity for local network

**Protocols**:
- `/carefulwhisper/message/1.0.0` - Direct message protocol
- `/carefulwhisper/presence/1.0.0` - Online/offline status
- `/carefulwhisper/delivery/1.0.0` - Message delivery confirmations

**DHT**: Kademlia for peer discovery
- Bootstrap nodes: TBD (use public IPFS bootstrap nodes or host minimal bootstrap nodes)
- Peer routing: Find peers by their Peer ID
- Content routing: Not used (no content sharing, only direct messaging)

**Connection Management**:
- **Persistent connections**: Top 10 contacts (configurable)
- **On-demand connections**: All other contacts
- **Connection timeout**: 5 minutes of inactivity
- **Reconnection strategy**: Exponential backoff (1s, 2s, 4s, 8s, max 60s)

### Multipeer Connectivity (Local Network)

**Service Type**: `carefulwhisper-msg`

**Discovery**:
- Advertise presence when app is active
- Browse for nearby peers
- Automatic connection establishment

**Priority**: Always prefer local connection over internet if available (lower latency, no data usage)

**Handoff**: Seamless transition between local and internet connection

### NAT Traversal

**Techniques** (in order of preference):
1. Direct connection (if both peers have public IPs)
2. STUN (Session Traversal Utilities for NAT) - hole punching
3. TURN (Traversal Using Relays around NAT) - relay fallback

**STUN/TURN Servers**: Use public servers (e.g., Google's STUN servers) or host minimal TURN relay for fallback

**Note**: libp2p handles NAT traversal automatically via AutoNAT and Circuit Relay protocols

### Message Transport Protocol

**Message Envelope** (JSON):
```json
{
  "version": "1.0",
  "messageId": "uuid-v4",
  "senderId": "peer-id",
  "recipientId": "peer-id",
  "timestamp": "iso8601",
  "encryptedPayload": "base64-encoded-signal-ciphertext",
  "signalMetadata": {
    "preKeyId": "optional-number",
    "registrationId": "number"
  }
}
```

**Delivery Confirmation**:
```json
{
  "type": "delivery-confirmation",
  "messageId": "uuid-v4",
  "status": "delivered" | "read",
  "timestamp": "iso8601"
}
```

**Presence Update**:
```json
{
  "type": "presence",
  "peerId": "peer-id",
  "status": "online" | "offline",
  "timestamp": "iso8601"
}
```

---

## Data Models

### Contact
```swift
@Model
class Contact {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var publicKey: Data // Signal Protocol identity key
    var peerId: String // libp2p peer ID
    var dateAdded: Date
    var lastSeen: Date?
    var isOnline: Bool
    var isPersistentConnection: Bool // Top 10 frequent contacts

    @Relationship(deleteRule: .cascade) var conversations: [Conversation]

    init(displayName: String, publicKey: Data, peerId: String) {
        self.id = UUID()
        self.displayName = displayName
        self.publicKey = publicKey
        self.peerId = peerId
        self.dateAdded = Date()
        self.isOnline = false
        self.isPersistentConnection = false
    }

    var publicKeyFingerprint: String {
        // SHA-256 hash of public key, formatted as hex
        publicKey.sha256.hexString
    }
}
```

### Conversation
```swift
@Model
class Conversation {
    @Attribute(.unique) var id: UUID
    var type: ConversationType // oneToOne or group
    var createdAt: Date
    var lastMessageAt: Date?

    @Relationship(deleteRule: .nullify) var participants: [Contact]
    @Relationship(deleteRule: .cascade) var messages: [Message]

    // Group-specific properties
    var groupName: String?
    var groupAdminIds: [UUID]? // Contact IDs of admins

    init(type: ConversationType, participants: [Contact]) {
        self.id = UUID()
        self.type = type
        self.participants = participants
        self.createdAt = Date()
    }

    var lastMessage: Message? {
        messages.sorted(by: { $0.timestamp > $1.timestamp }).first
    }
}

enum ConversationType: String, Codable {
    case oneToOne
    case group
}
```

### Message
```swift
@Model
class Message {
    @Attribute(.unique) var id: UUID
    var content: String
    var timestamp: Date
    var status: MessageStatus
    var isFromMe: Bool

    @Relationship(deleteRule: .nullify) var conversation: Conversation?
    @Relationship(deleteRule: .nullify) var sender: Contact?

    // Encryption metadata
    var encryptedPayload: Data? // Stored only for pending outgoing messages
    var signalMessageType: SignalMessageType

    init(content: String, sender: Contact, conversation: Conversation, isFromMe: Bool) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.status = .sending
        self.sender = sender
        self.conversation = conversation
        self.isFromMe = isFromMe
        self.signalMessageType = .normal
    }
}

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}

enum SignalMessageType: String, Codable {
    case preKey // Initial message in a session
    case normal // Standard encrypted message
}
```

### EncryptionKeys
```swift
@Model
class EncryptionKeys {
    @Attribute(.unique) var id: UUID
    var userId: UUID // Single user per device
    var identityKeyPairId: String // Reference to Keychain item
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
        return Date().timeIntervalSince(lastRotated) > 30 * 24 * 60 * 60 // 30 days
    }
}
```

### UserProfile
```swift
@Model
class UserProfile {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var createdAt: Date
    var publicKey: Data
    var peerId: String

    // Settings
    var autoDeleteEnabled: Bool
    var autoDeleteDays: Int? // nil = never delete

    init(displayName: String, publicKey: Data, peerId: String) {
        self.id = UUID()
        self.displayName = displayName
        self.publicKey = publicKey
        self.peerId = peerId
        self.createdAt = Date()
        self.autoDeleteEnabled = false
    }

    var qrCodeData: String {
        // Format: carefulwhisper://contact?name=DisplayName&key=Base64PublicKey&peer=PeerId
        "carefulwhisper://contact?name=\(displayName)&key=\(publicKey.base64EncodedString())&peer=\(peerId)"
    }
}
```

---

## Message Flow

### Sending a Message (One-to-One)

```
1. User types message in ChatView
2. ChatViewModel.sendMessage(content) called
3. EncryptionService.encrypt(content, recipientContactId)
   ├─> Load or create Signal session with recipient
   ├─> Use SessionCipher to encrypt plaintext
   └─> Return encrypted payload + metadata
4. Create Message object (status: .sending)
5. Save to SwiftData
6. P2PNetworkService.sendMessage(encryptedPayload, recipientPeerId)
   ├─> Check if persistent connection exists
   ├─> If not, establish on-demand connection
   ├─> Send message envelope over libp2p stream
   └─> Update message status to .sent
7. Save updated message status
8. UI updates (message bubble shows "sent" checkmark)
```

### Receiving a Message

```
1. libp2p stream receives incoming data
2. P2PNetworkService.handleIncomingMessage(envelope)
3. Parse envelope → extract encryptedPayload + senderId
4. EncryptionService.decrypt(encryptedPayload, senderContactId)
   ├─> Load Signal session with sender
   ├─> Use SessionCipher to decrypt ciphertext
   └─> Return plaintext content
5. Create Message object (status: .delivered, isFromMe: false)
6. Save to SwiftData
7. P2PNetworkService.sendDeliveryConfirmation(messageId, status: .delivered)
8. UI updates (ChatView receives SwiftData change notification)
9. If chat is currently open, mark as read:
   ├─> Update message status to .read
   ├─> P2PNetworkService.sendDeliveryConfirmation(messageId, status: .read)
10. Display local notification if app in background
```

### Offline Message Delivery

```
Sender Side:
1. User sends message
2. Encryption and Message creation same as normal
3. P2PNetworkService.sendMessage() detects recipient offline
4. Message saved with status: .sent (queued for delivery)
5. ConnectionManager monitors for recipient coming online
6. When recipient online:
   ├─> Establish connection
   ├─> Send queued message
   └─> Update status to .delivered (on confirmation)

Recipient Side:
1. Recipient comes online
2. P2PNetworkService advertises presence via DHT
3. Sender's ConnectionManager detects recipient online
4. Sender initiates connection
5. Queued messages sent automatically
6. Recipient processes as normal incoming messages
```

---

## Security Considerations

### Key Storage
- **Identity private keys**: iOS Keychain with `kSecAttrAccessibleAfterFirstUnlock`
- **Session keys**: In-memory only, never persisted
- **Message keys**: Used once, immediately deleted (PFS)
- **Pre-key private keys**: Keychain with `kSecAttrAccessibleAfterFirstUnlock`

### Attack Vectors & Mitigations

| Attack | Mitigation |
|--------|------------|
| **Man-in-the-Middle (MITM)** | QR code verification (out-of-band key exchange), safety numbers |
| **Replay Attacks** | Signal Protocol includes message counters and nonces |
| **Key Compromise** | Perfect Forward Secrecy (past messages safe), key rotation |
| **Device Compromise** | Keychain encryption, biometric unlock (future), secure enclave (future) |
| **Network Analysis** | libp2p encrypted transport (Noise protocol), no metadata leakage |
| **Sybil Attacks (DHT)** | libp2p's Kademlia has built-in Sybil resistance |

### Trust on First Use (TOFU)
- First contact add: user scans QR code → public key saved
- Subsequent messages: verify sender's identity key matches saved key
- If mismatch detected: warn user, require re-verification

### Safety Numbers
- Concatenate both users' public key fingerprints
- Display as QR code or 60-digit number
- Users can verify out-of-band (in person, phone call)

---

## Algorithms

### QR Code Generation (Contact Sharing)

**Input**: UserProfile (displayName, publicKey, peerId)

**Output**: QR Code image

**Algorithm**:
```swift
func generateContactQRCode(profile: UserProfile) -> UIImage {
    // 1. Format data URL
    let urlString = "carefulwhisper://contact?name=\(profile.displayName.urlEncoded)&key=\(profile.publicKey.base64EncodedString())&peer=\(profile.peerId)"

    // 2. Generate QR code using CIFilter
    let data = urlString.data(using: .utf8)
    let filter = CIFilter(name: "CIQRCodeGenerator")
    filter?.setValue(data, forKey: "inputMessage")
    filter?.setValue("H", forKey: "inputCorrectionLevel") // High error correction

    // 3. Scale up for display
    let transform = CGAffineTransform(scaleX: 10, y: 10)
    let ciImage = filter?.outputImage?.transformed(by: transform)

    // 4. Convert to UIImage
    let context = CIContext()
    let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent)
    return UIImage(cgImage: cgImage!)
}
```

### QR Code Scanning (Contact Addition)

**Input**: Scanned QR code data

**Output**: Contact (displayName, publicKey, peerId)

**Algorithm**:
```swift
func parseContactQRCode(urlString: String) throws -> (displayName: String, publicKey: Data, peerId: String) {
    // 1. Validate scheme
    guard urlString.hasPrefix("carefulwhisper://contact") else {
        throw QRCodeError.invalidScheme
    }

    // 2. Parse URL components
    guard let url = URL(string: urlString),
          let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let queryItems = components.queryItems else {
        throw QRCodeError.invalidFormat
    }

    // 3. Extract parameters
    guard let name = queryItems.first(where: { $0.name == "name" })?.value,
          let keyBase64 = queryItems.first(where: { $0.name == "key" })?.value,
          let peer = queryItems.first(where: { $0.name == "peer" })?.value,
          let publicKey = Data(base64Encoded: keyBase64) else {
        throw QRCodeError.missingParameters
    }

    // 4. Validate public key format (32 bytes for Ed25519)
    guard publicKey.count == 32 else {
        throw QRCodeError.invalidPublicKey
    }

    return (displayName: name, publicKey: publicKey, peerId: peer)
}
```

### Public Key Fingerprint Display

**Input**: Public key (Data, 32 bytes)

**Output**: Fingerprint string (hex, space-separated)

**Algorithm**:
```swift
func formatPublicKeyFingerprint(publicKey: Data) -> String {
    // 1. SHA-256 hash
    let hash = SHA256.hash(data: publicKey)

    // 2. Convert to hex
    let hexString = hash.map { String(format: "%02x", $0) }.joined()

    // 3. Format for readability (space every 4 characters)
    var formatted = ""
    for (index, char) in hexString.enumerated() {
        if index > 0 && index % 4 == 0 {
            formatted += " "
        }
        formatted.append(char)
    }

    return formatted.uppercased()
}

// Example output: "A3F2 1B4C 8D9E 7F0A 5C6B 2E8D 9A1F 4B7C ..."
```

### Auto-Delete Background Task

**Trigger**: Daily at 2 AM (iOS background task)

**Algorithm**:
```swift
func autoDeleteOldMessages(maxAgeDays: Int) async {
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -maxAgeDays, to: Date())!

    let descriptor = FetchDescriptor<Message>(
        predicate: #Predicate { message in
            message.timestamp < cutoffDate
        }
    )

    let oldMessages = try? modelContext.fetch(descriptor)

    oldMessages?.forEach { message in
        modelContext.delete(message)
    }

    try? modelContext.save()
}
```

### Connection Priority Algorithm

**Goal**: Maintain persistent connections to most-contacted users

**Algorithm**:
```swift
func updatePersistentConnections() async {
    // 1. Count messages per contact (last 30 days)
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!

    let allContacts = try? modelContext.fetch(FetchDescriptor<Contact>())

    let contactMessageCounts = allContacts?.map { contact in
        let messageCount = contact.conversations.flatMap { $0.messages }
            .filter { $0.timestamp > thirtyDaysAgo }
            .count
        return (contact: contact, count: messageCount)
    } ?? []

    // 2. Sort by message count (descending)
    let sorted = contactMessageCounts.sorted { $0.count > $1.count }

    // 3. Top 10 get persistent connections
    let top10 = sorted.prefix(10).map { $0.contact }

    // 4. Update isPersistentConnection flag
    allContacts?.forEach { contact in
        contact.isPersistentConnection = top10.contains { $0.id == contact.id }
    }

    try? modelContext.save()

    // 5. ConnectionManager establishes/tears down connections accordingly
}
```

---

## Implementation Notes

### Third-Party Dependencies

| Library | Purpose | Installation |
|---------|---------|--------------|
| **libsignal-client** or **SignalProtocolKit** | Signal Protocol implementation | Swift Package Manager |
| **swift-libp2p** (if available) | P2P networking | Swift Package Manager |
| **Multipeer Connectivity** | Local network P2P | Built-in (no install needed) |

**Note**: As of 2026, Swift bindings for libp2p may be limited. Evaluate:
- **Option A**: Use available Swift libp2p bindings
- **Option B**: Bridge to Rust libp2p via FFI
- **Option C**: Fallback to WebRTC + minimal signaling server if libp2p unusable

### Performance Optimizations

- **Message pagination**: Load 50 messages at a time in ChatView
- **Contact list**: Virtualized list for large contact counts
- **Encryption caching**: Cache Signal sessions in memory (invalidate on app background)
- **Network batching**: Batch delivery confirmations (send every 5 seconds, not per message)

### Testing Approach

- **Unit tests**: Models, encryption, parsing logic
- **Integration tests**: End-to-end message sending (mock P2P layer)
- **Network tests**: Simulated network conditions (latency, packet loss, offline)
- **Security tests**: Verify PFS, replay protection, TOFU behavior
- **UI tests**: Onboarding flow, send message, add contact

---

*This spec will evolve as implementation proceeds. Update with learnings and decisions.*
