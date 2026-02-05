//
//  OnboardingAboutYouView.swift
//  PowderTracker
//
//  About You step for onboarding (bio, experience level, terrain preferences).
//

import SwiftUI

struct OnboardingAboutYouView: View {
    @Binding var profile: OnboardingProfile
    let authService: AuthService
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var bio: String = ""
    private let bioMaxLength = 150

    @FocusState private var isBioFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                // Header
                VStack(spacing: .spacingS) {
                    Text("Tell us about you")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text("Help us personalize your experience")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(.top, .spacingXL)

                // Riding Style - First question!
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("I ride on...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, .spacingL)

                    HStack(spacing: .spacingM) {
                        ForEach(RidingStyle.allCases) { style in
                            RidingStyleButton(
                                style: style,
                                isSelected: profile.ridingStyle == style,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        profile.ridingStyle = style
                                    }
                                    HapticFeedback.selection.trigger()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, .spacingL)
                }

                // Bio
                VStack(alignment: .leading, spacing: .spacingS) {
                    HStack {
                        Text("Bio")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
                        Spacer()
                        Text("\(bio.count)/\(bioMaxLength)")
                            .font(.caption)
                            .foregroundStyle(bio.count > bioMaxLength ? .red : .white.opacity(0.5))
                    }

                    TextField("Share a bit about yourself...", text: $bio, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .focused($isBioFocused)
                        .submitLabel(.done)
                        .onChange(of: bio) { _, newValue in
                            if newValue.count > bioMaxLength {
                                bio = String(newValue.prefix(bioMaxLength))
                            }
                        }
                }
                .padding(.horizontal, .spacingL)

                // Experience Level
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Skiing Experience")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, .spacingL)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacingM) {
                            ForEach(ExperienceLevel.allCases) { level in
                                ExperienceLevelButton(
                                    level: level,
                                    isSelected: profile.experienceLevel == level,
                                    action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            profile.experienceLevel = level
                                        }
                                        HapticFeedback.selection.trigger()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, .spacingL)
                    }
                }

                // Preferred Terrain
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Favorite Terrain")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, .spacingL)

                    Text("Select all that apply")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, .spacingL)

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ],
                        spacing: .spacingM
                    ) {
                        ForEach(TerrainType.allCases) { terrain in
                            TerrainToggleButton(
                                terrain: terrain,
                                isSelected: profile.preferredTerrain.contains(terrain),
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        toggleTerrain(terrain)
                                    }
                                    HapticFeedback.selection.trigger()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, .spacingL)
                }

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
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.5, blue: 0.72),
                                Color(red: 0.5, green: 0.7, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .purple.opacity(0.3), radius: 12, y: 6)
                }

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
            bio = profile.bio ?? ""
        }
    }

    // MARK: - Actions

    private func toggleTerrain(_ terrain: TerrainType) {
        if let index = profile.preferredTerrain.firstIndex(of: terrain) {
            profile.preferredTerrain.remove(at: index)
        } else {
            profile.preferredTerrain.append(terrain)
        }
    }

    private func saveAndContinue() {
        profile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : bio.trimmingCharacters(in: .whitespacesAndNewlines)
        onContinue()
    }
}

#Preview {
    OnboardingAboutYouView(
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
