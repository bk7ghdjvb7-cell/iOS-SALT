import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showLogoutConfirm = false
    
    private var user: User? { authService.currentUser }
    
    var body: some View {
        List {
            // Profile header
            Section {
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.saltPurple.opacity(0.15))
                        .frame(width: 72, height: 72)
                        .overlay(
                            Text(String((user?.displayName ?? "?").prefix(1)))
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(Color.saltPurple)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user?.displayName ?? "Member")
                            .font(SaltTypography.title3)
                        Text(user?.email ?? "")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        
                        HStack(spacing: 6) {
                            Text(user?.membershipStatus.rawValue.capitalized ?? "")
                                .font(SaltTypography.caption)
                                .foregroundStyle(statusColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(statusColor.opacity(0.15))
                                .clipShape(Capsule())
                            
                            if let tier = user?.tier {
                                Text(tier == .business ? "Business" : "Individual")
                                    .font(SaltTypography.caption)
                                    .foregroundStyle(Color.saltPurple)
                            }

                            if user?.isBoardMember == true {
                                Text("Admin")
                                    .font(SaltTypography.caption)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.saltPurple)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            // Membership
            Section("Membership") {
                LabeledContent("Tier", value: user?.tier.rawValue ?? "—")
                LabeledContent("Annual Dues") {
                    Text("$\(Int(user?.tier.annualDues ?? 0))")
                        .foregroundStyle(Color.saltGold)
                }
                if let join = user?.joinDate {
                    LabeledContent("Member Since", value: join.formatted(date: .abbreviated, time: .omitted))
                }
                
                NavigationLink {
                    DuesPaymentView()
                } label: {
                    Label("Renew / Pay Dues", systemImage: "creditcard")
                }

                NavigationLink {
                    MembershipApplicationView()
                } label: {
                    Label("Apply for Membership", systemImage: "person.badge.plus")
                }
            }
            
            // Account
            Section("Account") {
                NavigationLink {
                    ConversationsListView()
                } label: {
                    Label("Messages", systemImage: "message")
                }
                
                NavigationLink {
                    ResourcesView()
                } label: {
                    Label("Resources", systemImage: "book")
                }
                
                NavigationLink {
                    Text("Edit Profile — connect to Firestore update")
                        .padding()
                } label: {
                    Label("Edit Profile", systemImage: "person")
                }
                
                NavigationLink {
                    Text("Notification settings")
                        .padding()
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
            }
            
            // Board only
            if user?.isBoardMember == true {
                Section("Admin") {
                    NavigationLink {
                        AdminDashboardView()
                    } label: {
                        Label("Admin Tools", systemImage: "person.crop.circle.badge.checkmark")
                    }

                    NavigationLink {
                        BoardApplicationsView()
                    } label: {
                        Label("Pending Applications", systemImage: "checkmark.shield")
                    }
                }
            }
            
            // Support
            Section("Support & About") {
                NavigationLink {
                    DonateView()
                } label: {
                    Label("Donate", systemImage: "heart")
                }

                NavigationLink {
                    MemberDocumentsView()
                } label: {
                    Label("Member Documents", systemImage: "doc.text")
                }

                NavigationLink {
                    AboutSALTView()
                } label: {
                    Label("About SALT", systemImage: "info.circle")
                }
            }
            
            // Logout
            Section {
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .navigationTitle("Profile")
        .confirmationDialog("Sign Out?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                authService.logout()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private var statusColor: Color {
        switch user?.membershipStatus {
        case .active: return .green
        case .pending: return Color.saltGold
        case .expired, .suspended: return Color.saltRed
        case .none: return .gray
        }
    }
}
