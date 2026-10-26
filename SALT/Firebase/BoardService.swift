import Foundation
import FirebaseFirestore

@MainActor
final class BoardService: ObservableObject {
    static let shared = BoardService()
    
    @Published var pendingApplications: [MembershipApplication] = []
    
    private var listener: ListenerRegistration?
    
    func listenPending() {
        listener?.remove()
        listener = FirebaseManager.shared.collection(.membershipApplications)
            .whereField("status", isEqualTo: "pending")
            .order(by: "submittedAt", descending: false)
            .addSnapshotListener { [weak self] snap, _ in
                self?.pendingApplications = snap?.documents.compactMap {
                    try? $0.data(as: MembershipApplication.self)
                } ?? []
            }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
    }
    
    func approve(_ app: MembershipApplication, by boardMemberId: String) async throws {
        guard let id = app.id else { return }
        
        try await FirebaseManager.shared.collection(.membershipApplications).document(id).updateData([
            "status": "approved",
            "reviewedBy": boardMemberId,
            "reviewedAt": FieldValue.serverTimestamp()
        ])
        
        // Activate user – Cloud Function also does this + email/push
        try await FirebaseManager.shared.collection(.users).document(app.userId).updateData([
            "membershipStatus": MembershipStatus.active.rawValue
        ])
    }
    
    func reject(_ app: MembershipApplication, by boardMemberId: String, notes: String) async throws {
        guard let id = app.id else { return }
        try await FirebaseManager.shared.collection(.membershipApplications).document(id).updateData([
            "status": "rejected",
            "reviewedBy": boardMemberId,
            "reviewedAt": FieldValue.serverTimestamp(),
            "notes": notes
        ])
    }
}
