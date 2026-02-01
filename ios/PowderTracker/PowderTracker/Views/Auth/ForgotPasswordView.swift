import SwiftUI

/// View for requesting a password reset email
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.blue)

                        Text("Reset Password")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Enter your email address and we'll send you a link to reset your password.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .tint(colorScheme == .dark ? .white : .blue)
                } header: {
                    Text("Email Address")
                }

                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                Section {
                    Button {
                        Task {
                            await sendResetEmail()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid || isLoading)
                }
                .listRowBackground(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isLoading)
            .alert("Check Your Email", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("If an account with that email exists, you'll receive a password reset link shortly. Please check your inbox and spam folder.")
            }
        }
    }

    private func sendResetEmail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "\(AppConfig.apiBaseURL)/auth/forgot-password") else {
            errorMessage = "Invalid server URL"
            return
        }

        struct ForgotPasswordRequest: Encodable {
            let email: String
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(ForgotPasswordRequest(email: email))

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Network error"
                return
            }

            if httpResponse.statusCode == 429 {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let message = errorData["message"] {
                    errorMessage = message
                } else {
                    errorMessage = "Too many requests. Please try again later."
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let error = errorData["error"] {
                    errorMessage = error
                } else {
                    errorMessage = "Failed to send reset email"
                }
                return
            }

            // Always show success (even if email doesn't exist - prevent enumeration)
            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ForgotPasswordView()
}
