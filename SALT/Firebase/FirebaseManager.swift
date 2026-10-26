import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseMessaging
import FirebaseStorage
import UIKit
import UserNotifications

/// Central Firebase bootstrap & shared instances.
@MainActor
final class FirebaseManager: NSObject, ObservableObject {
    static let shared = FirebaseManager()
    
    let auth = Auth.auth()
    let db = Firestore.firestore()
    let storage = Storage.storage()
    
    private(set) var isConfigured = false
    @Published var fcmToken: String?
    
    /// Deep-link / notification routing publisher
    @Published var pendingDeepLink: DeepLink?
    
    private override init() {
        super.init()
    }
    
    func configure() {
        guard !isConfigured else { return }
        
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024)
        db.settings = settings
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        
        isConfigured = true
        print("✅ Firebase configured")
    }
    
    // MARK: - Push Permission
    func requestPushPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        } catch {
            print("Push permission error: \(error)")
            return false
        }
    }
    
    // MARK: - Collections
    enum Collection: String {
        case users = "users"
        case events = "events"
        case jobs = "jobs"
        case posts = "posts"
        case resources = "resources"
        case membershipApplications = "membershipApplications"
        case rsvps = "rsvps"
        case conversations = "conversations"
        case messages = "messages"
        case payments = "payments"
    }
    
    func collection(_ name: Collection) -> CollectionReference {
        db.collection(name.rawValue)
    }
    
    // MARK: - Deep Link Handling
    func handleNotificationUserInfo(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }
        
        switch type {
        case "new_message":
            if let conversationId = userInfo["conversationId"] as? String {
                pendingDeepLink = .conversation(id: conversationId)
            }
        case "new_application", "membership_approved":
            pendingDeepLink = .boardApplications
        case "payment_success":
            pendingDeepLink = .profile
        default:
            break
        }
    }
    
    func clearDeepLink() {
        pendingDeepLink = nil
    }
}

// MARK: - DeepLink
enum DeepLink: Equatable {
    case conversation(id: String)
    case boardApplications
    case profile
    case event(id: String)
    case job(id: String)
}

// MARK: - MessagingDelegate
extension FirebaseManager: MessagingDelegate {
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Task { @MainActor in
            self.fcmToken = fcmToken
            guard let token = fcmToken,
                  let uid = Auth.auth().currentUser?.uid else { return }
            try? await Firestore.firestore().collection("fcmTokens").document(uid).setData([
                "token": token,
                "updatedAt": FieldValue.serverTimestamp()
            ], merge: true)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension FirebaseManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        await MainActor.run {
            FirebaseManager.shared.handleNotificationUserInfo(userInfo)
        }
    }
}
