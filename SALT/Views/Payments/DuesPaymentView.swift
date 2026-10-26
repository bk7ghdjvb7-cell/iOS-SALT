import SwiftUI
/*
  Stripe PaymentSheet integration.
  
  1. Add package: https://github.com/stripe/stripe-ios
     Products: StripePaymentSheet, StripePayments
  
  2. Uncomment the Stripe imports and the presentPaymentSheet body below.
  
  3. Set PaymentService.shared.stripePublishableKey and createIntentURL.
*/

// import StripePaymentSheet
// import StripePayments

struct DuesPaymentView: View {
    @EnvironmentObject var auth: AuthService
    @StateObject private var paymentService = PaymentService.shared
    
    @State private var statusMessage: String?
    @State private var isSuccess = false
    // @State private var paymentSheet: PaymentSheet?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "creditcard.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.saltGold)
            
            Text("Membership Dues")
                .font(SaltTypography.title2)
            
            if let user = auth.currentUser {
                VStack(spacing: 8) {
                    Text(user.tier.rawValue)
                        .font(SaltTypography.headline)
                    Text("$\(Int(user.tier.annualDues)) / year")
                        .font(SaltTypography.title)
                        .foregroundStyle(Color.saltGold)
                    Text("Supports advocacy, networking events, and member resources.")
                        .font(SaltTypography.footnote)
                        .foregroundStyle(Color.saltSecondaryLabel)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let statusMessage {
                Text(statusMessage)
                    .font(SaltTypography.subheadline)
                    .foregroundStyle(isSuccess ? .green : Color.saltRed)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task { await startPayment() }
            } label: {
                if paymentService.isProcessing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Text("Pay with Card")
                }
            }
            .buttonStyle(SaltGoldButtonStyle())
            .disabled(paymentService.isProcessing || auth.currentUser == nil)
            
            Text("Secured by Stripe. You will receive a receipt by email.")
                .font(SaltTypography.caption)
                .foregroundStyle(Color.saltSecondaryLabel)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding(24)
        .navigationTitle("Renew Membership")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startPayment() async {
        guard let user = auth.currentUser else { return }
        statusMessage = nil
        isSuccess = false
        
        do {
            let (_, clientSecret) = try await paymentService.prepareDuesPayment(for: user)
            
            // ---------------------------------------------------------------
            // Uncomment when StripePaymentSheet is added:
            //
            // STPAPIClient.shared.publishableKey = paymentService.stripePublishableKey
            //
            // var config = PaymentSheet.Configuration()
            // config.merchantDisplayName = "SALT – Savannah Area Local Tours"
            // config.allowsDelayedPaymentMethods = false
            //
            // let sheet = PaymentSheet(paymentIntentClientSecret: clientSecret, configuration: config)
            //
            // // Present from the top UIViewController
            // if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            //    let root = windowScene.windows.first?.rootViewController {
            //     sheet.present(from: root) { result in
            //         switch result {
            //         case .completed:
            //             statusMessage = "Payment successful! Thank you."
            //             isSuccess = true
            //         case .canceled:
            //             statusMessage = "Payment cancelled."
            //         case .failed(let error):
            //             statusMessage = error.localizedDescription
            //         }
            //     }
            // }
            // ---------------------------------------------------------------
            
            // Until Stripe SDK is added, show the client secret for debugging
            statusMessage = "PaymentIntent ready.\nAdd StripePaymentSheet package and uncomment the present code.\n\nClient secret received (\(clientSecret.prefix(20))…)"
            isSuccess = true
            
        } catch {
            statusMessage = error.localizedDescription
            isSuccess = false
        }
    }
}
