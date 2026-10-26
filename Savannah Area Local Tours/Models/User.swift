import Foundation

// MARK: - Membership Tiers
enum MembershipTier: String, Codable, CaseIterable, Identifiable {
    case individual = "Individual / Sole Proprietor"
    case business = "For-Profit Business"
    
    var id: String { rawValue }
    
    var annualDues: Double {
        switch self {
        case .individual: return 150
        case .business: return 350
        }
    }
    
    var description: String {
        switch self {
        case .individual:
            return "For independent guides, sole proprietors, and freelancers."
        case .business:
            return "For tour companies, restaurants, hotels, retail, and other tourism businesses."
        }
    }
}

// MARK: - User / Member
struct User: Identifiable, Codable, Equatable, Hashable {
    let id: String
    var email: String
    var firstName: String
    var lastName: String
    var businessName: String?
    var tier: MembershipTier
    var membershipStatus: MembershipStatus
    var joinDate: Date
    var phone: String?
    var website: String?
    var bio: String?
    var profileImageURL: String?
    var isBoardMember: Bool
    var categories: [BusinessCategory]
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var displayName: String {
        businessName ?? fullName
    }
}

enum MembershipStatus: String, Codable {
    case pending
    case active
    case expired
    case suspended
}

enum BusinessCategory: String, Codable, CaseIterable, Identifiable {
    case tourGuide = "Tour Guide / Operator"
    case restaurant = "Restaurant / Food"
    case hotel = "Hotel / Lodging"
    case retail = "Retail"
    case attraction = "Attraction"
    case transportation = "Transportation"
    case other = "Other Tourism"
    
    var id: String { rawValue }
}
