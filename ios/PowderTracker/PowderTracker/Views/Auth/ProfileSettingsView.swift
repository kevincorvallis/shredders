import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var bio = ""
    @State private var showingSignOut = false
    @State private var saveMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Profile") {
                    TextField("Email", text: .constant(authService.currentUser?.email ?? ""))
                        .disabled(true)
                        .foregroundStyle(.secondary)

                    TextField("Username", text: .constant(authService.userProfile?.username ?? ""))
                        .disabled(true)
                        .foregroundStyle(.secondary)

                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)

                    ZStack(alignment: .topLeading) {
                        if bio.isEmpty {
                            Text("Bio")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                    }
                }

                Section {
                    Button {
                        Task {
                            await saveProfile()
                        }
                    } label: {
                        if authService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Save Changes")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(authService.isLoading)
                }

                if let saveMessage = saveMessage {
                    Section {
                        Text(saveMessage)
                            .foregroundStyle(.green)
                    }
                }

                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                Section("Account") {
                    if let profile = authService.userProfile {
                        LabeledContent("Joined", value: profile.createdAt.formatted(date: .abbreviated, time: .omitted))
                        if let lastLogin = profile.lastLoginAt {
                            LabeledContent("Last Login", value: lastLogin.formatted(date: .abbreviated, time: .omitted))
                        }
                    }

                    Button(role: .destructive) {
                        showingSignOut = true
                    } label: {
                        Text("Sign Out")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let profile = authService.userProfile {
                    displayName = profile.displayName ?? ""
                    bio = profile.bio ?? ""
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOut) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private func saveProfile() async {
        saveMessage = nil
        errorMessage = nil

        do {
            try await authService.updateProfile(
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio,
                homeMountainId: nil
            )
            saveMessage = "Profile updated successfully"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func signOut() async {
        do {
            try await authService.signOut()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    ProfileSettingsView()
        .environment(AuthService.shared)
}
