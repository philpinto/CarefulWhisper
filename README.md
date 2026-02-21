# CarefulWhisper

A privacy-focused, end-to-end encrypted peer-to-peer messaging app for iOS. No servers, no tracking, no compromises.

## Features

- **End-to-End Encryption**: All messages are encrypted using CryptoKit with Curve25519 key exchange and ChaCha20-Poly1305 symmetric encryption
- **Peer-to-Peer Communication**: Direct device-to-device messaging via Multipeer Connectivity - no central servers
- **QR Code Contact Exchange**: Add contacts by scanning QR codes containing their public key
- **Message Status Tracking**: Real-time delivery confirmations and read receipts
- **Local Notifications**: Get notified when new messages arrive
- **Auto-Delete Messages**: Configurable message retention (7 days, 30 days, 90 days, 1 year, or never)
- **Privacy by Design**: Messages stored only on your device, keys never leave your device
- **Accessibility**: Full VoiceOver support for visually impaired users

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 5.9+

## Architecture

CarefulWhisper follows the MVVM (Model-View-ViewModel) architecture pattern with a services layer:

```
CarefulWhisper/
├── Models/
│   ├── Contact.swift
│   ├── Conversation.swift
│   ├── Message.swift
│   ├── UserProfile.swift
│   └── EncryptionKeys.swift
├── Views/
│   ├── Onboarding/
│   ├── Contacts/
│   ├── Conversations/
│   ├── Profile/
│   └── Settings/
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── ContactListViewModel.swift
│   ├── ChatViewModel.swift
│   └── SettingsViewModel.swift
└── Services/
    ├── EncryptionService.swift
    ├── P2PNetworkService.swift
    ├── MessageTransportService.swift
    ├── PresenceService.swift
    └── AutoDeleteService.swift
```

## Security

### Encryption
- **Key Exchange**: X25519 (Curve25519) Diffie-Hellman
- **Message Encryption**: ChaCha20-Poly1305 authenticated encryption
- **Key Derivation**: HKDF-SHA256
- **Signatures**: Ed25519 for message authentication
- **Forward Secrecy**: Ephemeral keys for each message session

### Data Storage
- Private keys stored in iOS Keychain with biometric protection
- Messages stored locally using SwiftData
- No cloud sync, no server storage
- Optional auto-delete for message expiration

## How It Works

1. **Setup**: On first launch, the app generates a unique cryptographic identity (public/private key pair)
2. **Adding Contacts**: Share your QR code or scan a contact's QR code to exchange public keys
3. **Messaging**: When both users are nearby (same WiFi or Bluetooth range), messages are sent directly between devices
4. **Encryption**: Each message is encrypted with the recipient's public key before transmission
5. **Delivery**: The recipient's device decrypts the message and displays it

## Building

1. Clone the repository:
   ```bash
   git clone https://github.com/philpinto/CarefulWhisper.git
   cd CarefulWhisper
   ```

2. Open in Xcode:
   ```bash
   open CarefulWhisper.xcodeproj
   ```

3. Select your development team in Signing & Capabilities

4. Build and run on a physical device (Multipeer Connectivity requires real devices for full functionality)

## Testing

Run the test suite:
```bash
xcodebuild test -scheme CarefulWhisper -destination 'platform=iOS Simulator,name=iPhone 16'
```

Or in Xcode: Product > Test (Cmd+U)

The project includes 70 unit tests covering:
- Data models and relationships
- Encryption/decryption roundtrips
- Key generation and agreement
- Message queue operations
- URL parsing and encoding

## Project Status

| Phase | Feature | Status |
|-------|---------|--------|
| 1 | Foundation & Data Models | Complete |
| 2 | Encryption Layer | Complete |
| 3 | P2P Networking | Complete |
| 4 | Onboarding & Profile | Complete |
| 5 | Contacts | Complete |
| 6 | Messaging | Complete |
| 7 | Message Delivery & Status | Complete |
| 8 | watchOS Companion | Planned |
| 9 | Polish & Settings | Complete |
| 10 | Relay Server (Internet Messaging) | Planned |

## Privacy Policy

CarefulWhisper collects **zero** user data:
- No accounts or registration
- No analytics or tracking
- No server communication
- No cloud storage
- All data stays on your device

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a pull request.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Built with SwiftUI and SwiftData
- Encryption powered by Apple CryptoKit
- P2P networking via Multipeer Connectivity framework
