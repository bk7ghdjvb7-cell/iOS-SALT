import Combine
import Foundation

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    @Published var posts: [FeedPost]
    @Published var comments: [Comment]
    @Published var events: [Event]

    private init() {
        posts = MockData.feedPosts
        comments = MockData.comments
        events = MockData.events
    }

    func addPost(_ post: FeedPost) {
        posts.insert(post, at: 0)
    }

    func deletePost(id: String) {
        posts.removeAll { $0.id == id }
        comments.removeAll { $0.postId == id }
    }

    func deleteComment(id: String) {
        guard let comment = comments.first(where: { $0.id == id }) else { return }
        comments.removeAll { $0.id == id }

        if let postIndex = posts.firstIndex(where: { $0.id == comment.postId }) {
            posts[postIndex].commentsCount = max(0, posts[postIndex].commentsCount - 1)
        }
    }

    func comments(for postId: String) -> [Comment] {
        comments
            .filter { $0.postId == postId }
            .sorted { $0.createdAt < $1.createdAt }
    }

    func addComment(_ comment: Comment) {
        comments.append(comment)

        if let postIndex = posts.firstIndex(where: { $0.id == comment.postId }) {
            posts[postIndex].commentsCount += 1
        }
    }

    func addEvent(_ event: Event) {
        events.append(event)
        events.sort { $0.startDate < $1.startDate }
    }

    func updateEvent(_ event: Event) {
        guard let index = events.firstIndex(where: { $0.id == event.id }) else { return }
        events[index] = event
    }
}
