import SwiftUI

/// Separate account management view following Apple design principles
/// - Separates account actions from profile editing
/// - Clear destructive action placement
/// - Minimal, focused design
struct AccountSettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAccountConfirmation = false
    @State private var showChangePassword = false
    @State private var isDeletingAccount = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            Form {
                // Account Information (Read-only)
                accountInfoSection

                // Security Section
                securitySection

                // Danger Zone
                dangerZoneSection
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Delete Account",
                isPresented: $showDeleteAccountConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action is permanent and cannot be undone. All your data including favorites, check-ins, and photos will be permanently deleted.")
            }
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
            }
            .alert("Error", isPresented: .constant(deleteError != nil)) {
                Button("OK") { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var accountInfoSection: some View {
        Section {
            if let user = authService.currentUser {
                // Email
                LabeledContent("Email", value: user.email ?? "No email")

                // Username
                if let username = user.userMetadata["username"]?.value as? String {
                    LabeledContent("Username", value: username)
                }

                // User ID (for support)
                LabeledContent("User ID") {
                    Button {
                        UIPasteboard.general.string = user.id.uuidString
                        HapticFeedback.light.trigger()
                    } label: {
                        HStack(spacing: 4) {
                            Text(String(user.id.uuidString.prefix(8)) + "...")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Image(systemName: "doc.on.doc")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Copy User ID")
                    .accessibilityHint("Double tap to copy your user ID for support")
                }
            }
        } header: {
            Text("Account Information")
        } footer: {
            Text("This information is used to identify your account")
                .font(.caption)
        }
    }

    private var securitySection: some View {
        Section {
            Button {
                showChangePassword = true
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundStyle(.blue)
                    Text("Change Password")
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Security")
        }
    }

    private var dangerZoneSection: some View {
        Section {
            Button(role: .destructive) {
                HapticFeedback.warning.trigger()
                showDeleteAccountConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    if isDeletingAccount {
                        ProgressView()
                            .tint(.red)
                    } else {
                        Text("Delete Account")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(isDeletingAccount)
        } header: {
            Text("Danger Zone")
        } footer: {
            Text("Deleting your account is permanent and cannot be undone")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }

        guard let accessToken = KeychainHelper.getAccessToken() else {
            deleteError = "You must be signed in to delete your account"
            return
        }

        guard let url = URL(string: "\(AppConfig.apiBaseURL)/auth/delete-account") else {
            deleteError = "Invalid server URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                deleteError = "Network error"
                return
            }

            if httpResponse.statusCode == 401 {
                deleteError = "Session expired. Please sign in again"
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorData["error"] {
                    deleteError = errorMessage
                } else {
                    deleteError = "Failed to delete account"
                }
                return
            }

            // Success - clear tokens and dismiss
            KeychainHelper.clearTokens()
            try? await authService.signOut()
            dismiss()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    AccountSettingsView()
        .environment(AuthService.shared)
}
