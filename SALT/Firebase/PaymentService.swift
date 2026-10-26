import Foundation
import FirebaseFirestore

/// Handles membership dues via Stripe PaymentIntents.
/// Requires:
/// 1. Cloud Function `createDuesPaymentIntent` deployed
/// 2. Stripe iOS SDK (https://github.com/stripe/stripe-ios) added via SPM
/// 3. Publishable key set in Info.plist or here
@MainActor
final class PaymentService: ObservableObject {
    static let shared = PaymentService()
    
    /// Replace with your Cloud Function URL after deploy
    var createIntentURL = URL(string: "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/createDuesPaymentIntent")!
    
    /// Stripe publishable key (pk_test_... or pk_live_...)
    var stripePublishableKey = "pk_test_REPLACE_ME"
    
    @Published var isProcessing = false
    @Published var lastError: String?
    
    private init() {}
    
    // MARK: - Create local payment record + request PaymentIntent
    
    struct PaymentIntentResponse: Decodable {
        let clientSecret: String
        let paymentIntentId: String
    }
    
    /// Creates a Firestore payment doc, then asks Cloud Function for a Stripe clientSecret.
    func prepareDuesPayment(for user: User) async throws -> (paymentDocId: String, clientSecret: String) {
        isProcessing = true
        lastError = nil
        defer { isProcessing = false }
        
        let year = Calendar.current.component(.year, from: Date())
        let amount = user.tier.annualDues
        
        // 1. Create payment record
        let ref = FirebaseManager.shared.collection(.payments).document()
        let payment = MembershipPayment(
            id: ref.documentID,
            userId: user.id,
            amount: amount,
            tier: user.tier.rawValue,
            year: year,
            status: "pending",
            stripePaymentIntentId: nil,
            createdAt: Date(),
            paidAt: nil
        )
        try ref.setData(from: payment)
        
        // 2. Request PaymentIntent from Cloud Function
        var request = URLRequest(url: createIntentURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Optionally attach Firebase ID token for auth
        if let token = try? await FirebaseManager.shared.auth.currentUser?.getIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = [
            "userId": user.id,
            "tier": user.tier.rawValue,
            "amount": amount,
            "paymentDocId": ref.documentID
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw PaymentError.serverError
        }
        
        let decoded = try JSONDecoder().decode(PaymentIntentResponse.self, from: data)
        return (ref.documentID, decoded.clientSecret)
    }
}

enum PaymentError: LocalizedError {
    case serverError
    case cancelled
    case failed(String)
    
    var errorDescription: String? {
        switch self {
        case .serverError: return "Could not start payment. Please try again."
        case .cancelled: return "Payment cancelled."
        case .failed(let msg): return msg
        }
    }
}
