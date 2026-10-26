import SwiftUI

struct DirectoryView: View {
    @State private var searchText = ""
    @State private var selectedCategory: BusinessCategory? = nil
    @State private var members = MockData.members
    
    var filteredMembers: [User] {
        members.filter { member in
            let matchesSearch = searchText.isEmpty ||
                member.displayName.localizedCaseInsensitiveContains(searchText) ||
                member.fullName.localizedCaseInsensitiveContains(searchText) ||
                (member.bio?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesCategory = selectedCategory == nil || member.categories.contains(selectedCategory!)
            
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(BusinessCategory.allCases) { category in
                            FilterChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                
                if filteredMembers.isEmpty {
                    ContentUnavailableView(
                        "No Members Found",
                        systemImage: "person.3",
                        description: Text("Try adjusting your search or filters.")
                    )
                } else {
                    List {
                        ForEach(filteredMembers) { member in
                            NavigationLink(value: member) {
                                MemberRow(member: member)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color.saltBackground)
            .navigationTitle("Member Directory")
            .searchable(text: $searchText, prompt: "Search members or businesses")
            .navigationDestination(for: User.self) { member in
                MemberDetailView(member: member)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SaltTypography.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.saltPurple : Color.saltSecondaryBackground)
                .foregroundStyle(isSelected ? .white : Color.saltLabel)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct MemberRow: View {
    let member: User
    
    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.saltPurple.opacity(0.15))
                .frame(width: 52, height: 52)
                .overlay(
                    Text(String(member.displayName.prefix(1)))
                        .font(SaltTypography.title3)
                        .foregroundStyle(Color.saltPurple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(member.displayName)
                        .font(SaltTypography.headline)
                        .foregroundStyle(Color.saltLabel)
                    if member.isBoardMember {
                        Text("BOARD")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.saltGold)
                            .clipShape(Capsule())
                    }
                }
                
                Text(member.categories.map(\.rawValue).joined(separator: " • "))
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    .lineLimit(1)
                
                if let bio = member.bio {
                    Text(bio)
                        .font(SaltTypography.footnote)
                        .foregroundStyle(Color.saltSecondaryLabel)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct MemberDetailView: View {
    let member: User
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.saltPurple.opacity(0.15))
                        .frame(width: 96, height: 96)
                        .overlay(
                            Text(String(member.displayName.prefix(1)))
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(Color.saltPurple)
                        )
                    
                    Text(member.displayName)
                        .font(SaltTypography.title2)
                    
                    Text(member.fullName)
                        .font(SaltTypography.subheadline)
                        .foregroundStyle(Color.saltSecondaryLabel)
                    
                    if member.isBoardMember {
                        Label("Board of Directors", systemImage: "star.fill")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltGold)
                    }
                    
                    Text(member.tier.rawValue)
                        .font(SaltTypography.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.saltPurple.opacity(0.12))
                        .foregroundStyle(Color.saltPurple)
                        .clipShape(Capsule())
                }
                .padding(.top)
                
                // Bio
                if let bio = member.bio {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About")
                            .font(SaltTypography.headline)
                        Text(bio)
                            .font(SaltTypography.body)
                            .foregroundStyle(Color.saltSecondaryLabel)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .saltCard()
                    .padding(.horizontal)
                }
                
                // Contact
                VStack(alignment: .leading, spacing: 12) {
                    Text("Contact")
                        .font(SaltTypography.headline)
                    
                    if let phone = member.phone {
                        Label(phone, systemImage: "phone.fill")
                            .font(SaltTypography.body)
                    }
                    if let website = member.website {
                        Link(destination: URL(string: website)!) {
                            Label(website.replacingOccurrences(of: "https://", with: ""), systemImage: "globe")
                                .font(SaltTypography.body)
                                .foregroundStyle(Color.saltPurple)
                        }
                    }
                    Label(member.email, systemImage: "envelope.fill")
                        .font(SaltTypography.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .saltCard()
                .padding(.horizontal)
                
                // Categories
                VStack(alignment: .leading, spacing: 12) {
                    Text("Categories")
                        .font(SaltTypography.headline)
                    FlowLayout(spacing: 8) {
                        ForEach(member.categories) { cat in
                            Text(cat.rawValue)
                                .font(SaltTypography.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.saltSecondaryBackground)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .saltCard()
                .padding(.horizontal)
                
                // Message member
                Button {
                    Task {
                        guard let me = AuthService.shared.currentUser else { return }
                        do {
                            let convoId = try await MessagingService.shared.getOrCreateConversation(with: member, currentUser: me)
                            // Deep link into messages tab
                            FirebaseManager.shared.pendingDeepLink = .conversation(id: convoId)
                        } catch {
                            print("Failed to start conversation: \(error)")
                        }
                    }
                } label: {
                    Label("Message Member", systemImage: "message.fill")
                }
                .buttonStyle(SaltPrimaryButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .background(Color.saltBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
