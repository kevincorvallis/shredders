//
//  TerrainDiamondIcon.swift
//  PowderTracker
//
//  Traditional ski slope terrain difficulty icons using the standard
//  industry symbols: green circle, blue square, black diamond, double black diamond.
//

import SwiftUI

// MARK: - Terrain Icon Style

/// Standard ski slope terrain difficulty colors following industry conventions
enum TerrainIconStyle {
    /// Green for beginner slopes (green circle)
    static let beginnerColor = Color(hex: "22C55E") ?? .green
    /// Blue for intermediate slopes (blue square)
    static let intermediateColor = Color(hex: "3B82F6") ?? .blue
    /// Black for advanced/expert slopes (black diamond)
    static let advancedColor = Color.black
}

// MARK: - Terrain Diamond Icon

/// A view that displays the traditional ski slope difficulty icons.
/// - Beginner: Green circle
/// - Intermediate: Blue square
/// - Advanced: Single black diamond
/// - Expert: Double black diamond
struct TerrainDiamondIcon: View {
    let level: ExperienceLevel
    var size: CGFloat = 24
    var showBackground: Bool = true

    private var iconSize: CGFloat {
        size * 0.5
    }

    private var doubleIconSize: CGFloat {
        size * 0.35
    }

    var body: some View {
        Group {
            switch level {
            case .beginner:
                beginnerIcon
            case .intermediate:
                intermediateIcon
            case .advanced:
                advancedIcon
            case .expert:
                expertIcon
            }
        }
        .frame(width: size, height: size)
        .background(
            showBackground
                ? RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(Color(.systemBackground).opacity(0.9))
                : nil
        )
    }

    // MARK: - Icon Views

    /// Green circle for beginner terrain
    private var beginnerIcon: some View {
        Circle()
            .fill(TerrainIconStyle.beginnerColor)
            .frame(width: iconSize, height: iconSize)
    }

    /// Blue square for intermediate terrain
    private var intermediateIcon: some View {
        Rectangle()
            .fill(TerrainIconStyle.intermediateColor)
            .frame(width: iconSize, height: iconSize)
    }

    /// Single black diamond for advanced terrain
    private var advancedIcon: some View {
        Image(systemName: "diamond.fill")
            .font(.system(size: iconSize))
            .foregroundStyle(TerrainIconStyle.advancedColor)
    }

    /// Double black diamond for expert terrain
    private var expertIcon: some View {
        HStack(spacing: size * 0.02) {
            Image(systemName: "diamond.fill")
                .font(.system(size: doubleIconSize))
            Image(systemName: "diamond.fill")
                .font(.system(size: doubleIconSize))
        }
        .foregroundStyle(TerrainIconStyle.advancedColor)
    }
}

// MARK: - Labeled Terrain Icon

/// A terrain icon with an optional text label
struct LabeledTerrainIcon: View {
    let level: ExperienceLevel
    var iconSize: CGFloat = 32
    var showLabel: Bool = true
    var labelStyle: Font = .caption

    var body: some View {
        VStack(spacing: 4) {
            TerrainDiamondIcon(level: level, size: iconSize, showBackground: false)

            if showLabel {
                Text(level.trailRating)
                    .font(labelStyle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - ExperienceLevel Extension

extension ExperienceLevel {
    /// The traditional trail rating name for this experience level
    var trailRating: String {
        switch self {
        case .beginner: return "Green Circle"
        case .intermediate: return "Blue Square"
        case .advanced: return "Black Diamond"
        case .expert: return "Double Black"
        }
    }

    /// The accent color to use for UI elements (matches the icon color)
    var accentColor: Color {
        switch self {
        case .beginner: return TerrainIconStyle.beginnerColor
        case .intermediate: return TerrainIconStyle.intermediateColor
        case .advanced, .expert: return TerrainIconStyle.advancedColor
        }
    }
}

// MARK: - Preview

#Preview("All Terrain Icons") {
    VStack(spacing: 24) {
        Text("Terrain Difficulty Icons")
            .font(.headline)

        HStack(spacing: 20) {
            ForEach(ExperienceLevel.allCases) { level in
                VStack(spacing: 8) {
                    TerrainDiamondIcon(level: level, size: 48)
                    Text(level.displayName)
                        .font(.caption)
                    Text(level.trailRating)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }

        Divider()

        Text("Without Background")
            .font(.subheadline)

        HStack(spacing: 20) {
            ForEach(ExperienceLevel.allCases) { level in
                TerrainDiamondIcon(level: level, size: 32, showBackground: false)
            }
        }

        Divider()

        Text("Labeled Icons")
            .font(.subheadline)

        HStack(spacing: 20) {
            ForEach(ExperienceLevel.allCases) { level in
                LabeledTerrainIcon(level: level)
            }
        }
    }
    .padding()
}
