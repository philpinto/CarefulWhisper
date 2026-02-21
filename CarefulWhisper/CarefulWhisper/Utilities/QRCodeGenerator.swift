import SwiftUI
import CoreImage.CIFilterBuiltins

/// Utility for generating QR codes from strings
struct QRCodeGenerator {
    
    /// Generates a QR code image from the given string
    /// - Parameters:
    ///   - string: The string to encode in the QR code
    ///   - size: The desired size of the output image
    /// - Returns: A UIImage containing the QR code, or nil if generation fails
    static func generate(from string: String, size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        guard let data = string.data(using: .utf8) else {
            return nil
        }
        
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction
        
        guard let outputImage = filter.outputImage else {
            return nil
        }
        
        // Scale the image to the desired size
        let scaleX = size.width / outputImage.extent.size.width
        let scaleY = size.height / outputImage.extent.size.height
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

/// SwiftUI View that displays a QR code
struct QRCodeView: View {
    let data: String
    let size: CGFloat
    
    init(data: String, size: CGFloat = 200) {
        self.data = data
        self.size = size
    }
    
    var body: some View {
        if let image = QRCodeGenerator.generate(
            from: data,
            size: CGSize(width: size, height: size)
        ) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            // Fallback if QR generation fails
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)
                .overlay {
                    VStack {
                        Image(systemName: "qrcode")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("QR Code unavailable")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        QRCodeView(data: "carefulwhisper://contact?name=Alice&key=abc123&peer=peer123", size: 200)
        
        QRCodeView(data: "Hello, World!", size: 150)
    }
}
