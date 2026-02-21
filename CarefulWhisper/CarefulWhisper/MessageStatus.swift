import Foundation

enum MessageStatus: String, Codable {
    case sending
    case sent
    case delivered
    case read
    case failed
}
