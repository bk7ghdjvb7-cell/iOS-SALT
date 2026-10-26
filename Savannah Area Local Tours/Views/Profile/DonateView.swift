import SwiftUI

struct DonateView: View {
    @State private var selectedAmount = 50
    private let donationAmounts = [25, 50, 100, 250]
    private let donationURL = URL(string: "https://www.zeffy.com/en-US/fundraising/salt-donation")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image("SALTLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 150)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Support SALT")
                        .font(SaltTypography.title2)
                        .foregroundStyle(Color.saltPurple)
                    Text("Your donation helps support local tourism advocacy, professional standards, civic engagement, and community initiatives across Savannah.")
                        .font(SaltTypography.body)
                        .foregroundStyle(Color.saltSecondaryLabel)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Donation Amount")
                        .font(SaltTypography.headline)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                        ForEach(donationAmounts, id: \.self) { amount in
                            Button {
                                selectedAmount = amount
                            } label: {
                                Text("$\(amount)")
                                    .font(SaltTypography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(selectedAmount == amount ? Color.saltPurple : Color.saltSecondaryBackground)
                                    .foregroundStyle(selectedAmount == amount ? .white : Color.saltLabel)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Link(destination: donationURL) {
                    Label("Donate Now", systemImage: "heart.fill")
                        .font(SaltTypography.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.saltPurple)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 8)

                Text("Donations are processed securely through SALT's official Zeffy fundraiser. 100% of your donation goes to SALT.")
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }
            .padding(24)
        }
        .background(Color.saltBackground)
        .navigationTitle("Donate")
        .navigationBarTitleDisplayMode(.inline)
    }
}
