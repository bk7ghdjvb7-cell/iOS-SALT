import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var auth: AuthService
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var selectedTab = 0
    @State private var pathMessages = NavigationPath()
    @State private var pathProfile = NavigationPath()
    @State private var showBoardFromDeepLink = false
    @State private var deepLinkConversationId: String?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView { tab in
                selectedTab = tab
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(0)
            
            DirectoryView()
                .tabItem { Label("Directory", systemImage: "person.3.fill") }
                .tag(1)
            
            EventsView()
                .tabItem { Label("Events", systemImage: "calendar") }
                .tag(2)
            
            JobsView()
                .tabItem { Label("Jobs", systemImage: "briefcase.fill") }
                .tag(3)

            ResourcesView()
                .tabItem { Label("Resources", systemImage: "book.fill") }
                .tag(4)
            
            // Messages tab
            NavigationStack(path: $pathMessages) {
                ConversationsListView()
                    .navigationDestination(for: String.self) { conversationId in
                        ChatView(conversationId: conversationId, otherName: "Chat")
                    }
            }
            .tabItem { Label("Messages", systemImage: "message.fill") }
            .tag(5)
            
            // Profile tab (Resources moved under profile or keep separate - using Profile)
            NavigationStack(path: $pathProfile) {
                ProfileView()
                    .navigationDestination(isPresented: $showBoardFromDeepLink) {
                        BoardApplicationsView()
                    }
            }
            .tabItem { Label("Profile", systemImage: "person.circle.fill") }
            .tag(6)

            NavigationStack {
                DonateView()
            }
            .tabItem { Label("Donate", systemImage: "heart.fill") }
            .tag(7)

            NavigationStack {
                MemberDocumentsView()
            }
            .tabItem { Label("Documents", systemImage: "doc.text.fill") }
            .tag(8)

            NavigationStack {
                AboutSALTView()
            }
            .tabItem { Label("About SALT", systemImage: "info.circle.fill") }
            .tag(9)
        }
        .tint(Color.saltPurple)
        .onChange(of: firebaseManager.pendingDeepLink) { _, link in
            guard let link else { return }
            handleDeepLink(link)
            firebaseManager.clearDeepLink()
        }
        .onAppear {
            // Handle any pending link from cold start
            if let link = firebaseManager.pendingDeepLink {
                handleDeepLink(link)
                firebaseManager.clearDeepLink()
            }
        }
    }
    
    private func handleDeepLink(_ link: DeepLink) {
        switch link {
        case .conversation(let id):
            selectedTab = 5
            // Small delay so tab is active before navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                pathMessages.append(id)
            }
        case .boardApplications:
            selectedTab = 6
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showBoardFromDeepLink = true
            }
        case .profile:
            selectedTab = 6
        case .event, .job:
            // Future: navigate to specific event/job
            break
        }
    }
}
