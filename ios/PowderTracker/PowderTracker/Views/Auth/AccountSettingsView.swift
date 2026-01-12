import SwiftUI

/// Separate account management view following Apple design principles
/// - Separates account actions from profile editing
/// - Clear destructive action placement
/// - Minimal, focused design
struct AccountSettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                // Account Information (Read-only)
                accountInfoSection

                // Account Actions
                accountActionsSection
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
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authService.signOut()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
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
                    Text(user.id.uuidString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Account Information")
        } footer: {
            Text("This information is used to identify your account")
                .font(.caption)
        }
    }

    private var accountActionsSection: some View {
        Section {
            // Sign Out button
            Button(role: .destructive) {
                showSignOutConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Text("Sign Out")
                        .fontWeight(.semibold)
                    Spacer()
                }
            }
        } footer: {
            Text("You can always sign back in with your credentials")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    AccountSettingsView()
        .environment(AuthService.shared)
}
