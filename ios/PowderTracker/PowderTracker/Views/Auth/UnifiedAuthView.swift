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
            Form {
                // Header section
                headerSection

                // Sign in with Apple (primary option)
                appleSignInSection

                // Divider
                Section {
                    HStack {
                        VStack {
                            Divider()
                        }
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                        VStack {
                            Divider()
                        }
                    }
                }
                .listRowBackground(Color.clear)

                // Email/Password section
                credentialsSection

                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                // Action buttons
                actionSection

                // Toggle between login/signup
                toggleModeSection
            }
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
        Section {
            VStack(spacing: 8) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text(isSignupMode ? "Welcome to PowderTracker" : "Welcome Back")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(isSignupMode ? "Create your account to track conditions" : "Sign in to access your favorites")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical)
        }
        .listRowBackground(Color.clear)
    }

    private var appleSignInSection: some View {
        Section {
            SignInWithAppleButton()
        } header: {
            Text("Recommended")
                .font(.caption)
                .foregroundStyle(.secondary)
        } footer: {
            Text("Use your Apple ID to sign in securely without creating a password")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var credentialsSection: some View {
        Section {
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

            // Display Name (only for signup)
            if isSignupMode {
                TextField("Display Name (Optional)", text: $displayName)
                    .textContentType(.name)
                    .focused($focusedField, equals: .displayName)
                    .submitLabel(.next)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            // Password
            SecureField("Password", text: $password)
                .textContentType(isSignupMode ? .newPassword : .password)
                .focused($focusedField, equals: .password)
                .submitLabel(isSignupMode ? .continue : .go)
                .onSubmit {
                    handleSubmit()
                }

            // Password requirements (only for signup)
            if isSignupMode && !password.isEmpty {
                passwordRequirementsView
            }
        } header: {
            Text("Email & Password")
                .font(.caption)
                .foregroundStyle(.secondary)
        } footer: {
            if isSignupMode && password.isEmpty {
                Text("Password must contain: 12+ characters, uppercase, lowercase, number, and special character")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(zip(PasswordRequirement.all.indices, PasswordRequirement.all)), id: \.0) { index, requirement in
                HStack(spacing: 8) {
                    Image(systemName: passwordRequirementsMet[index] ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(passwordRequirementsMet[index] ? .green : .secondary)
                    Text(requirement.description)
                        .font(.caption)
                        .foregroundStyle(passwordRequirementsMet[index] ? .primary : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var actionSection: some View {
        Section {
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
            }
            .disabled(!isFormValid || isLoading)

            // Forgot Password link (only in login mode)
            if !isSignupMode {
                Button {
                    showForgotPassword = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
            }
        }
        .listRowBackground(isFormValid ? Color.blue : Color.gray.opacity(0.3))
        .foregroundColor(.white)
    }

    private var toggleModeSection: some View {
        Section {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSignupMode.toggle()
                    errorMessage = nil
                    password = "" // Clear password when switching modes
                }
            } label: {
                HStack {
                    Spacer()
                    Text(isSignupMode ? "Already have an account? " : "Don't have an account? ")
                        .foregroundStyle(.secondary)
                    +
                    Text(isSignupMode ? "Sign In" : "Sign Up")
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .listRowBackground(Color.clear)
    }

    // MARK: - Password Validation

    /// Password requirement: 12+ chars, uppercase, lowercase, number, special char
    private struct PasswordRequirement: Sendable {
        let description: String
        let isMet: @Sendable (String) -> Bool

		static let all: [PasswordRequirement] = [
            PasswordRequirement(description: "At least 12 characters") { $0.count >= 12 },
            PasswordRequirement(description: "One uppercase letter") { $0.contains(where: { $0.isUppercase }) },
            PasswordRequirement(description: "One lowercase letter") { $0.contains(where: { $0.isLowercase }) },
            PasswordRequirement(description: "One number") { $0.contains(where: { $0.isNumber }) },
            PasswordRequirement(description: "One special character") { $0.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) }
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
