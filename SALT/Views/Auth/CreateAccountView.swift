import SwiftUI

struct CreateAccountView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var emailVerificationCode = ""
    @State private var phoneVerificationCode = ""
    @State private var verificationCodesSent = false
    @State private var localError: String?

    private let demoVerificationCode = "123456"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create Account")
                    .font(SaltTypography.title2)

                authField(title: "Email", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                authField(title: "Phone", text: $phone, keyboard: .phonePad, contentType: .telephoneNumber)
                authSecureField(title: "Strong Password", text: $password)
                authSecureField(title: "Confirm Password", text: $confirmPassword)

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

                    authField(title: "Email Verification Code", text: $emailVerificationCode, keyboard: .numberPad, contentType: .oneTimeCode)
                    authField(title: "Phone Verification Code", text: $phoneVerificationCode, keyboard: .numberPad, contentType: .oneTimeCode)
                }

                if let error = localError ?? authService.errorMessage {
                    Text(error)
                        .font(SaltTypography.footnote)
                        .foregroundStyle(Color.saltRed)
                }

                Button {
                    createAccount()
                } label: {
                    if authService.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Create Account")
                    }
                }
                .buttonStyle(SaltPrimaryButtonStyle())
                .disabled(authService.isLoading || !canCreateAccount)
                .padding(.top, 8)
            }
            .padding(24)
        }
        .background(Color.saltBackground)
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var canSendVerificationCodes: Bool {
        email.contains("@") && phoneDigits.count >= 10 && AuthService.isStrongPassword(password) && password == confirmPassword
    }

    private var canCreateAccount: Bool {
        canSendVerificationCodes && isEmailVerified && isPhoneVerified
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

    private func createAccount() {
        Task {
            localError = nil
            do {
                try await authService.createAccount(
                    email: email,
                    password: password,
                    phone: phone,
                    isEmailVerified: isEmailVerified,
                    isPhoneVerified: isPhoneVerified
                )
            } catch {
                localError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func authField(title: String, text: Binding<String>, keyboard: UIKeyboardType = .default, contentType: UITextContentType? = nil) -> some View {
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

    private func authSecureField(title: String, text: Binding<String>) -> some View {
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
