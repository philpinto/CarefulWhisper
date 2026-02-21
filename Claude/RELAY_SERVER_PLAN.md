# CarefulWhisper Relay Server - Implementation Plan

## Overview

A minimal, privacy-preserving relay server that enables message delivery when devices aren't on the same local network. The server acts as a temporary encrypted mailbox - it never sees message content and deletes messages after delivery.

## Architecture

```
┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│   Device A      │         │  Relay Server   │         │   Device B      │
│                 │         │                 │         │                 │
│  ┌───────────┐  │         │  ┌───────────┐  │         │  ┌───────────┐  │
│  │ Message   │  │────────▶│  │ Encrypted │  │◀────────│  │ Poll/Push │  │
│  │ Encrypted │  │  HTTPS  │  │ Mailbox   │  │  HTTPS  │  │ Retrieve  │  │
│  │ Locally   │  │         │  │ (temp)    │  │         │  │ & Decrypt │  │
│  └───────────┘  │         │  └───────────┘  │         │  └───────────┘  │
└─────────────────┘         └─────────────────┘         └─────────────────┘
                                    │
                                    │ APNs
                                    ▼
                            ┌─────────────────┐
                            │  Apple Push     │
                            │  Notification   │
                            └─────────────────┘
```

## Privacy Guarantees

| Data | Server Sees | Server Stores |
|------|-------------|---------------|
| Message content | ❌ Never (E2E encrypted) | ❌ Never |
| Sender identity | ❌ Ephemeral token only | ❌ No logs |
| Recipient ID | ✅ Public key hash (routing) | ⏱️ Until delivered |
| Message metadata | ⏱️ Timestamp, size | ⏱️ Until delivered |
| IP addresses | ✅ Transient | ❌ No logs |
| Contact graph | ❌ Never | ❌ Never |

## Message Flow

### Sending (Device A)
1. App checks if recipient is on local network (Multipeer)
2. If local: send via Multipeer directly (existing flow)
3. If not local:
   - Encrypt message with recipient's public key (existing)
   - Generate ephemeral sender token
   - POST to relay: `{recipientHash, encryptedBlob, senderToken, ttl}`
   - Relay stores in mailbox, triggers APNs silent push to recipient

### Receiving (Device B)
1. Receives APNs silent push OR polls on app open
2. GET from relay: `/mailbox/{myPublicKeyHash}`
3. Relay returns all pending messages
4. Device decrypts each message locally
5. Device sends DELETE acknowledgment
6. Relay purges delivered messages

## Server Components

### API Endpoints

```
POST   /v1/messages              # Submit encrypted message
GET    /v1/mailbox/{recipientId} # Retrieve pending messages
DELETE /v1/messages/{messageId}  # Acknowledge delivery
POST   /v1/register              # Register APNs token (optional)
GET    /v1/health                # Health check
```

### Data Model

```
Message {
    id: UUID
    recipientHash: String (32 chars, SHA256 of public key)
    encryptedBlob: Blob (max 256KB)
    senderToken: String (ephemeral, for delivery receipts)
    createdAt: Timestamp
    expiresAt: Timestamp (default: createdAt + 7 days)
}

DeviceToken {
    recipientHash: String
    apnsToken: String
    updatedAt: Timestamp
}
```

### Storage

- Redis or SQLite for simplicity
- No persistent storage of delivered messages
- Automatic TTL expiration
- Max storage per recipient: 100 messages or 25MB

## iOS Client Changes

### New Service: RelayService

```swift
protocol MessageTransport {
    func send(encryptedPayload: Data, to recipientHash: String) async -> SendResult
    func fetchPendingMessages() async -> [EncryptedEnvelope]
}

class RelayService: MessageTransport {
    let baseURL: URL
    let session: URLSession

    func send(...) async -> SendResult
    func fetchPendingMessages() async -> [EncryptedEnvelope]
    func acknowledgeDelivery(messageId: UUID) async
    func registerForPush(token: Data) async
}
```

### Modified: MessageTransportService

```swift
// Existing flow
func sendMessage(...) async throws -> Message {
    // 1. Try Multipeer first (local network)
    if let peerId = p2pService.findPeerByPublicKey(contact.publicKey) {
        return try await sendViaMultipeer(...)
    }

    // 2. Fall back to relay server
    return try await sendViaRelay(...)
}
```

### Push Notifications

- Register APNs token with relay server
- Handle silent push to trigger message fetch
- Background fetch for polling when push unavailable

## Server Implementation Options

### Option A: Cloudflare Workers + KV (Recommended for MVP)
- **Pros**: Serverless, global edge, cheap, easy to deploy
- **Cons**: KV eventually consistent (fine for messaging)
- **Cost**: Free tier covers ~100K messages/day

### Option B: Self-hosted (Docker)
- Simple Go or Rust binary
- SQLite for storage
- Runs on any $5/month VPS
- Provide Docker image for self-hosters

### Option C: Both
- Default to Cloudflare Workers
- Publish self-host Docker image
- Settings allows custom relay URL

## Implementation Phases

### Phase 1: Server MVP
- [ ] Basic API endpoints (POST message, GET mailbox, DELETE ack)
- [ ] In-memory or KV storage
- [ ] TTL expiration
- [ ] Rate limiting
- [ ] Health endpoint

### Phase 2: iOS Integration
- [ ] Create RelayService
- [ ] Modify MessageTransportService for hybrid routing
- [ ] Add relay URL to app config
- [ ] Handle offline queueing for relay

### Phase 3: Push Notifications
- [ ] APNs integration on server
- [ ] Token registration endpoint
- [ ] Silent push on new message
- [ ] Handle push in iOS app

### Phase 4: Polish
- [ ] Custom relay URL in Settings
- [ ] Connection status indicator
- [ ] Retry logic with exponential backoff
- [ ] Delivery receipts via relay

### Phase 5: Self-hosting
- [ ] Docker image
- [ ] Documentation
- [ ] One-click deploy templates (Railway, Fly.io)

## Security Considerations

1. **TLS everywhere** - All relay communication over HTTPS
2. **No auth required** - Public key hash is the "address"
3. **Rate limiting** - Prevent spam/DoS
4. **Size limits** - Max 256KB per message
5. **TTL enforcement** - Messages auto-delete
6. **No logs** - Server logs only errors, no message metadata
7. **Open source** - Server code public for auditability

## Cost Estimates

| Scale | Cloudflare Workers | Self-hosted VPS |
|-------|-------------------|-----------------|
| 1K users | Free tier | $5/month |
| 10K users | ~$5/month | $10/month |
| 100K users | ~$25/month | $50/month |

## Open Questions

1. **Delivery receipts via relay?** - Should the relay forward delivery/read receipts when devices aren't local?

2. **Key rotation** - If user regenerates keys, how do we handle pending messages encrypted with old key?

3. **Multiple devices** - Same user on iPhone + iPad? Share mailbox or separate?

4. **Abuse prevention** - How to prevent spam without compromising anonymity?

## Success Criteria

- [ ] Messages deliver reliably when not on same network
- [ ] Latency < 2 seconds for delivery (excluding push delay)
- [ ] Zero plaintext ever touches server
- [ ] Server can be fully replaced without app update (URL config)
- [ ] Self-hosting documented and tested
