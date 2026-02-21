import SwiftUI

/// Message input view with text field and send button
struct MessageInputView: View {
    @Binding var text: String
    let isSending: Bool
    let canSend: Bool
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input field
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .lineLimit(1...5)
                .focused(isFocused)
            
            // Send button
            Button(action: onSend) {
                Group {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "arrow.up")
                            .fontWeight(.semibold)
                    }
                }
                .frame(width: 20, height: 20)
            }
            .frame(width: 36, height: 36)
            .background(canSend ? Color.blue : Color.gray.opacity(0.3))
            .clipShape(Circle())
            .disabled(!canSend)
            .animation(.easeInOut(duration: 0.15), value: canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview("Empty") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isSending: false,
            canSend: false,
            isFocused: FocusState<Bool>().projectedValue
        ) {}
    }
}

#Preview("With Text") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("Hello there!"),
            isSending: false,
            canSend: true,
            isFocused: FocusState<Bool>().projectedValue
        ) {}
    }
}

#Preview("Sending") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant(""),
            isSending: true,
            canSend: false,
            isFocused: FocusState<Bool>().projectedValue
        ) {}
    }
}

#Preview("Multiline") {
    VStack {
        Spacer()
        MessageInputView(
            text: .constant("This is a longer message that spans multiple lines to show how the text field expands vertically when needed."),
            isSending: false,
            canSend: true,
            isFocused: FocusState<Bool>().projectedValue
        ) {}
    }
}
