import SwiftUI

/// App icon: dark background with message bubble as lock body + shackle on top
struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    private var iconColor: Color {
        Color(red: 0.28, green: 0.28, blue: 0.32)
    }
    
    var body: some View {
        ZStack {
            // Dark grey / light black background
            Color(red: 0.12, green: 0.12, blue: 0.14)
            
            // Lock shackle (the loop on top)
            LockShackle()
                .stroke(iconColor, style: StrokeStyle(lineWidth: size * 0.06, lineCap: .round))
                .frame(width: size * 0.28, height: size * 0.22)
                .offset(y: -size * 0.22)
            
            // Message bubble as lock body
            MessageBubbleIcon()
                .fill(iconColor)
                .frame(width: size * 0.55, height: size * 0.42)
                .offset(y: size * 0.08)
        }
        .frame(width: size, height: size)
    }
}

struct LockShackle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        
        // Draw U-shape (upside down)
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.4))
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.4),
            control: CGPoint(x: w / 2, y: -h * 0.15)
        )
        path.addLine(to: CGPoint(x: w, y: h))
        
        return path
    }
}

struct MessageBubbleIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let w = rect.width
        let h = rect.height
        let cornerRadius = w * 0.18
        let tailSize = w * 0.12
        
        // Start top-left
        path.move(to: CGPoint(x: cornerRadius, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: w - cornerRadius, y: 0))
        
        // Top-right corner
        path.addQuadCurve(
            to: CGPoint(x: w, y: cornerRadius),
            control: CGPoint(x: w, y: 0)
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: w, y: h - cornerRadius - tailSize))
        
        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: w - cornerRadius, y: h - tailSize),
            control: CGPoint(x: w, y: h - tailSize)
        )
        
        // Bottom edge to tail
        path.addLine(to: CGPoint(x: tailSize * 2.5, y: h - tailSize))
        
        // Tail
        path.addQuadCurve(
            to: CGPoint(x: tailSize * 0.5, y: h),
            control: CGPoint(x: tailSize * 1.5, y: h - tailSize * 0.3)
        )
        path.addQuadCurve(
            to: CGPoint(x: tailSize * 1.5, y: h - tailSize),
            control: CGPoint(x: tailSize * 0.8, y: h - tailSize * 0.6)
        )
        
        // Bottom edge after tail
        path.addLine(to: CGPoint(x: cornerRadius, y: h - tailSize))
        
        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - cornerRadius - tailSize),
            control: CGPoint(x: 0, y: h - tailSize)
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: cornerRadius))
        
        // Top-left corner
        path.addQuadCurve(
            to: CGPoint(x: cornerRadius, y: 0),
            control: CGPoint(x: 0, y: 0)
        )
        
        path.closeSubpath()
        return path
    }
}

// Screenshot this square icon (Cmd+Shift+4), resize to 1024x1024 in Preview app
#Preview("App Icon - Screenshot This") {
    AppIconView(size: 512)
        .frame(width: 512, height: 512)
}
