import SwiftUI

/// Detailed view for a single contact
struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let contact: Contact
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    @State private var showCopiedAlert = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Avatar and name
                    headerSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Contact info
                    infoSection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Security section
                    securitySection
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Actions
                    actionsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Contact",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete \(contact.displayName)? This will also delete your conversation history with them.")
            }
            .overlay {
                if showCopiedAlert {
                    copiedToast
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(avatarColor)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(initials)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            
            // Name
            Text(contact.displayName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(contact.isOnline ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                
                Text(contact.isOnline ? "Online" : "Offline")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                InfoRow(
                    icon: "calendar",
                    title: "Added",
                    value: formattedDate(contact.dateAdded)
                )
                
                if let lastSeen = contact.lastSeen {
                    Divider()
                        .padding(.leading, 56)
                    
                    InfoRow(
                        icon: "clock",
                        title: "Last Seen",
                        value: formattedDate(lastSeen)
                    )
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
        }
    }
    
    // MARK: - Security Section
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security")
                .font(.headline)
                .padding(.horizontal)
            
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
                        
                        Text(contact.publicKeyFingerprint)
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
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            
            Text("Compare this fingerprint with your contact in person to verify their identity")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Start conversation button
            Button {
                // TODO: Navigate to chat (Phase 6)
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "bubble.left.fill")
                    Text("Send Message")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            
            // Delete button
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Contact")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .foregroundStyle(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
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
    
    private var initials: String {
        let components = contact.displayName.split(separator: " ")
        if components.count >= 2 {
            return String(components[0].prefix(1) + components[1].prefix(1)).uppercased()
        }
        return String(contact.displayName.prefix(2)).uppercased()
    }
    
    private var avatarColor: Color {
        let hash = contact.displayName.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.6, brightness: 0.7)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func copyFingerprint() {
        UIPasteboard.general.string = contact.publicKeyFingerprint
        
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

/// Row displaying contact information
private struct InfoRow: View {
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
    ContactDetailView(
        contact: Contact(
            displayName: "Alice Johnson",
            publicKey: Data(repeating: 0xAB, count: 32),
            peerId: "peer123"
        ),
        onDelete: { }
    )
}
