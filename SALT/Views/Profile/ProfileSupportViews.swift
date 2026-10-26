import SwiftUI

struct DuesPaymentView: View {
    @EnvironmentObject var authService: AuthService

    private var duesAmount: Double {
        authService.currentUser?.tier.annualDues ?? 0
    }

    var body: some View {
        Form {
            Section("Amount Due") {
                LabeledContent("Annual Dues") {
                    Text(duesAmount, format: .currency(code: "USD"))
                        .foregroundStyle(Color.saltGold)
                }
                LabeledContent("Status", value: authService.currentUser?.membershipStatus.rawValue.capitalized ?? "Unknown")
            }

            Section {
                Button {
                } label: {
                    Label("Pay Dues", systemImage: "creditcard.fill")
                }
                .buttonStyle(SaltPrimaryButtonStyle())
            }
        }
        .navigationTitle("Dues")
    }
}

struct BoardApplicationsView: View {
    private var pendingMembers: [User] {
        MockData.members.filter { $0.membershipStatus == .pending }
    }

    var body: some View {
        List {
            if pendingMembers.isEmpty {
                ContentUnavailableView(
                    "No Pending Applications",
                    systemImage: "checkmark.shield",
                    description: Text("New membership applications will appear here.")
                )
            } else {
                ForEach(pendingMembers) { member in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(member.displayName)
                            .font(SaltTypography.headline)
                        Text(member.email)
                            .font(SaltTypography.subheadline)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        Text(member.tier.rawValue)
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltPurple)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Applications")
    }
}
