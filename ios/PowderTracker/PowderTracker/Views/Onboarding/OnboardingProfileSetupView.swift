//
//  OnboardingProfileSetupView.swift
//  PowderTracker
//
//  Profile setup step for onboarding (avatar + display name).
//

import SwiftUI
import PhotosUI

struct OnboardingProfileSetupView: View {
    @Binding var profile: OnboardingProfile
    let authService: AuthService
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var rawImageForCropping: UIImage?
    @State private var showCropper = false
    @State private var isUploadingAvatar = false
    @State private var displayName: String = ""
    @State private var avatarError: String?
    @State private var showAvatarError = false
    @FocusState private var isNameFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: .spacingXL) {
                // Header
                VStack(spacing: .spacingS) {
                    Text("Set up your profile")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Add a photo and name so friends can find you")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, .spacingXL)

                // Avatar picker
                AvatarPickerView(
                    selectedImage: $selectedImage,
                    selectedItem: $selectedItem,
                    isUploading: isUploadingAvatar
                )
                .onChange(of: selectedItem) { _, newItem in
                    Task {
                        await loadImage(from: newItem)
                    }
                }

                // Display name field
                VStack(alignment: .leading, spacing: .spacingS) {
                    Text("Display Name")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))

                    TextField("How should we call you?", text: $displayName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .autocorrectionDisabled()
                        .focused($isNameFocused)
                        .submitLabel(.continue)
                        .onSubmit {
                            if canContinue {
                                saveAndContinue()
                            }
                        }
                }
                .padding(.horizontal, .spacingL)
            }
            .padding(.bottom, .spacingL)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) {
            // Buttons pinned to bottom
            VStack(spacing: .spacingM) {
                Button {
                    saveAndContinue()
                } label: {
                    HStack(spacing: 8) {
                        if isUploadingAvatar {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Continue")
                            .fontWeight(.semibold)
                        if !isUploadingAvatar {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        canContinue ?
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.5, blue: 0.72),
                                Color(red: 0.5, green: 0.7, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: canContinue ? .purple.opacity(0.3) : .clear, radius: 12, y: 6)
                }
                .disabled(!canContinue || isUploadingAvatar)

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            // Pre-fill with existing data if available
            displayName = profile.displayName ?? authService.userProfile?.displayName ?? ""

            // Auto-focus the text field after a short delay (lets animation finish)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
        .alert("Photo Upload Failed", isPresented: $showAvatarError) {
            Button("Try Again") {
                saveAndContinue()
            }
            Button("Skip Photo", role: .cancel) {
                // Clear the selected image and continue without it
                selectedImage = nil
                profile.displayName = displayName.trimmingCharacters(in: .whitespaces)
                onContinue()
            }
        } message: {
            Text(avatarError ?? "We couldn't upload your photo. Would you like to try again or continue without it?")
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

    // MARK: - Computed Properties

    private var canContinue: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    // Store raw image and show cropper
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

    private func saveAndContinue() {
        // Update profile with display name
        profile.displayName = displayName.trimmingCharacters(in: .whitespaces)

        // Upload avatar if selected
        if let image = selectedImage {
            isUploadingAvatar = true

            Task {
                do {
                    // Get user ID for avatar upload
                    // Prefer userProfile.authUserId (persisted profile data) over currentUser.id (Supabase session)
                    // Both should match, but profile is more reliable if session is refreshing
                    guard let userId = authService.userProfile?.authUserId ?? authService.currentUser?.id.uuidString else {
                        throw NSError(domain: "Onboarding", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
                    }

                    let avatarUrl = try await AvatarService.shared.uploadAvatar(
                        image: image,
                        userId: userId
                    )

                    await MainActor.run {
                        profile.avatarUrl = avatarUrl
                        isUploadingAvatar = false
                        onContinue()
                    }
                } catch {
                    await MainActor.run {
                        isUploadingAvatar = false
                        avatarError = "We couldn't upload your photo. Check your connection and try again."
                        showAvatarError = true
                    }
                    HapticFeedback.error.trigger()
                }
            }
        } else {
            onContinue()
        }
    }
}

#Preview {
    OnboardingProfileSetupView(
        profile: .constant(OnboardingProfile()),
        authService: AuthService.shared,
        onContinue: {},
        onSkip: {}
    )
    .background(
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
