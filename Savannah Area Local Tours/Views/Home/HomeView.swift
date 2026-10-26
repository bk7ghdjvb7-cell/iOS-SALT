import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appDataStore: AppDataStore

    let selectTab: (Int) -> Void

    @State private var showNewPost = false
    @State private var selectedPostId: String?
    @State private var postNotice = ""

    private var currentUser: User {
        authService.currentUser ?? MockData.currentUser
    }

    private var canCreatePosts: Bool {
        currentUser.membershipStatus == .active
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Welcome banner
                    VStack(alignment: .center, spacing: 8) {
                        Text("Welcome back")
                            .font(SaltTypography.subheadline)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        Text(currentUser.displayName)
                            .font(SaltTypography.title2)
                            .foregroundStyle(Color.saltLabel)
                            .multilineTextAlignment(.center)
                        
                        if !postNotice.isEmpty {
                            Text(postNotice)
                                .font(SaltTypography.subheadline)
                                .foregroundStyle(Color.saltRed)
                                .multilineTextAlignment(.center)
                        }
                        Text("Strengthening Savannah's Local Tourism.\nCommitted to Its Future.\nInvested in Savannah.")
                            .font(SaltTypography.headline)
                            .foregroundStyle(Color.saltGold)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.saltPurple.opacity(0.15), Color.saltPurple.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal)
                    
                    // Quick actions
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            QuickAction(title: "Events", icon: "calendar", color: .saltPurple) {
                                selectTab(2)
                            }
                            QuickAction(title: "Directory", icon: "person.3", color: .saltRed) {
                                selectTab(1)
                            }
                            QuickAction(title: "Jobs", icon: "briefcase", color: .saltGold) {
                                selectTab(3)
                            }
                            QuickAction(title: "Resources", icon: "book", color: .saltPurple, showsUnitedHomeIcon: true) {
                                selectTab(4)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Feed header
                    HStack {
                        Text("Community Feed")
                            .font(SaltTypography.headline)
                        Spacer()
                        if canCreatePosts {
                            Button {
                                showNewPost = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(Color.saltPurple)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if !canCreatePosts {
                        Label("Only active SALT members can post.", systemImage: "lock.fill")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                    
                    // Posts
                    ForEach(appDataStore.posts) { post in
                        FeedPostCard(post: post) {
                            // Toggle like
                            if let index = appDataStore.posts.firstIndex(where: { $0.id == post.id }) {
                                appDataStore.posts[index].isLikedByCurrentUser.toggle()
                                appDataStore.posts[index].likesCount += appDataStore.posts[index].isLikedByCurrentUser ? 1 : -1
                            }
                        } onComment: {
                            selectedPostId = post.id
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.saltBackground)
            .navigationTitle("SALT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Image("SALTLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text("SALT")
                            .font(SaltTypography.headline)
                            .foregroundStyle(Color.saltPurple)
                    }
                }
            }
            .sheet(isPresented: $showNewPost) {
                NewPostSheet(canCreatePosts: canCreatePosts) { content, attachments in
                    guard canCreatePosts else { return }

                    let newPost = FeedPost(
                        id: UUID().uuidString,
                        authorId: currentUser.id,
                        authorName: currentUser.fullName,
                        authorBusiness: currentUser.businessName,
                        authorImageURL: nil,
                        content: content,
                        imageURL: nil,
                        createdAt: Date(),
                        likesCount: 0,
                        commentsCount: 0,
                        isLikedByCurrentUser: false,
                        isAnnouncement: false,
                        isPinned: false,
                        attachments: attachments
                    )
                    do {
                        try PublicPostLimiter.consume(userId: currentUser.id)
                        appDataStore.addPost(newPost)
                        postNotice = ""
                    } catch {
                        postNotice = "Public posts are limited to 3 per hour."
                    }
                }
            }
            .navigationDestination(item: $selectedPostId) { postId in
                PostDetailView(postId: postId, currentUser: currentUser)
            }
        }
    }
}

struct QuickAction: View {
    let title: String
    let icon: String
    let color: Color
    var showsUnitedHomeIcon = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionLabel(title: title, icon: icon, color: color, showsUnitedHomeIcon: showsUnitedHomeIcon)
        }
        .buttonStyle(.plain)
    }
}

struct QuickActionLabel: View {
    let title: String
    let icon: String
    let color: Color
    var showsUnitedHomeIcon = false

    var body: some View {
        VStack(alignment: showsUnitedHomeIcon ? .leading : .center, spacing: 8) {
            HStack(spacing: showsUnitedHomeIcon ? 56 : 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 52, height: 52)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                if showsUnitedHomeIcon {
                    Image("UnitedHome")
                        .renderingMode(.original)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityLabel("United Home icon")
                }
            }
            Text(title)
                .font(SaltTypography.caption)
                .foregroundStyle(Color.saltLabel)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(width: showsUnitedHomeIcon ? 52 : nil, alignment: .center)
        }
        .contentShape(Rectangle())
    }
}

struct FeedPostCard: View {
    let post: FeedPost
    let onLike: () -> Void
    let onComment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Author row
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.saltPurple.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(post.authorName.prefix(1)))
                            .font(SaltTypography.headline)
                            .foregroundStyle(Color.saltPurple)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(post.authorName)
                            .font(SaltTypography.headline)
                        if post.isAnnouncement {
                            Text("OFFICIAL")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.saltRed)
                                .clipShape(Capsule())
                        }
                        if post.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(Color.saltGold)
                        }
                    }
                    if let business = post.authorBusiness {
                        Text(business)
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                    }
                }
                
                Spacer()
                
                Text(post.timeAgo)
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
            
            Text(post.content)
                .font(SaltTypography.body)
                .foregroundStyle(Color.saltLabel)

            if !post.attachments.isEmpty {
                FeedAttachmentGrid(attachments: post.attachments)
            }
            
            // Actions
            HStack(spacing: 24) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: post.isLikedByCurrentUser ? "heart.fill" : "heart")
                            .foregroundStyle(post.isLikedByCurrentUser ? Color.saltRed : Color.saltSecondaryLabel)
                        Text("\(post.likesCount)")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                    }
                }
                
                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right")
                            .foregroundStyle(Color.saltSecondaryLabel)
                        Text("\(post.commentsCount)")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding()
        .background(Color.saltSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct NewPostSheet: View {
    @Environment(\.dismiss) private var dismiss
    let canCreatePosts: Bool

    @State private var content = ""
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var attachments: [FeedPostAttachment] = []
    @State private var mediaError: String?
    @State private var reviewHolding = ConsentReviewHolding()
    @State private var reviewStatus = ""

    private let emojis = ["😀", "👏", "🎉", "📣", "⭐️", "❤️", "💬", "📍"]
    let onPost: (String, [FeedPostAttachment]) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if !canCreatePosts {
                    Label("Only active SALT members can post.", systemImage: "lock.fill")
                        .font(SaltTypography.subheadline)
                        .foregroundStyle(Color.saltSecondaryLabel)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.saltSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                TextEditor(text: $content)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color.saltSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .disabled(!canCreatePosts)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                content.append(emoji)
                            } label: {
                                Text(emoji)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(Color.saltSecondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .disabled(!canCreatePosts)
                        }
                    }
                }

                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 4,
                    matching: .any(of: [.images, .videos])
                ) {
                    Label("Add Images or Videos", systemImage: "photo.on.rectangle.angled")
                }
                .buttonStyle(SaltSecondaryButtonStyle())
                .disabled(!canCreatePosts)

                if let mediaError {
                    Text(mediaError)
                        .font(SaltTypography.footnote)
                        .foregroundStyle(Color.saltRed)
                }

                if !attachments.isEmpty {
                    ComposerAttachmentList(attachments: $attachments)
                    if attachments.contains(where: { reviewHolding.faces[$0.id] == true }) {
                        Button("Send faces to admin for consent review") {
                            submitConsentReviews()
                        }
                        .buttonStyle(SaltSecondaryButtonStyle())
                    }
                    if !reviewStatus.isEmpty {
                        Text(reviewStatus)
                            .font(SaltTypography.footnote)
                            .foregroundStyle(Color.saltSecondaryLabel)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { reviewHolding.discard() }
            .onChange(of: selectedItems) { _, items in
                Task {
                    await loadAttachments(from: items)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        guard canCreatePosts, canPost else { return }
                        onPost(content, attachments)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canCreatePosts || !canPost)
                }
            }
        }
    }

    private var canPost: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    private func loadAttachments(from items: [PhotosPickerItem]) async {
        mediaError = nil

        do {
            var loadedAttachments: [FeedPostAttachment] = []

            for item in items {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let isVideo = item.supportedContentTypes.contains { $0.conforms(to: .movie) || $0.conforms(to: .video) }
                if isVideo {
                    mediaError = "Videos are not uploaded. Use a still image so faces can be blurred first."
                    continue
                }
                let blurred = try FaceBlur.blurFaces(in: data)
                let attachmentId = UUID().uuidString
                reviewHolding.remember(id: attachmentId, original: data, facesFound: blurred != data)
                loadedAttachments.append(
                    FeedPostAttachment(
                        id: attachmentId,
                        type: .image,
                        data: blurred,
                        filename: item.itemIdentifier
                    )
                )
            }

            attachments = loadedAttachments
        } catch {
            reviewHolding.discard()
            attachments = []
            mediaError = "The photo was not uploaded because faces could not be scanned."
        }
    }

    private func submitConsentReviews() {
        var sent = 0
        for attachment in attachments where reviewHolding.faces[attachment.id] == true {
            if (try? reviewHolding.submit(id: attachment.id)) != nil {
                sent += 1
            }
        }
        reviewHolding.discard()
        reviewStatus = sent > 0
            ? "Encrypted review sent. The public post keeps the blurred photo."
            : "The unblurred photo was discarded."
    }
}

struct PostDetailView: View {
    @EnvironmentObject var appDataStore: AppDataStore
    let postId: String
    let currentUser: User

    @State private var draftComment = ""

    private var post: FeedPost? {
        appDataStore.posts.first { $0.id == postId }
    }

    private var comments: [Comment] {
        appDataStore.comments(for: postId)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if let post {
                        FeedPostCard(post: post) {
                            if let index = appDataStore.posts.firstIndex(where: { $0.id == post.id }) {
                                appDataStore.posts[index].isLikedByCurrentUser.toggle()
                                appDataStore.posts[index].likesCount += appDataStore.posts[index].isLikedByCurrentUser ? 1 : -1
                            }
                        } onComment: { }

                        Text("Comments")
                            .font(SaltTypography.headline)
                            .padding(.top, 8)

                        if comments.isEmpty {
                            ContentUnavailableView("No Comments Yet", systemImage: "bubble.left")
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                    } else {
                        ContentUnavailableView("Post Removed", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Add a comment", text: $draftComment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(post == nil)

                Button {
                    addComment()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(post == nil || draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .background(Color.saltBackground)
        .navigationTitle("Comments")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addComment() {
        let trimmedComment = draftComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }

        appDataStore.addComment(
            Comment(
                id: UUID().uuidString,
                postId: postId,
                authorId: currentUser.id,
                authorName: currentUser.fullName,
                content: trimmedComment,
                createdAt: Date()
            )
        )
        draftComment = ""
    }
}

struct CommentRow: View {
    let comment: Comment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(comment.authorName)
                    .font(SaltTypography.headline)
                Spacer()
                Text(comment.createdAt, style: .relative)
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }

            Text(comment.content)
                .font(SaltTypography.body)
                .foregroundStyle(Color.saltLabel)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.saltSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct FeedAttachmentGrid: View {
    let attachments: [FeedPostAttachment]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 8)], spacing: 8) {
            ForEach(attachments) { attachment in
                AttachmentPreview(attachment: attachment)
                    .frame(height: 140)
            }
        }
    }
}

struct ComposerAttachmentList: View {
    @Binding var attachments: [FeedPostAttachment]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments")
                .font(SaltTypography.footnote)
                .foregroundStyle(Color.saltSecondaryLabel)

            ForEach(attachments) { attachment in
                HStack(spacing: 12) {
                    AttachmentPreview(attachment: attachment)
                        .frame(width: 72, height: 72)

                    Text(attachment.type == .video ? "Video attached" : "Image attached")
                        .font(SaltTypography.subheadline)

                    Spacer()

                    Button {
                        attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.saltSecondaryLabel)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct AttachmentPreview: View {
    let attachment: FeedPostAttachment

    var body: some View {
        ZStack {
            if attachment.type == .image,
               let data = attachment.data,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.saltPurple.opacity(0.12)
                Image(systemName: attachment.type == .video ? "play.rectangle.fill" : "photo.fill")
                    .font(.title)
                    .foregroundStyle(Color.saltPurple)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(alignment: .bottomLeading) {
            if attachment.type == .video {
                Label("Video", systemImage: "play.fill")
                    .font(SaltTypography.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
        .clipped()
    }
}
