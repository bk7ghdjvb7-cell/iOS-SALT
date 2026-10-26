import CryptoKit
import SwiftUI

struct Conversation: Identifiable, Hashable {
    let id: String
    let member: User
    let lastMessage: String
    let updatedAt: Date
}

struct ConversationsListView: View {
    private var conversations: [Conversation] {
        MockData.members
            .filter { $0.id != AuthService.shared.currentUser?.id }
            .map { member in
                Conversation(
                    id: [AuthService.shared.currentUser?.id ?? "current", member.id].sorted().joined(separator: "-"),
                    member: member,
                    lastMessage: "Start a conversation with \(member.displayName).",
                    updatedAt: member.joinDate
                )
            }
    }

    var body: some View {
        List {
            Section {
                GroupChatSection(currentUserId: AuthService.shared.currentUser?.id ?? "current")
            }
            Section {
                conversationRows
            }
        }
        .navigationTitle("Messages")
    }

    private var conversationRows: some View {
        ForEach(conversations) { conversation in
            NavigationLink {
                ChatView(conversationId: conversation.id, otherName: conversation.member.displayName)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conversation.member.displayName)
                        .font(SaltTypography.headline)
                    Text(conversation.lastMessage)
                        .font(SaltTypography.subheadline)
                        .foregroundStyle(Color.saltSecondaryLabel)
                        .lineLimit(2)
                }
                .padding(.vertical, 4)
            }
        }
    }
}

struct ChatView: View {
    let conversationId: String
    let otherName: String
    @State private var draftMessage = ""
    @State private var passphrase = ""
    @State private var unlockedKey: SymmetricKey?
    @State private var status = "Enter the key from the person who started this chat."
    @ObservedObject private var directory = DirectChatDirectory.shared

    private var userId: String { AuthService.shared.currentUser?.id ?? "current" }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(directory.messages(for: conversationId)) { message in
                        Text(display(message))
                            .font(SaltTypography.body)
                            .padding(12)
                            .background(Color.saltSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }

            Divider()

            VStack(spacing: 8) {
                SecureField("Encryption key", text: $passphrase)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button("Unlock") { unlock() }
                    Spacer()
                    Text(status)
                        .font(SaltTypography.caption)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }
                HStack(spacing: 8) {
                    TextField("Message", text: $draftMessage, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button {
                        sendMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(unlockedKey == nil || draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func display(_ message: DirectMessage) -> String {
        guard let unlockedKey, let data = try? SaltCrypto.open(message.ciphertext, key: unlockedKey) else {
            return "Encrypted message"
        }
        return String(decoding: data, as: UTF8.self)
    }

    private func unlock() {
        do {
            try directory.establish(conversationId: conversationId, creatorId: userId, passphrase: passphrase)
            unlockedKey = try directory.unlock(conversationId: conversationId, passphrase: passphrase, userId: userId)
            status = "Unlocked on this device."
        } catch SaltCryptoError.locked(let until) {
            unlockedKey = nil
            status = "Too many attempts. Try again after \(until.formatted(date: .omitted, time: .shortened))."
        } catch SaltCryptoError.blocked {
            unlockedKey = nil
            status = "The key was removed and access is blocked."
        } catch {
            unlockedKey = nil
            status = "Key rejected. After three failures there is a 15 minute delay, then two final attempts."
        }
    }

    private func sendMessage() {
        let trimmedMessage = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty, let unlockedKey else { return }
        try? directory.send(conversationId: conversationId, plaintext: trimmedMessage, key: unlockedKey)
        draftMessage = ""
    }
}
