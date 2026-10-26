import CryptoKit
import Foundation
import Security

/// RFC 7914 scrypt. Matches Node.js crypto.scrypt and the Android Scrypt class.
enum SaltScrypt {
    static func derive(password: [UInt8], salt: [UInt8], n: Int, r: Int, p: Int, dkLen: Int) -> [UInt8] {
        precondition(n >= 2 && n & (n - 1) == 0 && r > 0 && p > 0 && dkLen > 0)
        let mfLen = 128 * r
        var block = pbkdf2(password: password, salt: salt, iterations: 1, dkLen: p * mfLen)
        for index in 0..<p {
            romix(&block, offset: index * mfLen, n: n, r: r)
        }
        return pbkdf2(password: password, salt: block, iterations: 1, dkLen: dkLen)
    }

    private static func romix(_ block: inout [UInt8], offset: Int, n: Int, r: Int) {
        let length = 128 * r
        var x = Array(block[offset..<(offset + length)])
        var v = [UInt8](repeating: 0, count: n * length)
        for index in 0..<n {
            v.replaceSubrange((index * length)..<((index + 1) * length), with: x)
            blockMix(&x, r: r)
        }
        for _ in 0..<n {
            let j = integerify(x, r: r) & (n - 1)
            xor(&x, v, sourceOffset: j * length)
            blockMix(&x, r: r)
        }
        block.replaceSubrange(offset..<(offset + length), with: x)
    }

    private static func blockMix(_ block: inout [UInt8], r: Int) {
        let blocks = 2 * r
        var x = Array(block[((blocks - 1) * 64)..<(blocks * 64)])
        var y = [UInt8](repeating: 0, count: blocks * 64)
        for index in 0..<blocks {
            xor64(&x, block, sourceOffset: index * 64)
            salsa208(&x)
            y.replaceSubrange((index * 64)..<((index + 1) * 64), with: x)
        }
        var mixed = [UInt8](repeating: 0, count: block.count)
        for index in 0..<r {
            mixed.replaceSubrange((index * 64)..<((index + 1) * 64), with: y[(index * 2 * 64)..<((index * 2 + 1) * 64)])
        }
        for index in 0..<r {
            let start = (index + r) * 64
            mixed.replaceSubrange(start..<(start + 64), with: y[((index * 2 + 1) * 64)..<((index * 2 + 2) * 64)])
        }
        block = mixed
    }

    private static func integerify(_ block: [UInt8], r: Int) -> Int {
        let offset = (2 * r - 1) * 64
        return Int(block[offset])
            | (Int(block[offset + 1]) << 8)
            | (Int(block[offset + 2]) << 16)
            | (Int(block[offset + 3]) << 24)
    }

    private static func xor(_ target: inout [UInt8], _ source: [UInt8], sourceOffset: Int) {
        for index in 0..<target.count {
            target[index] ^= source[sourceOffset + index]
        }
    }

    private static func xor64(_ target: inout [UInt8], _ source: [UInt8], sourceOffset: Int) {
        for index in 0..<64 {
            target[index] ^= source[sourceOffset + index]
        }
    }

    private static func salsa208(_ block: inout [UInt8]) {
        var b = [UInt32](repeating: 0, count: 16)
        for index in 0..<16 {
            b[index] = UInt32(block[index * 4])
                | (UInt32(block[index * 4 + 1]) << 8)
                | (UInt32(block[index * 4 + 2]) << 16)
                | (UInt32(block[index * 4 + 3]) << 24)
        }
        var x = b
        for _ in 0..<4 {
            x[4] ^= rotl(x[0] &+ x[12], 7)
            x[8] ^= rotl(x[4] &+ x[0], 9)
            x[12] ^= rotl(x[8] &+ x[4], 13)
            x[0] ^= rotl(x[12] &+ x[8], 18)
            x[9] ^= rotl(x[5] &+ x[1], 7)
            x[13] ^= rotl(x[9] &+ x[5], 9)
            x[1] ^= rotl(x[13] &+ x[9], 13)
            x[5] ^= rotl(x[1] &+ x[13], 18)
            x[14] ^= rotl(x[10] &+ x[6], 7)
            x[2] ^= rotl(x[14] &+ x[10], 9)
            x[6] ^= rotl(x[2] &+ x[14], 13)
            x[10] ^= rotl(x[6] &+ x[2], 18)
            x[3] ^= rotl(x[15] &+ x[11], 7)
            x[7] ^= rotl(x[3] &+ x[15], 9)
            x[11] ^= rotl(x[7] &+ x[3], 13)
            x[15] ^= rotl(x[11] &+ x[7], 18)
            x[1] ^= rotl(x[0] &+ x[3], 7)
            x[2] ^= rotl(x[1] &+ x[0], 9)
            x[3] ^= rotl(x[2] &+ x[1], 13)
            x[0] ^= rotl(x[3] &+ x[2], 18)
            x[6] ^= rotl(x[5] &+ x[4], 7)
            x[7] ^= rotl(x[6] &+ x[5], 9)
            x[4] ^= rotl(x[7] &+ x[6], 13)
            x[5] ^= rotl(x[4] &+ x[7], 18)
            x[11] ^= rotl(x[10] &+ x[9], 7)
            x[8] ^= rotl(x[11] &+ x[10], 9)
            x[9] ^= rotl(x[8] &+ x[11], 13)
            x[10] ^= rotl(x[9] &+ x[8], 18)
            x[12] ^= rotl(x[15] &+ x[14], 7)
            x[13] ^= rotl(x[12] &+ x[15], 9)
            x[14] ^= rotl(x[13] &+ x[12], 13)
            x[15] ^= rotl(x[14] &+ x[13], 18)
        }
        for index in 0..<16 {
            b[index] = b[index] &+ x[index]
            block[index * 4] = UInt8(b[index] & 0xff)
            block[index * 4 + 1] = UInt8((b[index] >> 8) & 0xff)
            block[index * 4 + 2] = UInt8((b[index] >> 16) & 0xff)
            block[index * 4 + 3] = UInt8((b[index] >> 24) & 0xff)
        }
    }

    private static func rotl(_ value: UInt32, _ count: UInt32) -> UInt32 {
        (value << count) | (value >> (32 - count))
    }

    private static func pbkdf2(password: [UInt8], salt: [UInt8], iterations: Int, dkLen: Int) -> [UInt8] {
        let key = SymmetricKey(data: Data(password))
        let hashLen = 32
        let blocks = (dkLen + hashLen - 1) / hashLen
        var output: [UInt8] = []
        output.reserveCapacity(dkLen)
        for blockIndex in 1...blocks {
            var mac = HMAC<SHA256>(key: key)
            mac.update(data: Data(salt))
            var counter = [UInt8](repeating: 0, count: 4)
            counter[0] = UInt8((blockIndex >> 24) & 0xff)
            counter[1] = UInt8((blockIndex >> 16) & 0xff)
            counter[2] = UInt8((blockIndex >> 8) & 0xff)
            counter[3] = UInt8(blockIndex & 0xff)
            mac.update(data: Data(counter))
            var u = Array(mac.finalize())
            var t = u
            if iterations > 1 {
                for _ in 1..<iterations {
                    var next = HMAC<SHA256>(key: key)
                    next.update(data: Data(u))
                    u = Array(next.finalize())
                    for index in 0..<hashLen {
                        t[index] ^= u[index]
                    }
                }
            }
            let take = min(hashLen, dkLen - output.count)
            output.append(contentsOf: t.prefix(take))
        }
        return output
    }
}

enum PublicPostLimiter {
    static func consume(userId: String) throws {
        let key = "post." + SaltCrypto.sha512Hex(Data(userId.utf8))
        let defaults = UserDefaults.standard
        let now = Date().timeIntervalSince1970
        let start = defaults.double(forKey: key + ".start")
        var count = defaults.integer(forKey: key + ".count")
        if start == 0 || now - start >= 60 * 60 {
            defaults.set(now, forKey: key + ".start")
            count = 0
        }
        if count >= 3 {
            throw SaltCryptoError.locked(until: Date(timeIntervalSince1970: start + 60 * 60))
        }
        defaults.set(count + 1, forKey: key + ".count")
    }
}

/// Holds an unblurred photo only in memory, then writes an encrypted review package.
final class ConsentReviewHolding {
    private var originals: [String: Data] = [:]
    private(set) var faces: [String: Bool] = [:]

    func remember(id: String, original: Data, facesFound: Bool) {
        if facesFound {
            originals[id] = original
        }
        faces[id] = facesFound
    }

    func submit(id: String) throws -> String {
        guard let original = originals[id] else { throw SaltCryptoError.invalidImage }
        let reviewId = try ConsentReviewStore.submit(original: original)
        originals[id] = nil
        return reviewId
    }

    func discard() {
        originals.removeAll()
    }
}

enum ConsentReviewStore {
    static func submit(original: Data) throws -> String {
        let reviewId = UUID().uuidString
        let key = SymmetricKey(size: .bits256)
        let token = try SaltCrypto.seal(original, key: key)
        let keyData = key.withUnsafeBytes { Data($0) }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "org.salt.savannah.consent",
            kSecAttrAccount as String: reviewId,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw SaltCryptoError.invalidImage }
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let url = base.appendingPathComponent("consent-reviews.json")
        var rows = (try? JSONDecoder().decode([String].self, from: Data(contentsOf: url))) ?? []
        rows.append(token)
        let encoded = try JSONEncoder().encode(rows)
        try encoded.write(to: url, options: [.atomic, .completeFileProtection])
        return reviewId
    }
}

struct DirectMessage: Codable, Identifiable {
    var id: String
    var ciphertext: String
}

struct DirectChatRecord: Codable, Identifiable {
    var id: String
    var creatorId: String
    var saltBase64: String
    var wrappedKey: String
    var attempts: [String: AttemptState]
    var blockedUserIds: [String]
    var messages: [DirectMessage]
}

final class DirectChatDirectory: ObservableObject {
    static let shared = DirectChatDirectory()
    @Published private(set) var chats: [DirectChatRecord] = []
    private let url: URL

    private init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        url = base.appendingPathComponent("salt-direct-chats.json")
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        load()
    }

    func establish(conversationId: String, creatorId: String, passphrase: String) throws {
        guard chats.firstIndex(where: { $0.id == conversationId }) == nil else { return }
        guard passphrase.count >= 12 else { throw SaltCryptoError.rejected }
        let salt = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let key = SaltCrypto.key(passphrase: passphrase, salt: salt)
        let privateKey = SymmetricKey(size: .bits256)
        let wrapped = try SaltCrypto.seal(privateKey.withUnsafeBytes { Data($0) }, key: key)
        chats.append(DirectChatRecord(
            id: conversationId,
            creatorId: creatorId,
            saltBase64: salt.base64EncodedString(),
            wrappedKey: wrapped,
            attempts: [:],
            blockedUserIds: [],
            messages: []
        ))
        save()
    }

    func unlock(conversationId: String, passphrase: String, userId: String) throws -> SymmetricKey {
        guard let index = chats.firstIndex(where: { $0.id == conversationId }) else { throw SaltCryptoError.rejected }
        var chat = chats[index]
        if chat.blockedUserIds.contains(userId) { throw SaltCryptoError.blocked }
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

    func messages(for conversationId: String) -> [DirectMessage] {
        chats.first { $0.id == conversationId }?.messages ?? []
    }

    func send(conversationId: String, plaintext: String, key: SymmetricKey) throws {
        guard let index = chats.firstIndex(where: { $0.id == conversationId }) else { throw SaltCryptoError.blocked }
        let token = try SaltCrypto.seal(Data(plaintext.utf8), key: key)
        chats[index].messages.append(DirectMessage(id: UUID().uuidString, ciphertext: token))
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: url) else { return }
        chats = (try? JSONDecoder().decode([DirectChatRecord].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(chats) else { return }
        try? data.write(to: url, options: [.atomic, .completeFileProtection])
    }
}
