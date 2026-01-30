//
//  OnboardingPreferencesView.swift
//  PowderTracker
//
//  Preferences step for onboarding (home mountain, season pass).
//

import SwiftUI

struct OnboardingPreferencesView: View {
    @Binding var profile: OnboardingProfile
    let onComplete: () -> Void
    let onSkip: () -> Void

    @State private var searchText = ""
    @State private var showMountainPicker = false

    // Get mountains from shared package
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

    private var selectedMountain: Mountain? {
        guard let id = profile.homeMountainId else { return nil }
        return mountains.first { $0.id == id }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingXL) {
                // Header
                VStack(spacing: .spacingS) {
                    Text("Your Preferences")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Help us show you relevant content")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, .spacingXL)

                // Home Mountain
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Home Mountain")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Button {
                        showMountainPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "mountain.2.fill")
                                .foregroundStyle(.blue)

                            if let mountain = selectedMountain {
                                Text(mountain.name)
                                    .foregroundStyle(.primary)
                            } else {
                                Text("Select your home mountain")
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusButton)
                    }
                }
                .padding(.horizontal, .spacingL)

                // Season Pass Type
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Season Pass")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    VStack(spacing: .spacingS) {
                        ForEach(SeasonPassType.allCases) { passType in
                            SeasonPassRow(
                                passType: passType,
                                isSelected: profile.seasonPassType == passType,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        profile.seasonPassType = passType
                                    }
                                    HapticFeedback.selection.trigger()
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, .spacingL)

                Spacer(minLength: .spacingXXL)

                // Buttons
                VStack(spacing: .spacingM) {
                    Button {
                        onComplete()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Setup")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
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
        .sheet(isPresented: $showMountainPicker) {
            OnboardingMountainPickerSheet(
                mountains: mountains,
                selectedMountainId: $profile.homeMountainId,
                isPresented: $showMountainPicker
            )
        }
    }
}

// MARK: - Season Pass Row

private struct SeasonPassRow: View {
    let passType: SeasonPassType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingM) {
                Image(systemName: passType.icon)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 32, height: 32)
                    .background(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(passType.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    Text(passType.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusButton)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Onboarding Mountain Picker Sheet

private struct OnboardingMountainPickerSheet: View {
    let mountains: [Mountain]
    @Binding var selectedMountainId: String?
    @Binding var isPresented: Bool

    @State private var searchText = ""

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
            .navigationTitle("Select Mountain")
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
    OnboardingPreferencesView(
        profile: .constant(OnboardingProfile()),
        onComplete: {},
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
