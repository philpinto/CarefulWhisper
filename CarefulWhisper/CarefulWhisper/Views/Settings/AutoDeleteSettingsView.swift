import SwiftUI
import SwiftData

/// Settings view for configuring auto-delete behavior
struct AutoDeleteSettingsView: View {
    @Bindable var viewModel: SettingsViewModel
    
    var body: some View {
        List {
            // Enable/Disable Section
            Section {
                Toggle(isOn: $viewModel.autoDeleteEnabled) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.orange)
                        Text("Auto-Delete Messages")
                    }
                }
            } footer: {
                Text("When enabled, messages older than the selected time period will be automatically deleted.")
            }
            
            // Time Period Selection
            if viewModel.autoDeleteEnabled {
                Section {
                    ForEach(AutoDeletePeriod.allCases.filter { $0 != .never }) { period in
                        Button {
                            viewModel.selectedAutoDeletePeriod = period
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(period.displayName)
                                        .foregroundStyle(.primary)
                                    
                                    Text(period.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                if viewModel.selectedAutoDeletePeriod == period {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Delete Messages After")
                }
            }
            
            // Info Section
            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How Auto-Delete Works")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("Messages are checked periodically in the background. When a message's timestamp exceeds the selected time period, it will be permanently deleted from your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("This only affects messages on your device. Recipients will still have their copies.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Warning Section
            if viewModel.autoDeleteEnabled {
                Section {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Deleted messages cannot be recovered")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Make sure to save any important information before it's deleted.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Auto-Delete")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.default, value: viewModel.autoDeleteEnabled)
    }
}

#Preview {
    NavigationStack {
        AutoDeleteSettingsView(
            viewModel: SettingsViewModel(
                modelContext: try! ModelContainer(
                    for: UserProfile.self, Contact.self, Conversation.self, Message.self
                ).mainContext
            )
        )
    }
}
