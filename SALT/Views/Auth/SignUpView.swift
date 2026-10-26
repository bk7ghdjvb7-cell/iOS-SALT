import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var businessName = ""
    @State private var phone = ""
    @State private var emailVerificationCode = ""
    @State private var phoneVerificationCode = ""
    @State private var verificationCodesSent = false
    @State private var selectedTier: MembershipTier = .individual
    @State private var selectedCategories: Set<BusinessCategory> = []
    @State private var localError: String?
    @State private var currentStep = 1

    private let demoVerificationCode = "123456"
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Progress
                HStack(spacing: 8) {
                    ForEach(1...3, id: \.self) { step in
                        Capsule()
                            .fill(step <= currentStep ? Color.saltPurple : Color.saltSecondaryLabel.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.top, 8)
                
                // Step content
                Group {
                    switch currentStep {
                    case 1:
                        accountStep
                    case 2:
                        profileStep
                    default:
                        membershipStep
                    }
                }
                
                if let error = localError {
                    Text(error)
                        .font(SaltTypography.footnote)
                        .foregroundStyle(Color.saltRed)
                }
                
                // Navigation buttons
                HStack(spacing: 12) {
                    if currentStep > 1 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                        .buttonStyle(SaltSecondaryButtonStyle())
                    }
                    
                    Button(currentStep == 3 ? "Submit Application" : "Continue") {
                        if currentStep < 3 {
                            withAnimation { currentStep += 1 }
                        } else {
                            submit()
                        }
                    }
                    .buttonStyle(SaltPrimaryButtonStyle())
                    .disabled(authService.isLoading || !canProceed)
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color.saltBackground)
        .navigationTitle("Join SALT")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }
    
    // MARK: - Steps
    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create Account")
                .font(SaltTypography.title2)
            
            field(title: "Email", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
            field(title: "Phone", text: $phone, keyboard: .phonePad, contentType: .telephoneNumber)
            secureField(title: "Strong Password", text: $password)
            secureField(title: "Confirm Password", text: $confirmPassword)

            VStack(alignment: .leading, spacing: 8) {
                PasswordRuleRow(title: "At least 12 characters", isMet: password.count >= 12)
                PasswordRuleRow(title: "Uppercase and lowercase letters", isMet: hasUppercase && hasLowercase)
                PasswordRuleRow(title: "Number and symbol", isMet: hasNumber && hasSymbol)
                PasswordRuleRow(title: "Passwords match", isMet: !password.isEmpty && password == confirmPassword)
            }

            Button {
                verificationCodesSent = true
                localError = nil
            } label: {
                Label("Send Verification Codes", systemImage: "envelope.badge.shield.half.filled")
            }
            .buttonStyle(SaltSecondaryButtonStyle())
            .disabled(!canSendVerificationCodes)

            if verificationCodesSent {
                Text("Demo verification code: \(demoVerificationCode)")
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)

                field(title: "Email Verification Code", text: $emailVerificationCode, keyboard: .numberPad, contentType: .oneTimeCode)
                field(title: "Phone Verification Code", text: $phoneVerificationCode, keyboard: .numberPad, contentType: .oneTimeCode)
            }
        }
    }
    
    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Profile")
                .font(SaltTypography.title2)
            
            HStack(spacing: 12) {
                field(title: "First Name", text: $firstName, contentType: .givenName)
                field(title: "Last Name", text: $lastName, contentType: .familyName)
            }
            
            field(title: "Business Name (optional)", text: $businessName)
            
            Text("Business Categories")
                .font(SaltTypography.footnote)
                .foregroundStyle(Color.saltSecondaryLabel)
                .padding(.top, 8)
            
            FlowLayout(spacing: 8) {
                ForEach(BusinessCategory.allCases) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategories.contains(category)
                    ) {
                        if selectedCategories.contains(category) {
                            selectedCategories.remove(category)
                        } else {
                            selectedCategories.insert(category)
                        }
                    }
                }
            }
        }
    }
    
    private var membershipStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Membership Tier")
                .font(SaltTypography.title2)
            
            ForEach(MembershipTier.allCases) { tier in
                Button {
                    selectedTier = tier
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedTier == tier ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedTier == tier ? Color.saltPurple : Color.saltSecondaryLabel)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tier.rawValue)
                                .font(SaltTypography.headline)
                                .foregroundStyle(Color.saltLabel)
                            Text(tier.description)
                                .font(SaltTypography.footnote)
                                .foregroundStyle(Color.saltSecondaryLabel)
                                .multilineTextAlignment(.leading)
                            Text("$\(Int(tier.annualDues))/year")
                                .font(SaltTypography.subheadline)
                                .foregroundStyle(Color.saltGold)
                                .padding(.top, 2)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(selectedTier == tier ? Color.saltPurple.opacity(0.08) : Color.saltSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selectedTier == tier ? Color.saltPurple : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Text("Applications are reviewed by the SALT Board. You will receive confirmation once approved.")
                .font(SaltTypography.caption)
                .foregroundStyle(Color.saltSecondaryLabel)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Helpers
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return canSendVerificationCodes && isEmailVerified && isPhoneVerified
        case 2:
            return !firstName.isEmpty && !lastName.isEmpty
        default:
            return true
        }
    }

    private var canSendVerificationCodes: Bool {
        email.contains("@") && phoneDigits.count >= 10 && AuthService.isStrongPassword(password) && password == confirmPassword
    }

    private var isEmailVerified: Bool {
        verificationCodesSent && emailVerificationCode == demoVerificationCode
    }

    private var isPhoneVerified: Bool {
        verificationCodesSent && phoneVerificationCode == demoVerificationCode
    }

    private var phoneDigits: String {
        phone.filter(\.isNumber)
    }

    private var hasUppercase: Bool {
        password.rangeOfCharacter(from: .uppercaseLetters) != nil
    }

    private var hasLowercase: Bool {
        password.rangeOfCharacter(from: .lowercaseLetters) != nil
    }

    private var hasNumber: Bool {
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }

    private var hasSymbol: Bool {
        password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
    }
    
    private func submit() {
        Task {
            localError = nil
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    firstName: firstName,
                    lastName: lastName,
                    businessName: businessName.isEmpty ? nil : businessName,
                    tier: selectedTier,
                    phone: phone.isEmpty ? nil : phone,
                    categories: Array(selectedCategories),
                    isEmailVerified: isEmailVerified,
                    isPhoneVerified: isPhoneVerified
                )
            } catch {
                localError = error.localizedDescription
            }
        }
    }
    
    @ViewBuilder
    private func field(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default, contentType: UITextContentType? = nil) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SaltTypography.footnote)
                .foregroundStyle(Color.saltSecondaryLabel)
            TextField(title, text: text)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .autocapitalization(keyboard == .emailAddress ? .none : .words)
                .padding()
                .background(Color.saltSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    private func secureField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(SaltTypography.footnote)
                .foregroundStyle(Color.saltSecondaryLabel)
            SecureField(title, text: text)
                .textContentType(.newPassword)
                .padding()
                .background(Color.saltSecondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

// MARK: - Supporting Views
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SaltTypography.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.saltPurple : Color.saltSecondaryBackground)
                .foregroundStyle(isSelected ? .white : Color.saltLabel)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct PasswordRuleRow: View {
    let title: String
    let isMet: Bool

    var body: some View {
        Label {
            Text(title)
                .font(SaltTypography.caption)
        } icon: {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? .green : Color.saltSecondaryLabel)
        }
        .foregroundStyle(isMet ? Color.saltLabel : Color.saltSecondaryLabel)
    }
}

// Simple flow layout for chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(in: proposal.width ?? 0, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxWidth = max(maxWidth, x)
        }
        
        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
