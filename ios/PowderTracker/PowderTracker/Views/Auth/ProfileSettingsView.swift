import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var bio = ""
    @State private var showingAccountSettings = false
    @State private var saveMessage: String?
    @State private var errorMessage: String?

    // Avatar editing states
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var rawImageForCropping: UIImage?
    @State private var showCropper = false
    @State private var isUploadingAvatar = false
    @State private var pendingAvatarUrl: String?

    var body: some View {
        NavigationStack {
            Form {
                // Profile Picture Section
                Section {
                    HStack {
                        Spacer()
                        avatarSection
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("Profile Picture")
                }

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

                // Skiing Preferences
                Section {
                    NavigationLink {
                        SkiingPreferencesView()
                    } label: {
                        HStack {
                            Label("Skiing Preferences", systemImage: "figure.skiing.downhill")
                                .foregroundStyle(.primary)

                            Spacer()

                            if let level = authService.userProfile?.experienceLevelEnum {
                                Text(level.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Preferences")
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
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
            .sheet(isPresented: $showingAccountSettings) {
                AccountSettingsView()
            }
            .fullScreenCover(isPresented: $showCropper) {
                if let rawImage = rawImageForCropping {
                    CircularImageCropper(
                        image: rawImage,
                        onCrop: { croppedImage in
                            selectedImage = croppedImage
                            showCropper = false
                            rawImageForCropping = nil
                            HapticFeedback.success.trigger()
                        },
                        onCancel: {
                            showCropper = false
                            rawImageForCropping = nil
                            selectedItem = nil
                        }
                    )
                }
            }
        }
    }

    // MARK: - Avatar Section

    @ViewBuilder
    private var avatarSection: some View {
        let size: CGFloat = 100
        let initial = String(authService.userProfile?.displayName?.first ?? authService.userProfile?.username.first ?? "?").uppercased()

        PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                // Show selected image, or current avatar, or placeholder
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } else if let avatarUrl = authService.userProfile?.avatarUrl,
                          let url = URL(string: avatarUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            ProfileAvatarPlaceholder(initial: initial, size: size)
                        case .empty:
                            ProgressView()
                        @unknown default:
                            ProfileAvatarPlaceholder(initial: initial, size: size)
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                } else {
                    ProfileAvatarPlaceholder(initial: initial, size: size)
                }

                // Camera badge
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Group {
                            if isUploadingAvatar {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                            }
                        }
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                    .offset(x: size / 2 - 16, y: size / 2 - 16)

                // Border
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: size, height: size)
            }
        }
        .disabled(isUploadingAvatar)
    }

    // MARK: - Image Loading

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    rawImageForCropping = image
                    showCropper = true
                    HapticFeedback.selection.trigger()
                }
            }
        } catch {
            #if DEBUG
            print("Failed to load image: \(error)")
            #endif
        }
    }

    // MARK: - Save Profile

    private func saveProfile() async {
        saveMessage = nil
        errorMessage = nil

        // Upload avatar if a new image was selected
        var avatarUrl: String? = nil
        if let image = selectedImage {
            isUploadingAvatar = true
            do {
                guard let userId = authService.userProfile?.authUserId ?? authService.currentUser?.id.uuidString else {
                    throw NSError(domain: "ProfileSettings", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
                }
                avatarUrl = try await AvatarService.shared.uploadAvatar(image: image, userId: userId)
            } catch {
                isUploadingAvatar = false
                errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                return
            }
            isUploadingAvatar = false
        }

        do {
            try await authService.updateProfile(
                displayName: displayName.isEmpty ? nil : displayName,
                bio: bio.isEmpty ? nil : bio,
                homeMountainId: nil,
                avatarUrl: avatarUrl
            )
            saveMessage = "Profile updated successfully"
            // Clear selected image since it's now saved
            selectedImage = nil
            selectedItem = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Avatar Placeholder Component

/// Simple placeholder view for avatars (Swift 6 concurrency safe)
private struct ProfileAvatarPlaceholder: View {
    let initial: String
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(initial)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

#Preview {
    ProfileSettingsView()
        .environment(AuthService.shared)
}
