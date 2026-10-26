import Foundation
import FirebaseFirestore

struct Conversation: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var participantIds: [String]
    var participantNames: [String: String]
    var lastMessage: String
    var lastMessageAt: Date
    var lastSenderId: String
    var unreadCount: [String: Int]
    
    func otherParticipant(currentUid: String) -> (id: String, name: String)? {
        guard let otherId = participantIds.first(where: { $0 != currentUid }) else { return nil }
        return (otherId, participantNames[otherId] ?? "Member")
    }
}

struct ChatMessage: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var conversationId: String
    var senderId: String
    var senderName: String
    var text: String
    var createdAt: Date
    var isRead: Bool
}

struct MembershipApplication: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var fullName: String
    var businessName: String?
    var tier: String
    var categories: [String]
    var status: String
    var submittedAt: Date
    var reviewedBy: String?
    var reviewedAt: Date?
    var notes: String?
}

struct MembershipPayment: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var amount: Double
    var tier: String
    var year: Int
    var status: String
    var stripePaymentIntentId: String?
    var createdAt: Date
    var paidAt: Date?
}
