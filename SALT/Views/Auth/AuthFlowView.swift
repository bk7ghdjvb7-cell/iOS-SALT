import SwiftUI

struct AuthFlowView: View {
    @State private var showMembershipApplication = false
    @State private var showCreateAccount = false
    
    var body: some View {
        NavigationStack {
            LoginView(
                showMembershipApplication: $showMembershipApplication,
                showCreateAccount: $showCreateAccount
            )
                .navigationDestination(isPresented: $showMembershipApplication) {
                    MembershipApplicationView()
                }
                .navigationDestination(isPresented: $showCreateAccount) {
                    CreateAccountView()
                }
        }
    }
}
