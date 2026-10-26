import SwiftUI

struct AboutSALTView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image("SALTLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 180)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)

                Text("Strengthening Savannah's Local Tourism")
                    .font(SaltTypography.title3)
                    .foregroundStyle(Color.saltGold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("The Savannah Association of Local Tours (SALT) was founded in 2025 by locally owned tour operators who share a deep commitment to the city we call home. Created at a pivotal moment for Savannah’s tourism industry, SALT unified local professionals to ensure that small business voices were represented while supporting thoughtful, responsible growth.")

                Text("Today, SALT works to strengthen the local tourism environment through collaboration, professional standards, and constructive civic engagement. Our members believe that a thriving visitor economy and a vibrant community go hand in hand — and that those who benefit from Savannah share a responsibility to help care for it.")

                Text("From industry coordination to hands-on initiatives like Maintaining Our Savannah Squares (M.O.S.S.) and the development of family-friendly cultural events, SALT is dedicated to supporting a city where residents, businesses, and visitors alike can flourish.")

                Text("We are proud to invest in Savannah — not just as a destination, but as a community.")
            }
            .font(SaltTypography.body)
            .foregroundStyle(Color.saltLabel)
            .lineSpacing(4)
            .padding(24)
        }
        .background(Color.saltBackground)
        .navigationTitle("About SALT")
        .navigationBarTitleDisplayMode(.inline)
    }
}
