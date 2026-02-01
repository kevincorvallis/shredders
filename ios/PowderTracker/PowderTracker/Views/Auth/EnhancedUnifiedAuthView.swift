//
//  EnhancedUnifiedAuthView.swift
//  PowderTracker
//
//  Enhanced authentication view with Shredders branding
//

import SwiftUI
import AuthenticationServices

/// Enhanced unified authentication view with branded design
/// Matches Supabase email template branding (#1e40af, #2563eb)
struct EnhancedUnifiedAuthView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignupMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var showSuccess = false
    @State private var animateHeader = false
    @State private var animateForm = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password, displayName
    }

    // Brand colors matching email templates
    private let primaryBlue = Color(red: 0.118, green: 0.251, blue: 0.686) // #1e40af
    private let accentBlue = Color(red: 0.145, green: 0.388, blue: 0.925) // #2563eb

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                backgroundGradient

                ScrollView {
                    VStack(spacing: 0) {
                        // Branded header with mountain logo
                        brandedHeader
                            .opacity(animateHeader ? 1 : 0)
                            .offset(y: animateHeader ? 0 : -20)

                        // Sign in with Apple
                        appleSignInSection
                            .padding(.top, 32)
                            .opacity(animateForm ? 1 : 0)
                            .offset(y: animateForm ? 0 : 20)

                        // Divider
                        dividerSection
                            .padding(.top, 24)
                            .opacity(animateForm ? 1 : 0)

                        // Credentials form
                        credentialsSection
                            .padding(.top, 24)
                            .opacity(animateForm ? 1 : 0)
                            .offset(y: animateForm ? 0 : 20)

                        // Error message
                        if let errorMessage = errorMessage {
                            errorBanner(message: errorMessage)
                                .padding(.top, 16)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Action buttons
                        actionSection
                            .padding(.top, 24)
                            .opacity(animateForm ? 1 : 0)

                        // Toggle mode
                        toggleModeSection
                            .padding(.top, 20)
                            .padding(.bottom, 40)
                            .opacity(animateForm ? 1 : 0)
                    }
                    .padding(.horizontal, 20)
                }

                // Success overlay
                if showSuccess {
                    successOverlay
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isLoading)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateHeader = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animateForm = true
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    primaryBlue.opacity(0.05),
                    accentBlue.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating orbs
            Circle()
                .fill(accentBlue.opacity(0.1))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -100, y: -200)

            Circle()
                .fill(primaryBlue.opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 150, y: 300)
        }
    }

    // MARK: - Header

    private var brandedHeader: some View {
        VStack(spacing: 16) {
            // Mountain logo with gradient
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentBlue.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 30,
                            endRadius: 70
                        )
                    )
                    .frame(width: 140, height: 140)

                // Logo container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [primaryBlue, accentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: accentBlue.opacity(0.5), radius: 16, y: 8)

                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white)
                }
            }
            .padding(.top, 40)

            // Title
            VStack(spacing: 4) {
                Text("Shredders")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [primaryBlue, accentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Your Powder Tracking Companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Subtitle
            Text(isSignupMode ? "Create your account" : "Welcome back")
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.top, 8)
        }
    }

    // MARK: - Apple Sign In

    private var appleSignInSection: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton()
                .frame(height: 50)
                .cornerRadius(.cornerRadiusButton)
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)

            Text("Quick and secure sign in")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Divider

    private var dividerSection: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)

            Text("or continue with email")
                .font(.caption)
                .foregroundStyle(.secondary)

            Rectangle()
                .fill(.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Credentials Form

    private var credentialsSection: some View {
        VStack(spacing: 16) {
            // Email field
            CustomTextField(
                icon: "envelope.fill",
                placeholder: "Email address",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                focusedField: $focusedField,
                fieldType: .email
            )

            // Display name (signup only)
            if isSignupMode {
                CustomTextField(
                    icon: "person.fill",
                    placeholder: "Display Name (Optional)",
                    text: $displayName,
                    textContentType: .name,
                    focusedField: $focusedField,
                    fieldType: .displayName
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Password field
            CustomSecureField(
                icon: "lock.fill",
                placeholder: "Password",
                text: $password,
                textContentType: isSignupMode ? .newPassword : .password,
                focusedField: $focusedField,
                fieldType: .password
            )

            // Password requirements (signup only)
            if isSignupMode && !password.isEmpty {
                passwordRequirementsView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 4)
    }

    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password requirements:")
                .font(.caption2)
                .foregroundStyle(.secondary)

            let requirements = PasswordRequirement.all
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 4) {
                ForEach(Array(requirements.enumerated()), id: \.offset) { index, requirement in
                    HStack(spacing: 4) {
                        Image(systemName: passwordRequirementsMet[index] ? "checkmark.circle.fill" : "circle")
                            .font(.caption2)
                            .foregroundStyle(passwordRequirementsMet[index] ? .green : .secondary)

                        Text(requirement.shortDescription)
                            .font(.caption2)
                            .foregroundStyle(passwordRequirementsMet[index] ? .primary : .secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Actions

    private var actionSection: some View {
        VStack(spacing: 12) {
            // Primary button
            Button {
                handleSubmit()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignupMode ? "Create Account" : "Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    isFormValid ?
                    LinearGradient(
                        colors: [primaryBlue, accentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(.cornerRadiusButton)
                .shadow(color: isFormValid ? accentBlue.opacity(0.3) : .clear, radius: 8, y: 4)
            }
            .disabled(!isFormValid || isLoading)
            .padding(.horizontal, 4)

            // Forgot password
            if !isSignupMode {
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot password?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(accentBlue)
                }
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
            }
        }
    }

    // MARK: - Toggle Mode

    private var toggleModeSection: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isSignupMode.toggle()
                errorMessage = nil
                password = ""
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignupMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundStyle(.secondary)
                Text(isSignupMode ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundStyle(accentBlue)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.1))
        .cornerRadius(.cornerRadiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 4)
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 80, height: 80)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text(isSignupMode ? "Account Created!" : "Welcome Back!")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isSignupMode ? "Check your email to verify" : "Signing you in...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(.cornerRadiusPill)
            .shadow(radius: 20)
        }
    }

    // MARK: - Password Validation

    private struct PasswordRequirement: Sendable {
        let description: String
        let shortDescription: String
        let isMet: @Sendable (String) -> Bool

        static let all: [PasswordRequirement] = [
            PasswordRequirement(description: "At least 12 characters", shortDescription: "12+ chars") { $0.count >= 12 },
            PasswordRequirement(description: "One uppercase letter", shortDescription: "Uppercase") { $0.contains(where: { $0.isUppercase }) },
            PasswordRequirement(description: "One lowercase letter", shortDescription: "Lowercase") { $0.contains(where: { $0.isLowercase }) },
            PasswordRequirement(description: "One number", shortDescription: "Number") { $0.contains(where: { $0.isNumber }) },
            PasswordRequirement(description: "One special character", shortDescription: "Special") { $0.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }) }
        ]
    }

    private var passwordRequirementsMet: [Bool] {
        PasswordRequirement.all.map { $0.isMet(password) }
    }

    private var isPasswordValid: Bool {
        passwordRequirementsMet.allSatisfy { $0 }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        (isSignupMode ? isPasswordValid : true)
    }

    // MARK: - Submit Handler

    private func handleSubmit() {
        guard isFormValid else { return }

        errorMessage = nil
        isLoading = true
        focusedField = nil

        Task {
            do {
                if isSignupMode {
                    let username = email.components(separatedBy: "@").first ?? "user"
                    try await authService.signUpViaBackend(
                        email: email,
                        password: password,
                        username: username,
                        displayName: displayName.isEmpty ? nil : displayName
                    )
                } else {
                    try await authService.signInViaBackend(email: email, password: password)
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showSuccess = true
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch let authError as AuthError {
                await MainActor.run {
                    withAnimation {
                        switch authError {
                        case .emailNotVerified:
                            errorMessage = "Please check your email and verify your account before signing in."
                        case .invalidCredentials:
                            errorMessage = "Invalid email or password. Please try again."
                        default:
                            errorMessage = authError.localizedDescription
                        }
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    withAnimation {
                        errorMessage = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Custom TextField Component

struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var focusedField: FocusState<EnhancedUnifiedAuthView.Field?>.Binding
    var fieldType: EnhancedUnifiedAuthView.Field

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            TextField(placeholder, text: $text)
                .textContentType(textContentType)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .focused(focusedField, equals: fieldType)
                .submitLabel(.next)
                .tint(colorScheme == .dark ? .white : .blue)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .stroke(focusedField.wrappedValue == fieldType ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}

struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType?
    var focusedField: FocusState<EnhancedUnifiedAuthView.Field?>.Binding
    var fieldType: EnhancedUnifiedAuthView.Field

    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            if isVisible {
                TextField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .autocapitalization(.none)
                    .focused(focusedField, equals: fieldType)
                    .tint(colorScheme == .dark ? .white : .blue)
            } else {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .focused(focusedField, equals: fieldType)
                    .tint(colorScheme == .dark ? .white : .blue)
            }

            Button {
                isVisible.toggle()
            } label: {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .stroke(focusedField.wrappedValue == fieldType ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Sign In with Apple Button

struct SignInWithAppleButton: View {
    var body: some View {
        Button {
            // Handle Apple Sign In
        } label: {
            HStack {
                Image(systemName: "applelogo")
                    .font(.title3)
                Text("Continue with Apple")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(.cornerRadiusButton)
        }
    }
}

// MARK: - Preview

#Preview("Login") {
    EnhancedUnifiedAuthView()
        .environment(AuthService.shared)
}

#Preview("Signup") {
    let view = EnhancedUnifiedAuthView()
    view
        .environment(AuthService.shared)
}
