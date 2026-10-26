import SwiftUI
import FirebaseFirestore

struct ChatView: View {
    let conversationId: String
    let otherName: String
    
    @EnvironmentObject var auth: AuthService
    @State private var messages: [ChatMessage] = []
    @State private var text = ""
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            MessageBubble(
                                message: msg,
                                isMine: msg.senderId == auth.currentUser?.id
                            )
                            .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack(spacing: 12) {
                TextField("Message…", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color.saltSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                
                Button {
                    send()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? Color.saltSecondaryLabel
                            : Color.saltPurple
                        )
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .navigationTitle(otherName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            listener = MessagingService.shared.listenMessages(conversationId: conversationId) { msgs in
                messages = msgs
            }
        }
        .onDisappear {
            listener?.remove()
            listener = nil
        }
    }
    
    private func send() {
        guard let user = auth.currentUser else { return }
        let body = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return }
        text = ""
        Task {
            try? await MessagingService.shared.sendMessage(
                conversationId: conversationId,
                text: body,
                from: user
            )
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool
    
    var body: some View {
        HStack {
            if isMine { Spacer(minLength: 60) }
            
            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMine ? Color.saltPurple : Color.saltSecondaryBackground)
                    .foregroundStyle(isMine ? .white : Color.saltLabel)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                
                Text(message.createdAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
            
            if !isMine { Spacer(minLength: 60) }
        }
    }
}
