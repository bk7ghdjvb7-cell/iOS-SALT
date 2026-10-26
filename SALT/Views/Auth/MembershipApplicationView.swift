import SwiftUI

struct MembershipApplicationView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedMembershipType: MembershipApplicationType = .tourOperatorSolo
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var businessOrganization = ""
    @State private var email = ""
    @State private var applicantURL = ""
    @State private var phone = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var city = ""
    @State private var state = "GA"
    @State private var zipCode = ""
    @State private var websiteURL = ""
    @State private var servicesDescription = ""
    @State private var numberOfEmployees = ""
    @State private var agreedToCodeOfConduct = false
    @State private var agreedToDeclaration = false
    @State private var applicationDate = Date()
    @State private var cardNumber = ""
    @State private var nameOnCard = ""
    @State private var expirationDate = ""
    @State private var securityCode = ""
    @State private var billingZipCode = ""
    @State private var showSubmittedAlert = false

    private let states = ["AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "FL", "GA", "HI", "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN", "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH", "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA", "WV", "WI", "WY"]

    var body: some View {
        Form {
            Section("Membership Type") {
                ForEach(MembershipApplicationType.allCases) { membershipType in
                    Button {
                        selectedMembershipType = membershipType
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: selectedMembershipType == membershipType ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedMembershipType == membershipType ? Color.saltPurple : Color.saltSecondaryLabel)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(membershipType.title)
                                    .font(SaltTypography.headline)
                                    .foregroundStyle(Color.saltLabel)
                                Text(membershipType.description)
                                    .font(SaltTypography.caption)
                                    .foregroundStyle(Color.saltSecondaryLabel)
                                Text(membershipType.priceText)
                                    .font(SaltTypography.caption)
                                    .foregroundStyle(Color.saltGold)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            Section("Name") {
                TextField("First", text: $firstName)
                    .textContentType(.givenName)
                TextField("Last", text: $lastName)
                    .textContentType(.familyName)
            }

            Section("Applicant") {
                TextField("Business / Organization", text: $businessOrganization)
                    .textContentType(.organizationName)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Applicant's URL", text: $applicantURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("Phone", text: $phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
            }

            Section("Address") {
                TextField("Address Line 1", text: $addressLine1)
                    .textContentType(.streetAddressLine1)
                TextField("Address Line 2", text: $addressLine2)
                    .textContentType(.streetAddressLine2)
                TextField("City", text: $city)
                    .textContentType(.addressCity)
                Picker("State", selection: $state) {
                    ForEach(states, id: \.self) { state in
                        Text(state).tag(state)
                    }
                }
                TextField("Zip Code", text: $zipCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numbersAndPunctuation)
            }

            Section("About Your Organization") {
                TextField("Website / URL", text: $websiteURL)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                TextField("Brief Description of Services", text: $servicesDescription, axis: .vertical)
                    .lineLimit(4...8)
                TextField("Number of Employees", text: $numberOfEmployees)
                    .keyboardType(.numberPad)
            }

            Section("Agreement to Code of Conduct") {
                Link(destination: MemberDocument.codeOfConduct.url) {
                    Label("View SALT Code of Conduct", systemImage: "arrow.up.right.square")
                }

                Toggle("I agree to the SALT Code of Conduct", isOn: $agreedToCodeOfConduct)
            }

            Section("Applicant's Declaration") {
                Link(destination: MemberDocument.bylaws.url) {
                    Label("View SALT Bylaws", systemImage: "arrow.up.right.square")
                }

                Toggle("I Agree", isOn: $agreedToDeclaration)

                Text("I hereby apply for membership in the Savannah Association of Local Tours, Inc. (SALT). I affirm that the information provided in this application is true and accurate to the best of my knowledge. I agree to support the mission and objectives of SALT and comply with all bylaws, policies, and the Code of Conduct.")
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
            }

            Section("Date") {
                DatePicker("Date", selection: $applicationDate, displayedComponents: .date)
            }

            Section("Square") {
                TextField("Card", text: $cardNumber)
                    .textContentType(.creditCardNumber)
                    .keyboardType(.numberPad)
                TextField("Name on Card", text: $nameOnCard)
                    .textContentType(.name)
                TextField("MM/YY", text: $expirationDate)
                    .keyboardType(.numbersAndPunctuation)
                TextField("CVV", text: $securityCode)
                    .keyboardType(.numberPad)
                TextField("Billing Zip Code", text: $billingZipCode)
                    .textContentType(.postalCode)
                    .keyboardType(.numberPad)

                LabeledContent("Total", value: selectedMembershipType.priceText)
            }

            Section {
                Button {
                    showSubmittedAlert = true
                } label: {
                    Label("Submit", systemImage: "paperplane.fill")
                }
                .buttonStyle(SaltPrimaryButtonStyle())
                .disabled(!canSubmit)
            }
        }
        .navigationTitle("Apply for Membership")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Application Submitted", isPresented: $showSubmittedAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your membership application has been submitted for board review.")
        }
    }

    private var canSubmit: Bool {
        !firstName.isEmpty &&
        !lastName.isEmpty &&
        !businessOrganization.isEmpty &&
        email.contains("@") &&
        phone.filter(\.isNumber).count >= 10 &&
        !addressLine1.isEmpty &&
        !city.isEmpty &&
        !zipCode.isEmpty &&
        !servicesDescription.isEmpty &&
        !numberOfEmployees.isEmpty &&
        agreedToCodeOfConduct &&
        agreedToDeclaration &&
        cardNumber.filter(\.isNumber).count >= 12 &&
        !nameOnCard.isEmpty &&
        !expirationDate.isEmpty &&
        securityCode.filter(\.isNumber).count >= 3 &&
        !billingZipCode.isEmpty
    }
}

enum MembershipApplicationType: String, CaseIterable, Identifiable {
    case tourOperatorSolo
    case tourOperatorSmallTeam
    case tourOperatorLargeTeam
    case tourGuide
    case communityPartner

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tourOperatorSolo: return "Tour Operator (Solo entrepreneurs)"
        case .tourOperatorSmallTeam: return "Tour Operator (2-10 employees)"
        case .tourOperatorLargeTeam: return "Tour Operator (10+ employees)"
        case .tourGuide: return "Tour Guide"
        case .communityPartner: return "Community Partner (Non-Voting)"
        }
    }

    var description: String {
        switch self {
        case .tourOperatorSolo:
            return "For locally operated tour companies and solo operators."
        case .tourOperatorSmallTeam:
            return "For locally operated tour companies with small teams."
        case .tourOperatorLargeTeam:
            return "For locally operated tour companies with larger teams."
        case .tourGuide:
            return "For individual working guides joining on their own behalf."
        case .communityPartner:
            return "For allied organizations connected to Savannah's visitor economy."
        }
    }

    var price: Int {
        switch self {
        case .tourOperatorSolo: return 50
        case .tourOperatorSmallTeam: return 75
        case .tourOperatorLargeTeam: return 100
        case .tourGuide: return 25
        case .communityPartner: return 50
        }
    }

    var priceText: String {
        "$\(price).00 annually"
    }
}
