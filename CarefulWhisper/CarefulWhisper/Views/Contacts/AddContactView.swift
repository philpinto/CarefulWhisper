import SwiftUI
import SwiftData
import AVFoundation

/// View for adding a new contact via QR scan or manual entry
struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: ContactListViewModel
    
    @State private var selectedTab: AddContactTab = .scan
    @State private var manualPeerId: String = ""
    @State private var manualDisplayName: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    enum AddContactTab {
        case scan
        case manual
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Add Method", selection: $selectedTab) {
                    Text("Scan QR").tag(AddContactTab.scan)
                    Text("Enter ID").tag(AddContactTab.manual)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                switch selectedTab {
                case .scan:
                    qrScannerView
                case .manual:
                    manualEntryView
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Request Sent", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Contact request sent! They will appear in your contacts once they accept.")
            }
        }
    }
    
    // MARK: - QR Scanner View
    
    private var qrScannerView: some View {
        VStack(spacing: 20) {
            QRScannerView { result in
                handleScannedCode(result)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
            
            Text("Point your camera at a contact's QR code")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.top)
    }
    
    // MARK: - Manual Entry View
    
    private var manualEntryView: some View {
        Form {
            Section {
                TextField("Display Name", text: $manualDisplayName)
                    .textContentType(.name)
                    .autocorrectionDisabled()
            } header: {
                Text("Contact Name")
            } footer: {
                Text("The name you want to use for this contact")
            }
            
            Section {
                TextField("Peer ID or Contact URL", text: $manualPeerId)
                    .textContentType(.none)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .font(.system(.body, design: .monospaced))
            } header: {
                Text("Contact ID")
            } footer: {
                Text("Paste the contact URL (carefulwhisper://...) or their peer ID")
            }
            
            Section {
                Button {
                    addManualContact()
                } label: {
                    HStack {
                        Spacer()
                        Text("Add Contact")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!canAddManually)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canAddManually: Bool {
        !manualDisplayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !manualPeerId.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func handleScannedCode(_ code: String) {
        if let contactData = ContactQRParser.parse(code) {
            Task {
                let success = await viewModel.sendContactRequest(
                    displayName: contactData.name,
                    publicKey: contactData.publicKey,
                    peerId: contactData.peerId
                )
                if success {
                    showSuccess = true
                } else {
                    errorMessage = viewModel.errorMessage ?? "Failed to send contact request"
                    showError = true
                }
            }
        } else {
            errorMessage = "Invalid QR code format"
            showError = true
        }
    }
    
    private func addManualContact() {
        let trimmedId = manualPeerId.trimmingCharacters(in: .whitespaces)
        let trimmedName = manualDisplayName.trimmingCharacters(in: .whitespaces)
        
        // Check if it's a full URL
        if let contactData = ContactQRParser.parse(trimmedId) {
            // Use parsed data, but override name if provided
            let nameToUse = trimmedName.isEmpty ? contactData.name : trimmedName
            Task {
                let success = await viewModel.sendContactRequest(
                    displayName: nameToUse,
                    publicKey: contactData.publicKey,
                    peerId: contactData.peerId
                )
                if success {
                    showSuccess = true
                } else {
                    errorMessage = viewModel.errorMessage ?? "Failed to send contact request"
                    showError = true
                }
            }
        } else {
            // Treat as raw peer ID (hex string)
            // For manual entry without full URL, we need to generate a placeholder public key
            // In a real app, we'd need to exchange keys via the P2P network
            errorMessage = "Please paste the full contact URL (carefulwhisper://...)"
            showError = true
        }
    }
}

/// Parser for contact QR code URLs
struct ContactQRParser {
    struct ContactData {
        let name: String
        let publicKey: Data
        let peerId: String
    }
    
    /// Parses a carefulwhisper:// URL into contact data
    static func parse(_ urlString: String) -> ContactData? {
        guard urlString.hasPrefix("carefulwhisper://contact?") else {
            return nil
        }
        
        guard let url = URL(string: urlString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        var name: String?
        var keyBase64: String?
        var peerId: String?
        
        for item in queryItems {
            switch item.name {
            case "name":
                name = item.value?.removingPercentEncoding
            case "key":
                keyBase64 = item.value
            case "peer":
                peerId = item.value
            default:
                break
            }
        }
        
        guard let contactName = name,
              let keyString = keyBase64,
              let publicKey = Data(base64Encoded: keyString),
              let contactPeerId = peerId else {
            return nil
        }
        
        return ContactData(name: contactName, publicKey: publicKey, peerId: contactPeerId)
    }
}

#Preview {
    AddContactView(viewModel: ContactListViewModel(
        modelContext: try! ModelContainer(for: Contact.self).mainContext
    ))
}
