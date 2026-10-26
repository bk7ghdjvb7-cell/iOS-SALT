import Foundation

struct FeedPost: Identifiable, Codable, Equatable {
    let id: String
    var authorId: String
    var authorName: String
    var authorBusiness: String?
    var authorImageURL: String?
    var content: String
    var imageURL: String?
    var createdAt: Date
    var likesCount: Int
    var commentsCount: Int
    var isLikedByCurrentUser: Bool
    var isAnnouncement: Bool
    var isPinned: Bool
    var attachments: [FeedPostAttachment] = []
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

struct FeedPostAttachment: Identifiable, Codable, Equatable {
    let id: String
    var type: FeedPostAttachmentType
    var data: Data?
    var filename: String?
}

enum FeedPostAttachmentType: String, Codable, Equatable {
    case image
    case video
}

struct Comment: Identifiable, Codable {
    let id: String
    var postId: String
    var authorId: String
    var authorName: String
    var content: String
    var createdAt: Date
}
