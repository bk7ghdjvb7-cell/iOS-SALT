import Foundation

struct Event: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var description: String
    var startDate: Date
    var endDate: Date?
    var location: String
    var imageURL: String?
    var memberPrice: Double?
    var nonMemberPrice: Double?
    var isSignature: Bool
    var maxAttendees: Int?
    var currentAttendees: Int
    var category: EventCategory
    var isRSVPed: Bool // local state for current user
    
    var isFull: Bool {
        guard let max = maxAttendees else { return false }
        return currentAttendees >= max
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
}

enum EventCategory: String, Codable, CaseIterable {
    case networking = "Networking"
    case education = "Education"
    case social = "Social"
    case advocacy = "Advocacy"
    case other = "Other"
}
