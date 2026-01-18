import SwiftUI

/// View for changing password while logged in
struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var revokeOtherSessions = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    // Password requirements (matching backend)
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
        PasswordRequirement.all.map { $0.isMet(newPassword) }
    }

    private var isNewPasswordValid: Bool {
        passwordRequirementsMet.allSatisfy { $0 }
    }

    private var isFormValid: Bool {
        !currentPassword.isEmpty &&
        isNewPasswordValid &&
        newPassword == confirmPassword
    }

    var body: some View {
        NavigationStack {
            Form {
                // Current Password
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                } header: {
                    Text("Current Password")
                } footer: {
                    Text("Enter your current password to verify your identity")
                }

                // New Password
                Section {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)

                    SecureField("Confirm New Password", text: $confirmPassword)
                        .textContentType(.newPassword)

                    // Password requirements
                    if !newPassword.isEmpty {
                        passwordRequirementsView
                    }

                    // Password match indicator
                    if !confirmPassword.isEmpty && newPassword != confirmPassword {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Passwords do not match")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("New Password")
                }

                // Options
                Section {
                    Toggle("Sign out of other devices", isOn: $revokeOtherSessions)
                } footer: {
                    Text("Recommended: Sign out all other devices after changing your password for security")
                }

                // Error message
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }

                // Submit button
                Section {
                    Button {
                        Task {
                            await changePassword()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Change Password")
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
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .disabled(isLoading)
            .alert("Password Changed", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been changed successfully.")
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

    private func changePassword() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let accessToken = KeychainHelper.getAccessToken() else {
            errorMessage = "You must be signed in to change your password"
            return
        }

        guard let url = URL(string: "\(AppConfig.apiBaseURL)/auth/change-password") else {
            errorMessage = "Invalid server URL"
            return
        }

        struct ChangePasswordRequest: Encodable {
            let currentPassword: String
            let newPassword: String
            let revokeOtherSessions: Bool
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            request.httpBody = try JSONEncoder().encode(ChangePasswordRequest(
                currentPassword: currentPassword,
                newPassword: newPassword,
                revokeOtherSessions: revokeOtherSessions
            ))

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                errorMessage = "Network error"
                return
            }

            if httpResponse.statusCode == 401 {
                // Could be either expired session or wrong current password
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let error = errorData["error"] {
                    errorMessage = error
                } else {
                    errorMessage = "Current password is incorrect"
                }
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let error = errorData["error"] {
                    errorMessage = error
                } else {
                    errorMessage = "Failed to change password"
                }
                return
            }

            showSuccess = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ChangePasswordView()
}
