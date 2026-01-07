import SwiftUI

struct SignupView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("🏔️")
                            .font(.system(size: 60))
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Join the Shredders community")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)

                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // Sign in with Apple
                    SignInWithAppleButton()
                        .padding(.horizontal)

                    // Divider
                    HStack {
                        VStack { Divider() }
                        Text("or")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        VStack { Divider() }
                    }
                    .padding(.horizontal)

                    // Signup form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        TextField("Display Name (optional)", text: $displayName)
                            .textContentType(.name)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        SecureField("Confirm Password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)

                        Button {
                            Task {
                                await signUp()
                            }
                        } label: {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else {
                                Text("Create Account")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(10)
                        .disabled(authService.isLoading || !isFormValid)
                    }
                    .padding(.horizontal)

                    // Password requirements
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password must:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("• Be at least 8 characters")
                            .font(.caption)
                            .foregroundStyle(password.count >= 8 ? .green : .secondary)
                        Text("• Match confirmation")
                            .font(.caption)
                            .foregroundStyle(!confirmPassword.isEmpty && password == confirmPassword ? .green : .secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        !password.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }

    private func signUp() async {
        errorMessage = nil

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            return
        }

        // Auto-generate username from email (same logic as Sign in with Apple)
        let autoUsername = email.components(separatedBy: "@").first ?? "user_\(UUID().uuidString.prefix(8))"

        do {
            try await authService.signUp(
                email: email,
                password: password,
                username: autoUsername,
                displayName: displayName.isEmpty ? nil : displayName
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SignupView()
        .environment(AuthService.shared)
}
