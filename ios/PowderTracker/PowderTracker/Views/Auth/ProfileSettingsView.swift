//
//  ProfileSettingsView.swift
//  PowderTracker
//
//  Modern profile editing view with glassmorphism design.
//  Follows iOS HIG 2025 best practices for settings UI.
//

import SwiftUI
import PhotosUI

struct ProfileSettingsView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName = ""
    @State private var bio = ""
    @State private var showingAccountSettings = false
    @State private var saveMessage: String?
    @State private var errorMessage: String?
    @State private var isSaving = false

    // Avatar editing states
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var rawImageForCropping: UIImage?
    @State private var showCropper = false
    @State private var isUploadingAvatar = false

    // Animation states
    @State private var headerScale: CGFloat = 0.9
    @State private var headerOpacity: Double = 0
    @State private var cardsOffset: CGFloat = 30
    @State private var cardsOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic gradient background
                backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacingXL) {
                        // Hero Profile Header
                        profileHeader
                            .scaleEffect(headerScale)
                            .opacity(headerOpacity)

                        // Profile Info Card
                        profileInfoCard
                            .offset(y: cardsOffset)
                            .opacity(cardsOpacity)

                        // Preferences Card
                        preferencesCard
                            .offset(y: cardsOffset)
                            .opacity(cardsOpacity)

                        // Account Card
                        accountCard
                            .offset(y: cardsOffset)
                            .opacity(cardsOpacity)

                        // Status Messages
                        statusMessages

                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.top, .spacingM)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await saveProfile() }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSaving || !hasChanges)
                }
            }
            .onAppear {
                loadProfile()
                animateIn()
            }
            .onChange(of: selectedItem) { _, newItem in
                Task { await loadImage(from: newItem) }
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

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(red: 0.08, green: 0.10, blue: 0.16), Color(red: 0.12, green: 0.14, blue: 0.22)]
                : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.90, green: 0.92, blue: 0.96)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: .spacingL) {
            // Avatar with glow effect
            ZStack {
                // Glow ring
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.pookieCyan.opacity(0.4),
                                Color.pookiePurple.opacity(0.2),
                                .clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 10)

                // Avatar
                avatarView
            }

            // Name and username
            VStack(spacing: 4) {
                Text(authService.userProfile?.displayName ?? "Your Name")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                if let username = authService.userProfile?.username {
                    Text("@\(username)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Quick stats
            if let profile = authService.userProfile {
                HStack(spacing: .spacingXL) {
                    if let ridingStyle = profile.ridingStyleEnum {
                        StatBadge(
                            icon: ridingStyle.icon,
                            value: ridingStyle.displayName,
                            color: ridingStyle.color
                        )
                    }

                    if let level = profile.experienceLevelEnum {
                        StatBadge(
                            icon: "figure.skiing.downhill",
                            value: level.displayName,
                            color: .pookieCyan
                        )
                    }

                    if profile.homeMountainId != nil {
                        StatBadge(
                            icon: "mountain.2.fill",
                            value: "Home Set",
                            color: .pookiePurple
                        )
                    }
                }
            }
        }
        .padding(.vertical, .spacingXL)
    }

    // MARK: - Avatar View

    private var avatarView: some View {
        let size: CGFloat = 120
        let initial = String(authService.userProfile?.displayName?.first ?? authService.userProfile?.username.first ?? "?").uppercased()
        let currentImage = selectedImage
        let avatarUrl = authService.userProfile?.avatarUrl
        let uploading = isUploadingAvatar

        return PhotosPicker(selection: $selectedItem, matching: .images) {
            ZStack {
                // Avatar image or placeholder
                Group {
                    if let image = currentImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if let avatarUrl,
                              let url = URL(string: avatarUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                AvatarPlaceholderView(initial: initial, size: size)
                            case .empty:
                                ProgressView()
                                    .frame(width: size, height: size)
                            @unknown default:
                                AvatarPlaceholderView(initial: initial, size: size)
                            }
                        }
                    } else {
                        AvatarPlaceholderView(initial: initial, size: size)
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())

                // Glass border
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: size, height: size)

                // Edit badge
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Group {
                            if uploading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                            }
                        }
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .offset(x: size / 2 - 18, y: size / 2 - 18)
            }
        }
        .disabled(uploading)
        .buttonStyle(.plain)
    }

    // MARK: - Profile Info Card

    private var profileInfoCard: some View {
        GlassCard(title: "Profile", icon: "person.fill") {
            VStack(spacing: .spacingL) {
                // Display Name Field
                ModernTextField(
                    title: "Display Name",
                    placeholder: "How others see you",
                    text: $displayName,
                    icon: "textformat"
                )

                Divider()
                    .background(Color.white.opacity(0.1))

                // Bio Field
                VStack(alignment: .leading, spacing: .spacingS) {
                    Label("Bio", systemImage: "text.quote")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)

                    ZStack(alignment: .topLeading) {
                        if bio.isEmpty {
                            Text("Tell us about yourself...")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 12)
                        }

                        TextEditor(text: $bio)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80, maxHeight: 120)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: .cornerRadiusSmall)
                                    .fill(Color(.systemBackground).opacity(0.5))
                            )
                    }

                    Text("\(bio.count)/200 characters")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }

    // MARK: - Preferences Card

    private var preferencesCard: some View {
        GlassCard(title: "Preferences", icon: "slider.horizontal.3") {
            VStack(spacing: 0) {
                NavigationLink {
                    SkiingPreferencesView()
                } label: {
                    ModernSettingsRow(
                        icon: authService.userProfile?.ridingStyleEnum?.icon ?? "figure.skiing.downhill",
                        iconColor: .pookieCyan,
                        title: "Riding Preferences",
                        subtitle: ridingPreferencesSubtitle,
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Account Card

    private var accountCard: some View {
        GlassCard(title: "Account", icon: "person.crop.circle") {
            VStack(spacing: 0) {
                Button {
                    showingAccountSettings = true
                    HapticFeedback.selection.trigger()
                } label: {
                    ModernSettingsRow(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        title: "Account Settings",
                        subtitle: "Email, password, security",
                        showChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Status Messages

    @ViewBuilder
    private var statusMessages: some View {
        if let saveMessage = saveMessage {
            StatusBanner(message: saveMessage, type: .success)
                .transition(.move(edge: .top).combined(with: .opacity))
        }

        if let errorMessage = errorMessage {
            StatusBanner(message: errorMessage, type: .error)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private var ridingPreferencesSubtitle: String {
        let profile = authService.userProfile
        var parts: [String] = []
        if let style = profile?.ridingStyleEnum {
            parts.append(style.displayName)
        }
        if let level = profile?.experienceLevelEnum {
            parts.append(level.displayName)
        }
        return parts.isEmpty ? "Not set" : parts.joined(separator: " • ")
    }

    private var hasChanges: Bool {
        let profile = authService.userProfile
        return displayName != (profile?.displayName ?? "") ||
               bio != (profile?.bio ?? "") ||
               selectedImage != nil
    }

    private func loadProfile() {
        if let profile = authService.userProfile {
            displayName = profile.displayName ?? ""
            bio = profile.bio ?? ""
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1)) {
            headerScale = 1.0
            headerOpacity = 1.0
        }

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
            cardsOffset = 0
            cardsOpacity = 1.0
        }
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
        isSaving = true

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
                isSaving = false
                withAnimation { errorMessage = "Failed to upload photo" }
                HapticFeedback.error.trigger()
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
            withAnimation { saveMessage = "Profile updated!" }
            selectedImage = nil
            selectedItem = nil
            HapticFeedback.success.trigger()

            // Auto-dismiss message
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { saveMessage = nil }
            }
        } catch {
            withAnimation { errorMessage = error.localizedDescription }
            HapticFeedback.error.trigger()
        }

        isSaving = false
    }
}

// MARK: - Supporting Components

/// Glass card container with title
private struct GlassCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Header
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            // Content card
            VStack(alignment: .leading, spacing: .spacingM) {
                content()
            }
            .padding(.spacingL)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusHero)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
    }
}

/// Modern text field with icon
private struct ModernTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textContentType(.name)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: .cornerRadiusSmall)
                        .fill(Color(.systemBackground).opacity(0.5))
                )
        }
    }
}

/// Modern settings row
private struct ModernSettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let showChevron: Bool

    var body: some View {
        HStack(spacing: .spacingM) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, .spacingS)
        .contentShape(Rectangle())
    }
}

/// Stat badge for profile header
private struct StatBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

/// Status banner for success/error messages
private struct StatusBanner: View {
    let message: String
    let type: BannerType

    enum BannerType {
        case success, error

        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: .spacingS) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .frame(maxWidth: .infinity)
        .background(type.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Avatar Placeholder View

private struct AvatarPlaceholderView: View {
    let initial: String
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.pookieCyan, .pookiePurple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay {
                Text(initial)
                    .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
    }
}

// MARK: - Preview

#Preview {
    ProfileSettingsView()
        .environment(AuthService.shared)
}
