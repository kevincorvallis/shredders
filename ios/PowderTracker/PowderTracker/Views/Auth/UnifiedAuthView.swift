//
//  UnifiedAuthView.swift
//  PowderTracker
//
//  Modern authentication view with glassmorphism design.
//

import SwiftUI
import AuthenticationServices

struct UnifiedAuthView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSignupMode = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false

    // Focus management
    @FocusState private var focusedField: Field?

    // Animation states
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 30
    @State private var buttonsOpacity: Double = 0

    enum Field {
        case email, password, displayName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic gradient background
                backgroundGradient
                    .ignoresSafeArea()
                
                // Decorative blurred circles
                GeometryReader { geometry in
                    Circle()
                        .fill(.pookieCyan.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .blur(radius: 60)
                        .offset(x: -50, y: geometry.size.height * 0.1)
                    
                    Circle()
                        .fill(.pookiePurple.opacity(0.3))
                        .frame(width: 250, height: 250)
                        .blur(radius: 70)
                        .offset(x: geometry.size.width - 100, y: geometry.size.height * 0.6)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacingXL) {
                        // Header section
                        headerSection
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)

                        // Sign in with Apple (primary option)
                        appleSignInSection
                            .offset(y: formOffset)
                            .opacity(formOpacity)

                        // Divider with "or"
                        orDivider
                            .offset(y: formOffset)
                            .opacity(formOpacity)

                        // Email/Password section
                        credentialsSection
                            .offset(y: formOffset)
                            .opacity(formOpacity)

                        // Error message
                        if let errorMessage = errorMessage {
                            errorBanner(message: errorMessage)
                        }

                        // Action buttons
                        actionSection
                            .offset(y: buttonsOffset)
                            .opacity(buttonsOpacity)

                        // Toggle between login/signup
                        toggleModeSection
                            .offset(y: buttonsOffset)
                            .opacity(buttonsOpacity)
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingXL)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(isSignupMode ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
            .disabled(isLoading)
            .onAppear {
                animateIn()
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.06), Color(white: 0.1), Color(white: 0.06)]
                : [Color(white: 0.96), Color(white: 0.98), Color(white: 0.94)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: .spacingM) {
            // Animated logo with glow
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.pookieCyan.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                // Icon with gradient
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pookieCyan, .pookiePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: .spacingXS) {
                Text(isSignupMode ? "Welcome to PowderTracker" : "Welcome Back")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(isSignupMode ? "Create your account to track conditions" : "Sign in to access your favorites")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, .spacingL)
    }

    // MARK: - Apple Sign In Section

    private var appleSignInSection: some View {
        VStack(spacing: .spacingS) {
            SignInWithAppleButton()
                .frame(height: 54)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

            Text("Use your Apple ID to sign in securely")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Or Divider

    private var orDivider: some View {
        HStack(spacing: .spacingM) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .secondary.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            Text("or")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, .spacingS)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.secondary.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }

    // MARK: - Credentials Section

    private var credentialsSection: some View {
        VStack(spacing: .spacingM) {
            // Email field
            GlassTextField(
                title: "Email",
                placeholder: "your@email.com",
                text: $email,
                icon: "envelope.fill",
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                autocapitalization: .never
            )
            .focused($focusedField, equals: .email)
            .submitLabel(.next)
            .onSubmit {
                if isSignupMode {
                    focusedField = .displayName
                } else {
                    focusedField = .password
                }
            }
            .accessibilityIdentifier("auth_email_field")

            // Display Name (only for signup)
            if isSignupMode {
                GlassTextField(
                    title: "Display Name",
                    placeholder: "How others see you (optional)",
                    text: $displayName,
                    icon: "person.fill",
                    textContentType: .name
                )
                .focused($focusedField, equals: .displayName)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
                .accessibilityIdentifier("auth_display_name_field")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }

            // Password field
            GlassSecureField(
                title: "Password",
                placeholder: isSignupMode ? "Create a secure password" : "Enter your password",
                text: $password,
                icon: "lock.fill",
                textContentType: isSignupMode ? .newPassword : .password
            )
            .focused($focusedField, equals: .password)
            .submitLabel(isSignupMode ? .continue : .go)
            .onSubmit {
                handleSubmit()
            }
            .accessibilityIdentifier("auth_password_field")

            // Password requirements (only for signup)
            if isSignupMode && !password.isEmpty {
                passwordRequirementsView
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSignupMode)
    }

    private var passwordRequirementsView: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("Password Requirements")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
                ForEach(Array(zip(PasswordRequirement.all.indices, PasswordRequirement.all)), id: \.0) { index, requirement in
                    HStack(spacing: 6) {
                        Image(systemName: passwordRequirementsMet[index] ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(passwordRequirementsMet[index] ? .green : .secondary)
                        Text(requirement.shortDescription)
                            .font(.caption)
                            .foregroundStyle(passwordRequirementsMet[index] ? .primary : .secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.spacingM)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall))
    }

    // MARK: - Error Banner

    private func errorBanner(message: String) -> some View {
        HStack(spacing: .spacingS) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(.spacingM)
        .background(.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusSmall)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .top)),
            removal: .opacity
        ))
    }

    // MARK: - Action Section

    private var actionSection: some View {
        VStack(spacing: .spacingM) {
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
                .padding(.spacingM)
                .background(
                    Group {
                        if isFormValid {
                            LinearGradient(
                                colors: [.pookieCyan, .pookiePurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton))
                .shadow(color: isFormValid ? .pookieCyan.opacity(0.3) : .clear, radius: 10, y: 5)
            }
            .disabled(!isFormValid || isLoading)
            .accessibilityIdentifier(isSignupMode ? "auth_create_account_button" : "auth_sign_in_button")

            // Forgot Password link (only in login mode)
            if !isSignupMode {
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.pookieCyan)
                }
                .accessibilityIdentifier("auth_forgot_password_button")
                .sheet(isPresented: $showForgotPassword) {
                    ForgotPasswordView()
                }
            }
        }
    }

    // MARK: - Toggle Mode Section

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
                    .foregroundStyle(.pookieCyan)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
        .padding(.top, .spacingS)
        .accessibilityIdentifier("auth_mode_toggle")
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

    // MARK: - Animation

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.15)) {
            formOffset = 0
            formOpacity = 1.0
        }
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25)) {
            buttonsOffset = 0
            buttonsOpacity = 1.0
        }
    }

    // MARK: - Actions

    private func handleSubmit() {
        guard isFormValid else { return }

        errorMessage = nil
        isLoading = true

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

// MARK: - Glass Text Field

private struct GlassTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
            }
            .padding(.spacingM)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusSmall)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Glass Secure Field

private struct GlassSecureField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String
    var textContentType: UITextContentType?
    
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .textContentType(textContentType)
                } else {
                    TextField(placeholder, text: $text)
                        .textContentType(textContentType)
                }
                
                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.spacingM)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusSmall))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusSmall)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview("Login") {
    UnifiedAuthView()
        .environment(AuthService.shared)
}

#Preview("Signup") {
    UnifiedAuthView()
        .environment(AuthService.shared)
}
