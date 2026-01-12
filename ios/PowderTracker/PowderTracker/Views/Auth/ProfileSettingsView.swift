import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var bio = ""
    @State private var showingAccountSettings = false
    @State private var saveMessage: String?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)

                    ZStack(alignment: .topLeading) {
                        if bio.isEmpty {
                            Text("Bio (Optional)")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                        }
                        TextEditor(text: $bio)
                            .frame(minHeight: 100)
                    }
                } header: {
                    Text("Profile")
                } footer: {
                    Text("Your display name and bio are visible to other users")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
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

                // Link to Account Settings
                Section {
                    Button {
                        showingAccountSettings = true
                    } label: {
                        HStack {
                            Label("Account Settings", systemImage: "person.crop.circle")
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
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
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
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
}

#Preview {
    ProfileSettingsView()
        .environment(AuthService.shared)
}
