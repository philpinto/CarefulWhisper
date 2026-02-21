import SwiftUI

/// Individual message bubble with status indicator
struct MessageBubbleView: View {
    let message: Message
    let timeString: String
    
    private var isFromMe: Bool {
        message.isFromMe
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            if isFromMe {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 2) {
                // Message content
                Text(message.content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(bubbleColor)
                    .foregroundStyle(textColor)
                    .clipShape(BubbleShape(isFromMe: isFromMe))
                
                // Time and status
                HStack(spacing: 4) {
                    Text(timeString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    if isFromMe {
                        statusIcon
                    }
                }
                .padding(.horizontal, 4)
            }
            
            if !isFromMe {
                Spacer(minLength: 60)
            }
        }
    }
    
    // MARK: - Styling
    
    private var bubbleColor: Color {
        if isFromMe {
            return Color.blue
        } else {
            return Color(.systemGray5)
        }
    }
    
    private var textColor: Color {
        if isFromMe {
            return .white
        } else {
            return .primary
        }
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch message.status {
        case .sending:
            Image(systemName: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .sent:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .delivered:
            Image(systemName: "checkmark")
                .font(.caption2)
                .foregroundStyle(.blue)
        case .read:
            HStack(spacing: -4) {
                Image(systemName: "checkmark")
                Image(systemName: "checkmark")
            }
            .font(.caption2)
            .foregroundStyle(.blue)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption2)
                .foregroundStyle(.red)
        }
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isFromMe: Bool
    
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailSize: CGFloat = 6
        
        var path = Path()
        
        if isFromMe {
            // Right-aligned bubble with tail on right
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius - tailSize, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - tailSize, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX - tailSize, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - tailSize, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.maxX - tailSize, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
        } else {
            // Left-aligned bubble with tail on left
            path.move(to: CGPoint(x: rect.minX + radius + tailSize, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + radius),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + tailSize, y: rect.maxY - radius),
                control: CGPoint(x: rect.minX + tailSize, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.minX + tailSize, y: rect.minY + radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius + tailSize, y: rect.minY),
                control: CGPoint(x: rect.minX + tailSize, y: rect.minY)
            )
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview("Sent Message") {
    VStack {
        MessageBubbleView(
            message: {
                let msg = Message(content: "Hello! How are you?", isFromMe: true, status: .sent)
                return msg
            }(),
            timeString: "2:30 PM"
        )
    }
    .padding()
}

#Preview("Received Message") {
    VStack {
        MessageBubbleView(
            message: {
                let msg = Message(content: "I'm doing great, thanks for asking!", isFromMe: false, status: .delivered)
                return msg
            }(),
            timeString: "2:31 PM"
        )
    }
    .padding()
}

#Preview("Message Status") {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: Message(content: "Sending...", isFromMe: true, status: .sending),
            timeString: "2:30 PM"
        )
        MessageBubbleView(
            message: Message(content: "Sent!", isFromMe: true, status: .sent),
            timeString: "2:30 PM"
        )
        MessageBubbleView(
            message: Message(content: "Delivered!", isFromMe: true, status: .delivered),
            timeString: "2:30 PM"
        )
        MessageBubbleView(
            message: Message(content: "Read!", isFromMe: true, status: .read),
            timeString: "2:30 PM"
        )
        MessageBubbleView(
            message: Message(content: "Failed to send", isFromMe: true, status: .failed),
            timeString: "2:30 PM"
        )
    }
    .padding()
}

#Preview("Long Message") {
    VStack {
        MessageBubbleView(
            message: Message(content: "This is a much longer message that should wrap to multiple lines. It demonstrates how the bubble shape handles longer content gracefully.", isFromMe: true, status: .delivered),
            timeString: "2:32 PM"
        )
        MessageBubbleView(
            message: Message(content: "And this is a long received message that also wraps to multiple lines to show the different bubble styling.", isFromMe: false, status: .read),
            timeString: "2:33 PM"
        )
    }
    .padding()
}
