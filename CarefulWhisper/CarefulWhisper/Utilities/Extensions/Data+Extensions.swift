import Foundation
import CryptoKit

extension Data {
    /// Computes the SHA-256 hash of the data
    var sha256: Data {
        let hash = SHA256.hash(data: self)
        return Data(hash)
    }
    
    /// Converts the data to a hexadecimal string representation
    var hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }
}
