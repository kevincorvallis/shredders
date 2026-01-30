//
//  OnboardingAboutYouView.swift
//  PowderTracker
//
//  About You step for onboarding (bio, experience level, terrain preferences).
//

import SwiftUI

struct OnboardingAboutYouView: View {
    @Binding var profile: OnboardingProfile
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var bio: String = ""
    private let bioMaxLength = 150

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                // Header
                VStack(spacing: .spacingS) {
                    Text("Tell us about you")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Help us personalize your experience")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, .spacingXL)

                // Bio
                VStack(alignment: .leading, spacing: .spacingS) {
                    HStack {
                        Text("Bio")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(bio.count)/\(bioMaxLength)")
                            .font(.caption)
                            .foregroundStyle(bio.count > bioMaxLength ? .red : .secondary)
                    }

                    TextField("Share a bit about yourself...", text: $bio, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(3...5)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusButton)
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
                        .padding(.horizontal, .spacingL)

                    Text("Select all that apply")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

                Spacer(minLength: .spacingXXL)

                // Buttons
                VStack(spacing: .spacingM) {
                    Button {
                        saveAndContinue()
                    } label: {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .cornerRadius(.cornerRadiusButton)
                    }

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
