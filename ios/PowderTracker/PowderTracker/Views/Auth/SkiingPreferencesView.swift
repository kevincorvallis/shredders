//
//  SkiingPreferencesView.swift
//  PowderTracker
//
//  View for editing skiing preferences (from profile settings).
//

import SwiftUI

struct SkiingPreferencesView: View {
    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var ridingStyle: RidingStyle?
    @State private var experienceLevel: ExperienceLevel?
    @State private var preferredTerrain: [TerrainType] = []
    @State private var seasonPassType: SeasonPassType?
    @State private var homeMountainId: String?
    @State private var showMountainPicker = false
    @State private var isSaving = false
    @State private var saveMessage: String?

    private var mountains: [Mountain] {
        MountainService.shared.allMountains
    }

    private var selectedMountain: Mountain? {
        guard let id = homeMountainId else { return nil }
        return mountains.first { $0.id == id }
    }

    var body: some View {
        Form {
            // Riding Style
            Section {
                ForEach(RidingStyle.allCases) { style in
                    Button {
                        ridingStyle = style
                        HapticFeedback.selection.trigger()
                    } label: {
                        HStack {
                            Image(systemName: style.icon)
                                .foregroundStyle(style.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(style.displayName)
                                    .foregroundStyle(.primary)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if ridingStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("I Ride On...")
            }

            // Experience Level
            Section {
                ForEach(ExperienceLevel.allCases) { level in
                    Button {
                        experienceLevel = level
                        HapticFeedback.selection.trigger()
                    } label: {
                        HStack {
                            Image(systemName: level.icon)
                                .foregroundStyle(level.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName)
                                    .foregroundStyle(.primary)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if experienceLevel == level {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Experience Level")
            }

            // Preferred Terrain
            Section {
                ForEach(TerrainType.allCases) { terrain in
                    Button {
                        toggleTerrain(terrain)
                        HapticFeedback.selection.trigger()
                    } label: {
                        HStack {
                            Image(systemName: terrain.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 32)

                            Text(terrain.displayName)
                                .foregroundStyle(.primary)

                            Spacer()

                            if preferredTerrain.contains(terrain) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Favorite Terrain")
            } footer: {
                Text("Select all that apply")
            }

            // Season Pass
            Section {
                ForEach(SeasonPassType.allCases) { passType in
                    Button {
                        seasonPassType = passType
                        HapticFeedback.selection.trigger()
                    } label: {
                        HStack {
                            Image(systemName: passType.icon)
                                .foregroundStyle(.blue)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(passType.displayName)
                                    .foregroundStyle(.primary)
                                Text(passType.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if seasonPassType == passType {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            } header: {
                Text("Season Pass")
            }

            // Home Mountain
            Section {
                Button {
                    showMountainPicker = true
                } label: {
                    HStack {
                        Image(systemName: "mountain.2.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 32)

                        if let mountain = selectedMountain {
                            Text(mountain.name)
                                .foregroundStyle(.primary)
                        } else {
                            Text("Select home mountain")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Home Mountain")
            }

            // Save Button
            Section {
                Button {
                    Task { await savePreferences() }
                } label: {
                    HStack {
                        Spacer()
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save Changes")
                        }
                        Spacer()
                    }
                }
                .disabled(isSaving)
            }

            if let message = saveMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.green)
                }
            }
        }
        .navigationTitle("Skiing Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentPreferences()
        }
        .sheet(isPresented: $showMountainPicker) {
            SkiingPrefMountainPickerView(
                selectedMountainId: $homeMountainId,
                isPresented: $showMountainPicker
            )
        }
    }

    // MARK: - Actions

    private func loadCurrentPreferences() {
        guard let profile = authService.userProfile else { return }

        ridingStyle = profile.ridingStyleEnum
        experienceLevel = profile.experienceLevelEnum
        preferredTerrain = profile.preferredTerrainEnums
        seasonPassType = profile.seasonPassTypeEnum
        homeMountainId = profile.homeMountainId
    }

    private func toggleTerrain(_ terrain: TerrainType) {
        if let index = preferredTerrain.firstIndex(of: terrain) {
            preferredTerrain.remove(at: index)
        } else {
            preferredTerrain.append(terrain)
        }
    }

    private func savePreferences() async {
        isSaving = true
        saveMessage = nil

        let profile = OnboardingProfile(
            displayName: authService.userProfile?.displayName,
            bio: authService.userProfile?.bio,
            avatarUrl: authService.userProfile?.avatarUrl,
            ridingStyle: ridingStyle,
            experienceLevel: experienceLevel,
            preferredTerrain: preferredTerrain,
            seasonPassType: seasonPassType,
            homeMountainId: homeMountainId
        )

        do {
            try await authService.updateOnboardingProfile(profile)
            saveMessage = "Preferences saved!"
            HapticFeedback.success.trigger()
        } catch {
            saveMessage = "Failed to save: \(error.localizedDescription)"
            HapticFeedback.error.trigger()
        }

        isSaving = false
    }
}

// MARK: - Skiing Preferences Mountain Picker View

private struct SkiingPrefMountainPickerView: View {
    @Binding var selectedMountainId: String?
    @Binding var isPresented: Bool

    @State private var searchText = ""

    private var mountains: [Mountain] {
        MountainService.shared.allMountains
    }

    private var filteredMountains: [Mountain] {
        if searchText.isEmpty {
            return mountains
        }
        return mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Option to clear selection
                Button {
                    selectedMountainId = nil
                    isPresented = false
                } label: {
                    HStack {
                        Text("No home mountain")
                            .foregroundStyle(.secondary)

                        Spacer()

                        if selectedMountainId == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }

                ForEach(filteredMountains, id: \.id) { mountain in
                    Button {
                        selectedMountainId = mountain.id
                        HapticFeedback.selection.trigger()
                        isPresented = false
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(mountain.name)
                                    .foregroundStyle(.primary)

                                Text(mountain.region.capitalized)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if selectedMountainId == mountain.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search mountains")
            .navigationTitle("Home Mountain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SkiingPreferencesView()
            .environment(AuthService.shared)
    }
}
