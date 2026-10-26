import CoreImage
import CryptoKit
import Foundation
import Security
import SwiftUI
import UIKit
import Vision

enum SaltCSP {
    static let policy = """
    default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; \
    img-src 'self' blob: data: https://images.unsplash.com; font-src 'self'; connect-src 'self'; \
    form-action 'self'; base-uri 'self'; object-src 'none'; frame-ancestors 'self'
    """
}

enum SaltCryptoError: Error {
    case locked(until: Date)
    case blocked
    case rejected
    case invalidImage
}

/// AES-256-GCM with SHA-512. Chat keys stay on device. The server stores only ciphertext.
enum SaltCrypto {
    static func sha512Hex(_ data: Data) -> String {
        SHA512.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    static func seal(_ plaintext: Data, key: SymmetricKey) throws -> String {
        let sealed = try AES.GCM.seal(plaintext, using: key)
        let combined = sealed.combined ?? Data()
        return "enc:v1:" + combined.base64EncodedString()
    }

    static func open(_ token: String, key: SymmetricKey) throws -> Data {
        guard token.hasPrefix("enc:v1:"), let combined = Data(base64Encoded: String(token.dropFirst(7))) else {
            throw SaltCryptoError.blocked
        }
        let box = try AES.GCM.SealedBox(combined: combined)
        return try AES.GCM.open(box, using: key)
    }

    /// scrypt (N=16384, r=8, p=1). The same parameters are used on Android and the server.
    static func key(passphrase: String, salt: Data) -> SymmetricKey {
        let derived = SaltScrypt.derive(
            password: Array(passphrase.utf8),
            salt: Array(salt),
            n: 16384,
            r: 8,
            p: 1,
            dkLen: 32
        )
        return SymmetricKey(data: Data(derived))
    }

    static func proof(for passphrase: String, salt: Data) -> String {
        let code = HMAC<SHA512>.authenticationCode(for: Data(SaltCryptoProof.label.utf8), using: key(passphrase: passphrase, salt: salt))
        return Data(code).base64EncodedString()
    }

    static func loginProof(email: String, password: String) -> String {
        let salt = Array(SHA512.hash(data: Data("salt-login:\(email.lowercased())".utf8)).prefix(16))
        let derived = SaltScrypt.derive(password: Array(password.utf8), salt: salt, n: 16384, r: 8, p: 1, dkLen: 64)
        return Data(derived).base64EncodedString()
    }
}

enum SaltCryptoProof {
    static let label = "salt-key-proof-v1"
}

final class SaltLoginGuard {
    static let shared = SaltLoginGuard()
    private let defaults = UserDefaults.standard
    private init() {}

    func beginLogin(email: String) throws {
        let key = storageKey(email)
        let now = Date().timeIntervalSince1970
        let start = defaults.double(forKey: key + ".start")
        let count = defaults.integer(forKey: key + ".count")
        if start > 0, now - start < 15 * 60, count >= 5 {
            throw SaltCryptoError.locked(until: Date(timeIntervalSince1970: start + 15 * 60))
        }
    }

    func record(email: String, succeeded: Bool) {
        let key = storageKey(email)
        let now = Date().timeIntervalSince1970
        let start = defaults.double(forKey: key + ".start")
        let fresh = start == 0 || now - start >= 15 * 60
        if succeeded || fresh {
            defaults.set(succeeded ? 0 : now, forKey: key + ".start")
            defaults.set(succeeded ? 0 : 1, forKey: key + ".count")
            return
        }
        defaults.set(defaults.integer(forKey: key + ".count") + 1, forKey: key + ".count")
    }

    private func storageKey(_ email: String) -> String {
        SaltCrypto.sha512Hex(Data(email.lowercased().utf8))
    }
}

enum FaceBlur {
    /// Detects faces and returns only the blurred image. The original is not written to disk or logs.
    static func blurFaces(in imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw SaltCryptoError.invalidImage
        }
        let request = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])
        let faces = request.results ?? []
        guard !faces.isEmpty else {
            return imageData
        }
        var output = CIImage(cgImage: cgImage)
        for face in faces {
            let bounds = VNImageRectForNormalizedRect(face.boundingBox, cgImage.width, cgImage.height)
            let expanded = bounds.insetBy(dx: -12, dy: -12)
            let crop = output
                .clampedToExtent()
                .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 24])
                .cropped(to: expanded)
            output = crop.composited(over: output)
        }
        let context = CIContext()
        guard let blurred = context.createCGImage(output, from: output.extent),
              let data = UIImage(cgImage: blurred).jpegData(compressionQuality: 0.85) else {
            throw SaltCryptoError.invalidImage
        }
        return data
    }
}

struct GroupChatRecord: Identifiable, Codable {
    var id: String
    var creatorId: String
    var memberIds: [String]
    var pendingMemberIds: [String]
    var saltBase64: String
    var wrappedKey: String
    var attempts: [String: AttemptState]
    var blockedUserIds: [String]
}

struct AttemptState: Codable {
    var failures: Int
    var phase: String
    var lockedUntil: Date?
}

final class GroupChatDirectory: ObservableObject {
    static let shared = GroupChatDirectory()
    @Published private(set) var chats: [GroupChatRecord] = []
    private let url: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        url = base.appendingPathComponent("salt-group-chats.json")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        load()
    }

    func create(creatorId: String, passphrase: String) throws -> GroupChatRecord {
        let salt = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let key = SaltCrypto.key(passphrase: passphrase, salt: salt)
        let groupKey = SymmetricKey(size: .bits256)
        let wrapped = try SaltCrypto.seal(groupKey.withUnsafeBytes { Data($0) }, key: key)
        let chat = GroupChatRecord(
            id: UUID().uuidString,
            creatorId: creatorId,
            memberIds: [creatorId],
            pendingMemberIds: [],
            saltBase64: salt.base64EncodedString(),
            wrappedKey: wrapped,
            attempts: [:],
            blockedUserIds: []
        )
        chats.append(chat)
        save()
        return chat
    }

    func unlock(chatId: String, passphrase: String, userId: String) throws -> SymmetricKey {
        guard let index = chats.firstIndex(where: { $0.id == chatId }) else { throw SaltCryptoError.blocked }
        var chat = chats[index]
        if chat.blockedUserIds.contains(userId) || !chat.memberIds.contains(userId) { throw SaltCryptoError.blocked }
        var attempt = chat.attempts[userId] ?? AttemptState(failures: 0, phase: "initial", lockedUntil: nil)
        if let until = attempt.lockedUntil, until > Date() { throw SaltCryptoError.locked(until: until) }
        guard let salt = Data(base64Encoded: chat.saltBase64), !chat.wrappedKey.isEmpty else { throw SaltCryptoError.blocked }
        let key = SaltCrypto.key(passphrase: passphrase, salt: salt)
        do {
            _ = try SaltCrypto.open(chat.wrappedKey, key: key)
            chat.attempts[userId] = AttemptState(failures: 0, phase: "initial", lockedUntil: nil)
            chats[index] = chat
            save()
            return key
        } catch {
            attempt.failures += 1
            if attempt.phase == "initial" && attempt.failures >= 3 {
                attempt.phase = "after-delay"
                attempt.failures = 0
                attempt.lockedUntil = Date().addingTimeInterval(15 * 60)
            } else if attempt.phase == "after-delay" && attempt.failures >= 2 {
                chat.memberIds.removeAll { $0 == userId }
                chat.blockedUserIds.append(userId)
                if userId == chat.creatorId {
                    chat.wrappedKey = ""
                }
            }
            chat.attempts[userId] = attempt
            chats[index] = chat
            save()
            if chat.blockedUserIds.contains(userId) { throw SaltCryptoError.blocked }
            if let until = attempt.lockedUntil { throw SaltCryptoError.locked(until: until) }
            throw SaltCryptoError.rejected
        }
    }

    func requestAdd(chatId: String, memberId: String, requesterId: String) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }),
              chats[index].memberIds.contains(requesterId) else { return }
        if !chats[index].pendingMemberIds.contains(memberId) {
            chats[index].pendingMemberIds.append(memberId)
            save()
        }
    }

    func decide(chatId: String, memberId: String, actorId: String, approve: Bool) {
        guard let index = chats.firstIndex(where: { $0.id == chatId }),
              chats[index].creatorId == actorId else { return }
        chats[index].pendingMemberIds.removeAll { $0 == memberId }
        if approve, !chats[index].memberIds.contains(memberId) {
            chats[index].memberIds.append(memberId)
        }
        if !approve {
            chats[index].memberIds.removeAll { $0 == memberId }
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        chats = (try? JSONDecoder().decode([GroupChatRecord].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(chats) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}

struct GroupChatSection: View {
    let currentUserId: String
    @ObservedObject private var directory = GroupChatDirectory.shared
    @State private var passphrase = ""
    @State private var memberId = ""
    @State private var status = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Group chats")
                .font(SaltTypography.headline)
            SecureField("Encryption key", text: $passphrase)
                .textFieldStyle(.roundedBorder)
            Button("Create encrypted group") {
                guard passphrase.count >= 12 else {
                    status = "Use a key of at least 12 characters."
                    return
                }
                do {
                    _ = try directory.create(creatorId: currentUserId, passphrase: passphrase)
                    passphrase = ""
                    status = "Group created. Only this key can open it."
                } catch {
                    status = "The group could not be created."
                }
            }
            ForEach(directory.chats) { chat in
                VStack(alignment: .leading, spacing: 6) {
                    Text(chat.id.prefix(8) + "…")
                        .font(SaltTypography.subheadline)
                    Text(chat.blockedUserIds.contains(currentUserId) ? "Access blocked" : "Members: \(chat.memberIds.count)")
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltSecondaryLabel)
                    Button("Unlock") {
                        do {
                            _ = try directory.unlock(chatId: chat.id, passphrase: passphrase, userId: currentUserId)
                            status = "Unlocked on this device. Messages stay encrypted."
                        } catch SaltCryptoError.locked(let until) {
                            status = "Too many attempts. Try again after \(until.formatted(date: .omitted, time: .shortened))."
                        } catch SaltCryptoError.blocked {
                            status = "The key was removed and access to this chat is blocked."
                        } catch {
                            status = "Key rejected. After three failures there is a 15 minute delay, then two final attempts."
                        }
                    }
                    TextField("Member id", text: $memberId)
                        .textFieldStyle(.roundedBorder)
                    if chat.creatorId == currentUserId {
                        Button("Approve member") {
                            directory.decide(chatId: chat.id, memberId: memberId, actorId: currentUserId, approve: true)
                        }
                        Button("Remove member") {
                            directory.decide(chatId: chat.id, memberId: memberId, actorId: currentUserId, approve: false)
                        }
                    } else {
                        Button("Request to add member") {
                            directory.requestAdd(chatId: chat.id, memberId: memberId, requesterId: currentUserId)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            if !status.isEmpty {
                Text(status)
                    .font(SaltTypography.footnote)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
        }
        .padding(.vertical, 8)
    }
}
