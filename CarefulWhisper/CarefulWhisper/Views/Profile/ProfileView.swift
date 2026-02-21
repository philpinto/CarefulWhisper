import SwiftUI
import SwiftData

/// User profile view showing QR code and profile information
struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ProfileViewModel?
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // QR Code section
                    qrCodeSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Profile info section
                    profileInfoSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Security info section
                    securityInfoSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditingName = true
                        editedName = viewModel?.displayName ?? ""
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .alert("Edit Display Name", isPresented: $isEditingName) {
                TextField("Display Name", text: $editedName)
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    viewModel?.updateDisplayName(editedName)
                }
            }
            .overlay {
                if showCopiedAlert {
                    copiedToast
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = ProfileViewModel(modelContext: modelContext)
            }
        }
    }
    
    // MARK: - QR Code Section
    
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            Text("Your QR Code")
                .font(.headline)
            
            if let qrData = viewModel?.qrCodeData, !qrData.isEmpty {
                QRCodeView(data: qrData, size: 220)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10)
            }
            
            Text("Share this code to let others add you as a contact")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Profile Info Section
    
    private var profileInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profile Information")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ProfileInfoRow(
                    icon: "person.fill",
                    title: "Display Name",
                    value: viewModel?.displayName ?? "—"
                )
                
                Divider()
                    .padding(.leading, 56)
                
                ProfileInfoRow(
                    icon: "calendar",
                    title: "Created",
                    value: formattedDate(viewModel?.profileCreatedAt)
                )
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Security Info Section
    
    private var securityInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                Button {
                    copyFingerprint()
                } label: {
                    HStack {
                        Image(systemName: "key.fill")
                            .frame(width: 24)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Public Key Fingerprint")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            
                            Text(viewModel?.publicKeyFingerprint ?? "—")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .buttonStyle(.plain)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            
            Text("Compare this fingerprint with your contact to verify their identity")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Copied Toast
    
    private var copiedToast: some View {
        VStack {
            Spacer()
            
            Text("Fingerprint copied")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .shadow(radius: 10)
                .padding(.bottom, 50)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: showCopiedAlert)
    }
    
    // MARK: - Helpers
    
    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "—" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func copyFingerprint() {
        guard let fingerprint = viewModel?.publicKeyFingerprint else { return }
        UIPasteboard.general.string = fingerprint
        
        withAnimation {
            showCopiedAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
}

/// Row displaying profile information
private struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body)
            }
            
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [UserProfile.self, Contact.self, Conversation.self, Message.self, EncryptionKeys.self])
}
