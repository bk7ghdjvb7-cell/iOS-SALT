import Foundation

struct Resource: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var title: String
    var description: String
    var category: ResourceCategory
    var url: String?
    var content: String? // for in-app content
    var isMemberOnly: Bool
    var lastUpdated: Date
    var iconName: String
}

enum ResourceCategory: String, Codable, CaseIterable, Identifiable {
    case businessSupport = "Business Support"
    case licensesPermits = "Licenses & Permits"
    case crimeSafety = "Crime & Safety"
    case legislative = "Legislative Updates"
    case education = "Education & Training"
    case partnerships = "Partnerships"
    
    var id: String { rawValue }
    
    var systemImage: String {
        switch self {
        case .businessSupport: return "briefcase.fill"
        case .licensesPermits: return "doc.text.fill"
        case .crimeSafety: return "shield.fill"
        case .legislative: return "building.columns.fill"
        case .education: return "book.fill"
        case .partnerships: return "person.3.fill"
        }
    }
}
