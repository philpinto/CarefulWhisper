import SwiftUI
import SwiftData

/// View for displaying and responding to incoming contact requests
struct ContactRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appServices) private var appServices
    
    let request: ContactRequest
    var onAccepted: (() -> Void)?
    var onDeclined: (() -> Void)?
    
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header icon
            Image(systemName: "person.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .padding(.top, 20)
            
            // Title
            Text("Contact Request")
                .font(.title2)
                .fontWeight(.bold)
            
            // Sender info
            VStack(spacing: 8) {
                Text(request.senderName)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text("wants to add you as a contact")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Received \(request.receivedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            // Security notice
            VStack(spacing: 4) {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.green)
                Text("Messages will be end-to-end encrypted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button {
                    acceptRequest()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark")
                        }
                        Text("Accept")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing)
                
                Button {
                    declineRequest()
                } label: {
                    HStack {
                        Image(systemName: "xmark")
                        Text("Decline")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundStyle(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isProcessing)
            }
            .padding(.bottom)
        }
        .padding()
    }
    
    private func acceptRequest() {
        isProcessing = true
        Task {
            await appServices?.contactRequestService.acceptRequest(request)
            isProcessing = false
            onAccepted?()
            dismiss()
        }
    }
    
    private func declineRequest() {
        isProcessing = true
        Task {
            await appServices?.contactRequestService.declineRequest(request)
            isProcessing = false
            onDeclined?()
            dismiss()
        }
    }
}

/// Banner view for showing incoming contact request notification
struct ContactRequestBanner: View {
    let request: ContactRequest
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Contact Request")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(request.senderName) wants to connect")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 10)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Request View") {
    ContactRequestView(
        request: ContactRequest(
            senderName: "Alice",
            senderPeerId: "abc123",
            senderPublicKey: Data(),
            isIncoming: true
        )
    )
}

#Preview("Banner") {
    ContactRequestBanner(
        request: ContactRequest(
            senderName: "Bob",
            senderPeerId: "def456",
            senderPublicKey: Data(),
            isIncoming: true
        ),
        onTap: {}
    )
    .padding()
}
