import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @Binding var showMembershipApplication: Bool
    @Binding var showCreateAccount: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showResetAlert = false
    @State private var localError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image("SALTLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .padding(.top, 48)
                    
                    Text("SALT")
                        .font(SaltTypography.largeTitle)
                        .foregroundStyle(Color.saltPurple)
                    
                    Text("Savannah Area Local Tours")
                        .font(SaltTypography.subheadline)
                        .foregroundStyle(Color.saltSecondaryLabel)
                    
                    Text("Strengthening Savannah's Local Tourism.\nCommitted to Its Future.\nInvested in Savannah.")
                        .font(SaltTypography.headline)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .foregroundStyle(Color.saltGold)
                        .padding(.top, 4)
                        .padding(.horizontal, 28)
                }
                .padding(.bottom, 40)
                
                // Form
                VStack(spacing: 16) {
                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email")
                            .font(SaltTypography.footnote)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        TextField("you@business.com", text: $email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                            .background(Color.saltSecondaryBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Password")
                            .font(SaltTypography.footnote)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("Password", text: $password)
                                } else {
                                    SecureField("Password", text: $password)
                                }
                            }
                            .textContentType(.password)
                            
                            Button {
                                showPassword.toggle()
                            } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color.saltSecondaryLabel)
                            }
                        }
                        .padding()
                        .background(Color.saltSecondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    
                    if let error = localError ?? authService.errorMessage {
                        Text(error)
                            .font(SaltTypography.footnote)
                            .foregroundStyle(Color.saltRed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // Login button
                    Button {
                        Task {
                            localError = nil
                            do {
                                try await authService.login(email: email, password: password)
                            } catch {
                                localError = error.localizedDescription
                            }
                        }
                    } label: {
                        if authService.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Sign In")
                        }
                    }
                    .buttonStyle(SaltPrimaryButtonStyle())
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                    .padding(.top, 8)
                    
                    // Forgot password
                    Button("Forgot Password?") {
                        showResetAlert = true
                    }
                    .font(SaltTypography.subheadline)
                    .foregroundStyle(Color.saltPurple)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.saltSecondaryLabel.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(SaltTypography.caption)
                            .foregroundStyle(Color.saltSecondaryLabel)
                        Rectangle()
                            .fill(Color.saltSecondaryLabel.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    
                    // Sign up
                    Button {
                        showMembershipApplication = true
                    } label: {
                        Text("Apply for Membership")
                    }
                    .buttonStyle(SaltSecondaryButtonStyle())

                    Button {
                        showCreateAccount = true
                    } label: {
                        Text("Create an Account")
                    }
                    .font(SaltTypography.subheadline)
                    .foregroundStyle(Color.saltPurple)
                }
                .padding(.horizontal, 24)
                
                // Demo hint
                Text("Demo: demo@salt.savannah / SavannahTour1")
                    .font(SaltTypography.caption)
                    .foregroundStyle(Color.saltSecondaryLabel)
                    .padding(.top, 32)
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.saltBackground)
        .alert("Reset Password", isPresented: $showResetAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Password reset link will be sent to your email (demo mode).")
        }
    }
}
