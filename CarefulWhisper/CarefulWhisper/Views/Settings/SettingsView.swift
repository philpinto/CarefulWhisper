import SwiftUI
import SwiftData

/// Main settings screen
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SettingsViewModel?
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var exportedIdentity = ""
    
    var body: some View {
        NavigationStack {
            List {
                // Privacy & Security Section
                Section {
                    NavigationLink {
                        if let vm = viewModel {
                            AutoDeleteSettingsView(viewModel: vm)
                        }
                    } label: {
                        HStack {
                            SettingsIcon(systemName: "clock.arrow.circlepath", color: .orange)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Delete Messages")
                                
                                Text(viewModel?.autoDeleteEnabled == true
                                     ? viewModel?.selectedAutoDeletePeriod.displayName ?? "Off"
                                     : "Off")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Button {
                        exportedIdentity = viewModel?.exportIdentity() ?? ""
                        showExportSheet = true
                    } label: {
                        HStack {
                            SettingsIcon(systemName: "key.fill", color: .blue)
                            Text("Export Identity")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                } header: {
                    Text("Privacy & Security")
                } footer: {
                    Text("Export your identity to back up your encryption keys. This allows contacts to verify your identity.")
                }
                
                // Storage Section
                Section {
                    HStack {
                        SettingsIcon(systemName: "person.2.fill", color: .green)
                        Text("Contacts")
                        Spacer()
                        Text("\(viewModel?.totalContacts ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        SettingsIcon(systemName: "bubble.left.and.bubble.right.fill", color: .purple)
                        Text("Conversations")
                        Spacer()
                        Text("\(viewModel?.totalConversations ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        SettingsIcon(systemName: "text.bubble.fill", color: .indigo)
                        Text("Messages")
                        Spacer()
                        Text("\(viewModel?.totalMessages ?? 0)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            SettingsIcon(systemName: "trash.fill", color: .red)
                            Text("Delete All Data")
                        }
                    }
                } header: {
                    Text("Storage")
                } footer: {
                    Text("Deleting all data will remove all contacts, conversations, and messages. This cannot be undone.")
                }
                
                // Appearance Section
                Section {
                    HStack {
                        SettingsIcon(systemName: "paintbrush.fill", color: .cyan)
                        Text("Appearance")
                        Spacer()
                        Text("System")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("CarefulWhisper follows your system appearance settings. Change your device's appearance in Settings > Display & Brightness.")
                }
                
                // About Section
                Section {
                    HStack {
                        SettingsIcon(systemName: "info.circle.fill", color: .gray)
                        Text("Version")
                        Spacer()
                        Text("\(viewModel?.appVersion ?? "1.0") (\(viewModel?.buildNumber ?? "1"))")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/carefulwhisper")!) {
                        HStack {
                            SettingsIcon(systemName: "link", color: .blue)
                            Text("Source Code")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }
                    
                    Link(destination: URL(string: "https://github.com/carefulwhisper/issues")!) {
                        HStack {
                            SettingsIcon(systemName: "ladybug.fill", color: .red)
                            Text("Report an Issue")
                            Spacer()
                            Image(systemName: "arrow.up.forward")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    Text("About")
                }
                
                // Footer
                Section {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        
                        Text("CarefulWhisper")
                            .font(.headline)
                        
                        Text("End-to-end encrypted peer-to-peer messaging")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                if viewModel == nil {
                    viewModel = SettingsViewModel(modelContext: modelContext)
                }
                viewModel?.refreshStatistics()
            }
            .confirmationDialog(
                "Delete All Data",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Everything", role: .destructive) {
                    viewModel?.deleteAllData()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all contacts, conversations, and messages. This action cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                ExportIdentitySheet(identity: exportedIdentity)
            }
        }
    }
}

// MARK: - Settings Icon

private struct SettingsIcon: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

// MARK: - Export Identity Sheet

private struct ExportIdentitySheet: View {
    let identity: String
    @Environment(\.dismiss) private var dismiss
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.blue)
                
                Text("Your Identity")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("This contains your public key and peer ID. Share this with contacts so they can verify your identity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                ScrollView {
                    Text(identity)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(maxHeight: 200)
                .padding(.horizontal)
                
                HStack(spacing: 16) {
                    Button {
                        UIPasteboard.general.string = identity
                        showCopiedToast = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopiedToast = false
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    ShareLink(item: identity) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if showCopiedToast {
                    VStack {
                        Spacer()
                        Text("Copied to clipboard")
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
                    .animation(.spring(), value: showCopiedToast)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, Contact.self, Conversation.self, Message.self, EncryptionKeys.self])
}
