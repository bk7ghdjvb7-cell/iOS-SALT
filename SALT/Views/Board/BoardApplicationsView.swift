import SwiftUI

struct BoardApplicationsView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var board = BoardService.shared
    @State private var rejectNotes = ""
    @State private var appToReject: MembershipApplication?
    
    var body: some View {
        Group {
            if board.pendingApplications.isEmpty {
                ContentUnavailableView(
                    "No Pending Applications",
                    systemImage: "checkmark.seal",
                    description: Text("New membership applications will appear here for review.")
                )
            } else {
                List {
                    ForEach(board.pendingApplications) { app in
                        ApplicationCard(
                            app: app,
                            onApprove: {
                                Task {
                                    try? await board.approve(app, by: auth.currentUser?.id ?? "")
                                }
                            },
                            onReject: {
                                appToReject = app
                            }
                        )
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Board Review")
        .onAppear { board.listenPending() }
        .onDisappear { board.stopListening() }
        .alert("Reject Application", isPresented: Binding(
            get: { appToReject != nil },
            set: { if !$0 { appToReject = nil } }
        )) {
            TextField("Reason (optional)", text: $rejectNotes)
            Button("Reject", role: .destructive) {
                if let app = appToReject {
                    Task {
                        try? await board.reject(
                            app,
                            by: auth.currentUser?.id ?? "",
                            notes: rejectNotes
                        )
                    }
                }
                rejectNotes = ""
                appToReject = nil
            }
            Button("Cancel", role: .cancel) {
                rejectNotes = ""
                appToReject = nil
            }
        } message: {
            if let app = appToReject {
                Text("Reject \(app.fullName)’s application?")
            }
        }
    }
}

struct ApplicationCard: View {
    let app: MembershipApplication
    let onApprove: () -> Void
    let onReject: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.fullName)
                        .font(SaltTypography.headline)
                    if let biz = app.businessName, !biz.isEmpty {
                        Text(biz)
                            .font(SaltTypography.subheadline)
                            .foregroundStyle(Color.saltPurple)
                    }
                }
                Spacer()
                Text(app.tier)
                    .font(SaltTypography.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.saltPurple.opacity(0.12))
                    .foregroundStyle(Color.saltPurple)
                    .clipShape(Capsule())
            }
            
            Text(app.email)
                .font(SaltTypography.caption)
                .foregroundStyle(Color.saltSecondaryLabel)
            
            if !app.categories.isEmpty {
                Text(app.categories.joined(separator: " • "))
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
            
            Text(app.submittedAt, style: .date)
                .font(SaltTypography.caption)
                .foregroundStyle(Color.saltSecondaryLabel)
            
            HStack(spacing: 12) {
                Button("Approve", action: onApprove)
                    .buttonStyle(SaltPrimaryButtonStyle())
                Button("Reject", action: onReject)
                    .buttonStyle(SaltSecondaryButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}
