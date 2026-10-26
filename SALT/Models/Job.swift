import Foundation

struct Job: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var company: String
    var location: String
    var employmentType: EmploymentType
    var description: String
    var requirements: [String]
    var salaryRange: String?
    var postedDate: Date
    var isFeatured: Bool
    var isMemberPosting: Bool
    var applyURL: String?
    var contactEmail: String?
    
    var daysAgo: String {
        let days = Calendar.current.dateComponents([.day], from: postedDate, to: Date()).day ?? 0
        if days == 0 { return "Today" }
        if days == 1 { return "1 day ago" }
        return "\(days) days ago"
    }
}

enum EmploymentType: String, Codable, CaseIterable {
    case fullTime = "Full-time"
    case partTime = "Part-time"
    case seasonal = "Seasonal"
    case contract = "Contract"
    case internship = "Internship"
}
