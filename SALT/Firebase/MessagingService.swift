import Foundation
import FirebaseFirestore

@MainActor
final class MessagingService: ObservableObject {
    static let shared = MessagingService()
    
    @Published var conversations: [Conversation] = []
    
    private var listener: ListenerRegistration?
    
    func startListening(userId: String) {
        listener?.remove()
        listener = FirebaseManager.shared.collection(.conversations)
            .whereField("participantIds", arrayContains: userId)
            .order(by: "lastMessageAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                self?.conversations = snap?.documents.compactMap { try? $0.data(as: Conversation.self) } ?? []
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    /// Finds existing 1-on-1 conversation or creates a new one
    func getOrCreateConversation(with other: User, currentUser: User) async throws -> String {
        let ids = [currentUser.id, other.id].sorted()
        
        let existing = try await FirebaseManager.shared.collection(.conversations)
            .whereField("participantIds", isEqualTo: ids)
            .limit(to: 1)
            .getDocuments()
        
        if let doc = existing.documents.first {
            return doc.documentID
        }
        
        let ref = FirebaseManager.shared.collection(.conversations).document()
        let convo = Conversation(
            id: ref.documentID,
            participantIds: ids,
            participantNames: [
                currentUser.id: currentUser.displayName,
                other.id: other.displayName
            ],
            lastMessage: "",
            lastMessageAt: Date(),
            lastSenderId: "",
            unreadCount: [currentUser.id: 0, other.id: 0]
        )
        try ref.setData(from: convo)
        return ref.documentID
    }
    
    func sendMessage(conversationId: String, text: String, from user: User) async throws {
        let msgRef = FirebaseManager.shared.collection(.messages).document()
        let message = ChatMessage(
            id: msgRef.documentID,
            conversationId: conversationId,
            senderId: user.id,
            senderName: user.displayName,
            text: text,
            createdAt: Date(),
            isRead: false
        )
        try msgRef.setData(from: message)
        
        // Conversation preview is also updated by Cloud Function onNewMessage
        try await FirebaseManager.shared.collection(.conversations)
            .document(conversationId)
            .updateData([
                "lastMessage": text,
                "lastMessageAt": FieldValue.serverTimestamp(),
                "lastSenderId": user.id
            ])
    }
    
    func listenMessages(conversationId: String, onChange: @escaping ([ChatMessage]) -> Void) -> ListenerRegistration {
        FirebaseManager.shared.collection(.messages)
            .whereField("conversationId", isEqualTo: conversationId)
            .order(by: "createdAt")
            .addSnapshotListener { snap, _ in
                let msgs = snap?.documents.compactMap { try? $0.data(as: ChatMessage.self) } ?? []
                onChange(msgs)
            }
    }
}
