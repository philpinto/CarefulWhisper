import Foundation

extension String {
    /// Returns a URL-encoded version of the string suitable for use in URL query parameters
    var urlEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
