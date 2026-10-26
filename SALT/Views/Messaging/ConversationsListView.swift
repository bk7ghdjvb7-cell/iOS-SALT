import SwiftUI

struct ConversationsListView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var service = MessagingService.shared
    
    var body: some View {
        Group {
            if service.conversations.isEmpty {
                ContentUnavailableView(
                    "No Messages Yet",
                    systemImage: "message",
                    description: Text("Start a conversation from a member’s profile in the Directory.")
                )
            } else {
                List(service.conversations) { convo in
                    NavigationLink {
                        if let uid = auth.currentUser?.id,
                           let other = convo.otherParticipant(currentUid: uid) {
                            ChatView(
                                conversationId: convo.id ?? "",
                                otherName: other.name
                            )
                        }
                    } label: {
                        ConversationRow(convo: convo, currentUid: auth.currentUser?.id ?? "")
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Messages")
        .onAppear {
            if let uid = auth.currentUser?.id {
                service.startListening(userId: uid)
            }
        }
        .onDisappear {
            // Keep listening while app is open; stop only on logout if desired
        }
    }
}

struct ConversationRow: View {
    let convo: Conversation
    let currentUid: String
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.saltPurple.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String((convo.otherParticipant(currentUid: currentUid)?.name ?? "?").prefix(1)))
                        .font(SaltTypography.headline)
                        .foregroundStyle(Color.saltPurple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(convo.otherParticipant(currentUid: currentUid)?.name ?? "Member")
                    .font(SaltTypography.headline)
                Text(convo.lastMessage.isEmpty ? "No messages yet" : convo.lastMessage)
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(convo.lastMessageAt, style: .time)
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
                
                let unread = convo.unreadCount[currentUid] ?? 0
                if unread > 0 {
                    Text("\(unread)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.saltRed)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}
