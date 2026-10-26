import Combine
import Foundation

enum DeepLink: Equatable {
    case conversation(id: String)
    case boardApplications
    case profile
    case event(id: String)
    case job(id: String)
}

@MainActor
final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var pendingDeepLink: DeepLink?

    private init() { }

    func configure() { }

    func clearDeepLink() {
        pendingDeepLink = nil
    }

    func requestPushPermission() async -> Bool {
        false
    }
}

actor MessagingService {
    static let shared = MessagingService()

    private init() { }

    func getOrCreateConversation(with member: User, currentUser: User) async throws -> String {
        [currentUser.id, member.id].sorted().joined(separator: "-")
    }
}
