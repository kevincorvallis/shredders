//
//  ExperienceLevelButton.swift
//  PowderTracker
//
//  Experience level selection button for onboarding using traditional
//  ski slope terrain icons (green circle, blue square, black diamond, double black).
//

import SwiftUI

struct ExperienceLevelButton: View {
    let level: ExperienceLevel
    let isSelected: Bool
    let action: () -> Void

    /// Use backgroundColor for UI elements (provides better visibility for black diamonds)
    private var displayColor: Color {
        level.backgroundColor
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: .spacingS) {
                // Traditional ski slope diamond icon
                terrainIconView
                    .frame(width: 56, height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: .cornerRadiusCard)
                            .fill(isSelected ? displayColor.opacity(0.15) : Color(.tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadiusCard)
                            .stroke(isSelected ? displayColor : Color.clear, lineWidth: 2)
                    )

                VStack(spacing: 2) {
                    Text(level.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isSelected ? displayColor : .primary)

                    Text(level.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(width: 90)
            .padding(.spacingS)
            .background(isSelected ? displayColor.opacity(0.08) : Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .stroke(isSelected ? displayColor.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .accessibilityLabel("\(level.displayName), \(level.trailRating), \(level.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Terrain Icon View

    /// Returns the appropriate ski slope icon based on experience level
    @ViewBuilder
    private var terrainIconView: some View {
        switch level {
        case .beginner:
            // Green circle
            Circle()
                .fill(TerrainIconStyle.beginnerColor)
                .frame(width: 24, height: 24)
                .shadow(color: TerrainIconStyle.beginnerColor.opacity(0.3), radius: 4, y: 2)

        case .intermediate:
            // Blue square
            Rectangle()
                .fill(TerrainIconStyle.intermediateColor)
                .frame(width: 22, height: 22)
                .shadow(color: TerrainIconStyle.intermediateColor.opacity(0.3), radius: 4, y: 2)

        case .advanced:
            // Single black diamond
            Image(systemName: "diamond.fill")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(TerrainIconStyle.advancedColor)
                .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)

        case .expert:
            // Double black diamond
            HStack(spacing: 2) {
                Image(systemName: "diamond.fill")
                    .font(.system(size: 18, weight: .medium))
                Image(systemName: "diamond.fill")
                    .font(.system(size: 18, weight: .medium))
            }
            .foregroundStyle(TerrainIconStyle.advancedColor)
            .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
        }
    }
}

#Preview("Experience Level Buttons") {
    VStack(spacing: 24) {
        Text("Traditional Ski Slope Icons")
            .font(.headline)

        // Unselected state
        HStack(spacing: 12) {
            ForEach(ExperienceLevel.allCases) { level in
                ExperienceLevelButton(
                    level: level,
                    isSelected: false,
                    action: {}
                )
            }
        }

        Text("Selected States")
            .font(.subheadline)
            .foregroundStyle(.secondary)

        // Selected states
        HStack(spacing: 12) {
            ForEach(ExperienceLevel.allCases) { level in
                ExperienceLevelButton(
                    level: level,
                    isSelected: true,
                    action: {}
                )
            }
        }
    }
    .padding()
}
