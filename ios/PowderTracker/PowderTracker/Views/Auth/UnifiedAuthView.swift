import SwiftUI
import AuthenticationServices

/// Unified authentication view following Apple design principles
/// - Single screen for both login and signup
/// - Progressive disclosure (signup fields appear when needed)
/// - Native iOS Form patterns
/// - Minimal, clean design
struct UnifiedAuthView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignupMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false

    // Focus management
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, displayName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    headerSection

                    // Sign in with Apple (primary option)
                    appleSignInSection

                    // Divider with "or"
                    HStack {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    // Email/Password section
                    credentialsSection

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                            .multilineTextAlignment(.center)
                    }

                    // Action buttons
                    actionSection

                    // Toggle between login/signup
                    toggleModeSection
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(isSignupMode ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isLoading)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(.blue)

            Text(isSignupMode ? "Welcome to PowderTracker" : "Welcome Back")
                .font(.title3)
                .fontWeight(.semibold)

            Text(isSignupMode ? "Create your account to track conditions" : "Sign in to access your favorites")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal)
    }

    private var appleSignInSection: some View {
        VStack(spacing: 8) {
            SignInWithAppleButton()
                .padding(.horizontal)

            Text("Use your Apple ID to sign in securely")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var credentialsSection: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Email
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit {
                        if isSignupMode {
                            focusedField = .displayName
                        } else {
                            focusedField = .password
                        }
                    }
                    .padding()

                Divider().padding(.leading)

                // Display Name (only for signup)
                if isSignupMode {
                    TextField("Display Name (Optional)", text: $displayName)
                        .textContentType(.name)
                        .focused($focusedField, equals: .displayName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                        .padding()

                    Divider().padding(.leading)
                }

                // Password
                SecureField("Password", text: $password)
                    .textContentType(isSignupMode ? .newPassword : .password)
                    .focused($focusedField, equals: .password)
                    .submitLabel(isSignupMode ? .continue : .go)
                    .onSubmit {
                        handleSubmit()
                    }
                    .padding()

                // Password requirements (only for signup, compact inline)
                if isSignupMode && !password.isEmpty {
                    Divider().padding(.leading)
                    passwordRequirementsView
                        .padding()
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(.cornerRadiusSmall)
            .padding(.horizontal)
        }
    }

    private var passwordRequirementsView: some View {
        // Compact 2-column grid for password requirements
        let columns = [GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
            ForEach(Array(zip(PasswordRequirement.all.indices, PasswordRequirement.all)), id: \.0) { index, requirement in
                HStack(spacing: 4) {
                    Image(systemName: passwordRequirementsMet[index] ? "checkmark.circle.fill" : "circle")
                        .font(.caption2)
                        .foregroundStyle(passwordRequirementsMet[index] ? .green : .secondary)
                    Text(requirement.shortDescription)
                        .font(.caption2)
                        .foregroundStyle(passwordRequirementsMet[index] ? .primary : .secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var actionSection: some View {
        VStack(spacing: 12) {
            Button {
                handleSubmit()
            } label: {
                HStack {
                    Spacer()
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignupMode ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding()
                .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(.cornerRadiusSmall)
            }
            .disabled(!isFormValid || isLoading)
            .padding(.horizontal)

            // Forgot Password link (only in login mode)
            if !isSignupMode {
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
            }
        }
    }

    private var toggleModeSection: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.3)) {
                isSignupMode.toggle()
                errorMessage = nil
                password = "" // Clear password when switching modes
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignupMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundStyle(.secondary)
                Text(isSignupMode ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Password Validation

    /// Password requirement: 12+ chars, uppercase, lowercase, number, special char
    private struct PasswordRequirement: Sendable {
        let description: String
        let shortDescription: String
        let isMet: @Sendable (String) -> Bool

        static let all: [PasswordRequirement] = [
            PasswordRequirement(description: "At least 12 characters", shortDescription: "12+ chars") { $0.count >= 12 },
            PasswordRequirement(description: "One uppercase letter", shortDescription: "Uppercase") { $0.contains(where: { $0.isUppercase }) },
            PasswordRequirement(description: "One lowercase letter", shortDescription: "Lowercase") { $0.contains(where: { $0.isLowercase }) },
            PasswordRequirement(description: "One number", shortDescription: "Number") { $0.contains(where: { $0.isNumber }) },
            PasswordRequirement(description: "One special character", shortDescription: "Special char") { $0.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) }
        ]
    }

    private var passwordRequirementsMet: [Bool] {
        PasswordRequirement.all.map { $0.isMet(password) }
    }

    private var isPasswordValid: Bool {
        passwordRequirementsMet.allSatisfy { $0 }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        (isSignupMode ? isPasswordValid : true)
    }

    // MARK: - Actions

    private func handleSubmit() {
        guard isFormValid else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isSignupMode {
                    // Generate username from email (part before @)
                    let username = email.components(separatedBy: "@").first ?? "user"
                    // Use backend API for signup
                    try await authService.signUpViaBackend(
                        email: email,
                        password: password,
                        username: username,
                        displayName: displayName.isEmpty ? nil : displayName
                    )
                } else {
                    // Use backend API for login
                    try await authService.signInViaBackend(email: email, password: password)
                }

                await MainActor.run {
                    dismiss()
                }
            } catch let authError as AuthError {
                await MainActor.run {
                    switch authError {
                    case .emailNotVerified:
                        errorMessage = "Please check your email and verify your account before signing in."
                    case .invalidCredentials:
                        errorMessage = "Invalid email or password. Please try again."
                    default:
                        errorMessage = authError.localizedDescription
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Login") {
    UnifiedAuthView()
        .environment(AuthService.shared)
}

#Preview("Signup") {
    let view = UnifiedAuthView()
    view
        .environment(AuthService.shared)
        .onAppear {
            // Note: Can't set _isSignupMode directly in preview
            // This preview shows the initial state - toggle to see signup mode
        }
}
