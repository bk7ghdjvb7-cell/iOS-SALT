import Combine
import Foundation

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Uses MockData until a real backend is added to the project.
    let useMockMode = true

    private init() { }

    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 600_000_000)

        do {
            try SaltLoginGuard.shared.beginLogin(email: email)
        } catch SaltCryptoError.locked(let until) {
            errorMessage = "Too many sign-in attempts. Try again after \(until.formatted(date: .omitted, time: .shortened))."
            throw AuthError.invalidCredentials
        }

        guard email.lowercased().contains("@"), password.count >= 12 else {
            SaltLoginGuard.shared.record(email: email, succeeded: false)
            errorMessage = AuthError.invalidCredentials.localizedDescription
            throw AuthError.invalidCredentials
        }

        _ = SaltCrypto.loginProof(email: email, password: password)
        SaltLoginGuard.shared.record(email: email, succeeded: true)
        currentUser = MockData.currentUser
        isAuthenticated = true
    }

    static func isStrongPassword(_ password: String) -> Bool {
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSymbol = password.rangeOfCharacter(from: CharacterSet.alphanumerics.inverted) != nil
        return password.count >= 12 && hasUppercase && hasLowercase && hasNumber && hasSymbol
    }

    func createAccount(
        email: String,
        password: String,
        phone: String,
        isEmailVerified: Bool,
        isPhoneVerified: Bool
    ) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 700_000_000)

        guard email.lowercased().contains("@"), Self.isStrongPassword(password), phone.filter(\.isNumber).count >= 10 else {
            errorMessage = AuthError.weakCredentials.localizedDescription
            throw AuthError.weakCredentials
        }

        guard isEmailVerified, isPhoneVerified else {
            errorMessage = AuthError.verificationRequired.localizedDescription
            throw AuthError.verificationRequired
        }

        let namePart = email.split(separator: "@").first.map(String.init) ?? "Member"
        currentUser = User(
            id: UUID().uuidString,
            email: email,
            firstName: namePart.capitalized,
            lastName: "",
            businessName: nil,
            tier: .individual,
            membershipStatus: .pending,
            joinDate: Date(),
            phone: phone,
            website: nil,
            bio: nil,
            profileImageURL: nil,
            isBoardMember: false,
            categories: []
        )
        isAuthenticated = true
    }

    func signUp(
        email: String,
        password: String,
        firstName: String,
        lastName: String,
        businessName: String?,
        tier: MembershipTier,
        phone: String?,
        categories: [BusinessCategory],
        isEmailVerified: Bool,
        isPhoneVerified: Bool
    ) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 800_000_000)

        guard email.lowercased().contains("@"), Self.isStrongPassword(password) else {
            errorMessage = AuthError.weakCredentials.localizedDescription
            throw AuthError.weakCredentials
        }

        guard isEmailVerified, isPhoneVerified else {
            errorMessage = AuthError.verificationRequired.localizedDescription
            throw AuthError.verificationRequired
        }

        let newUser = User(
            id: UUID().uuidString,
            email: email,
            firstName: firstName,
            lastName: lastName,
            businessName: businessName,
            tier: tier,
            membershipStatus: .pending,
            joinDate: Date(),
            phone: phone,
            website: nil,
            bio: nil,
            profileImageURL: nil,
            isBoardMember: false,
            categories: categories
        )

        currentUser = newUser
        isAuthenticated = true
    }

    func logout() {
        currentUser = nil
        isAuthenticated = false
    }

    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        try await Task.sleep(nanoseconds: 400_000_000)

        guard email.lowercased().contains("@") else {
            errorMessage = AuthError.invalidCredentials.localizedDescription
            throw AuthError.invalidCredentials
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case weakCredentials
    case networkError
    case verificationRequired
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid email or password."
        case .weakCredentials: return "Use a valid email and a password with at least 12 characters, uppercase and lowercase letters, a number, and a symbol."
        case .networkError: return "Network error. Please try again."
        case .verificationRequired: return "Verify both email and phone before creating your account."
        case .unknown: return "Something went wrong. Please try again."
        }
    }
}
