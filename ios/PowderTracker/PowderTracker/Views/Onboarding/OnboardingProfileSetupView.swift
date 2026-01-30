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
    @State private var isUploadingAvatar = false
    @State private var displayName: String = ""

    var body: some View {
        VStack(spacing: .spacingXL) {
            // Header
            VStack(spacing: .spacingS) {
                Text("Set up your profile")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Add a photo and name so friends can find you")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, .spacingXL)

            Spacer()

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
                    .foregroundStyle(.secondary)

                TextField("How should we call you?", text: $displayName)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusButton)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, .spacingL)

            Spacer()

            // Buttons
            VStack(spacing: .spacingM) {
                Button {
                    saveAndContinue()
                } label: {
                    HStack {
                        if isUploadingAvatar {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("Continue")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canContinue ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                    .cornerRadius(.cornerRadiusButton)
                }
                .disabled(!canContinue || isUploadingAvatar)

                Button {
                    onSkip()
                } label: {
                    Text("Skip for now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.bottom, .spacingXL)
        }
        .onAppear {
            // Pre-fill with existing data if available
            displayName = profile.displayName ?? authService.userProfile?.displayName ?? ""
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
                    selectedImage = image
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
                    guard let userId = authService.currentUser?.id.uuidString ?? authService.userProfile?.authUserId else {
                        throw NSError(domain: "Onboarding", code: -1, userInfo: nil)
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
                        // Continue anyway, avatar upload failed
                        onContinue()
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
