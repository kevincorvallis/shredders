//
//  SkillLevelBadge.swift
//  PowderTracker
//
//  Reusable skill level badge component using authentic ski trail difficulty icons.
//  Based on North American ski trail rating system:
//  - Green Circle: Beginner (easiest, 0-25% grade)
//  - Blue Square: Intermediate (25-40% grade)
//  - Black Diamond: Advanced (40%+ grade, ungroomed)
//  - Double Black Diamond: Expert only (very steep, hazards)
//

import SwiftUI

/// Displays a ski trail difficulty badge (green circle, blue square, black diamond, etc.)
struct SkillLevelBadge: View {
    let level: SkillLevel
    var showLabel: Bool = true
    var size: Size = .standard

    enum Size {
        case compact
        case standard
        case large

        var iconSize: CGFloat {
            switch self {
            case .compact: return 12
            case .standard: return 14
            case .large: return 18
            }
        }

        var font: Font {
            switch self {
            case .compact: return .caption2
            case .standard: return .caption
            case .large: return .subheadline
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .compact: return 6
            case .standard: return 10
            case .large: return 12
            }
        }

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return 4
            case .standard: return 6
            case .large: return 8
            }
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            skillIcon

            if showLabel {
                Text(label)
                    .font(size.font)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
        .accessibilityLabel("Skill level: \(accessibilityLabel)")
    }

    // MARK: - Skill Icon (Authentic Ski Resort Trail Markers)

    @ViewBuilder
    private var skillIcon: some View {
        switch level {
        case .beginner:
            // Green Circle - Easiest runs
            Circle()
                .fill(SkillLevelStyle.beginnerColor)
                .frame(width: size.iconSize, height: size.iconSize)

        case .intermediate:
            // Blue Square - Intermediate runs
            Rectangle()
                .fill(SkillLevelStyle.intermediateColor)
                .frame(width: size.iconSize, height: size.iconSize)

        case .advanced:
            // Black Diamond - Advanced runs
            SkiDiamondShape()
                .fill(SkillLevelStyle.advancedColor)
                .frame(width: size.iconSize, height: size.iconSize)

        case .expert:
            // Double Black Diamond - Expert only
            HStack(spacing: 2) {
                SkiDiamondShape()
                    .fill(SkillLevelStyle.advancedColor)
                    .frame(width: size.iconSize * 0.8, height: size.iconSize * 0.8)
                SkiDiamondShape()
                    .fill(SkillLevelStyle.advancedColor)
                    .frame(width: size.iconSize * 0.8, height: size.iconSize * 0.8)
            }

        case .all:
            // All levels - show green, blue, black combined
            HStack(spacing: 3) {
                Circle()
                    .fill(SkillLevelStyle.beginnerColor)
                    .frame(width: size.iconSize * 0.6, height: size.iconSize * 0.6)
                Rectangle()
                    .fill(SkillLevelStyle.intermediateColor)
                    .frame(width: size.iconSize * 0.6, height: size.iconSize * 0.6)
                SkiDiamondShape()
                    .fill(SkillLevelStyle.advancedColor)
                    .frame(width: size.iconSize * 0.6, height: size.iconSize * 0.6)
            }
        }
    }

    // MARK: - Labels & Colors

    private var label: String {
        switch level {
        case .beginner: return "Green"
        case .intermediate: return "Blue"
        case .advanced: return "Black"
        case .expert: return "2x Black"
        case .all: return "All Levels"
        }
    }

    private var color: Color {
        switch level {
        case .beginner: return SkillLevelStyle.beginnerColor
        case .intermediate: return SkillLevelStyle.intermediateColor
        case .advanced, .expert: return SkillLevelStyle.advancedColor
        case .all: return SkillLevelStyle.allLevelsColor
        }
    }

    private var accessibilityLabel: String {
        switch level {
        case .beginner: return "Beginner, green circle runs"
        case .intermediate: return "Intermediate, blue square runs"
        case .advanced: return "Advanced, black diamond runs"
        case .expert: return "Expert, double black diamond runs"
        case .all: return "All skill levels welcome"
        }
    }
}

// MARK: - Standalone Ski Trail Icon (No Badge Background)

/// A standalone ski trail difficulty icon without badge styling
/// Use this when you want just the icon (e.g., in tight spaces or inline text)
struct SkiTrailIcon: View {
    let level: SkillLevel
    var size: CGFloat = 16

    var body: some View {
        Group {
            switch level {
            case .beginner:
                Circle()
                    .fill(SkillLevelStyle.beginnerColor)

            case .intermediate:
                Rectangle()
                    .fill(SkillLevelStyle.intermediateColor)

            case .advanced:
                SkiDiamondShape()
                    .fill(SkillLevelStyle.advancedColor)

            case .expert:
                HStack(spacing: 2) {
                    SkiDiamondShape()
                        .fill(SkillLevelStyle.advancedColor)
                        .frame(width: size * 0.8, height: size * 0.8)
                    SkiDiamondShape()
                        .fill(SkillLevelStyle.advancedColor)
                        .frame(width: size * 0.8, height: size * 0.8)
                }

            case .all:
                HStack(spacing: 2) {
                    Circle()
                        .fill(SkillLevelStyle.beginnerColor)
                        .frame(width: size * 0.6, height: size * 0.6)
                    Rectangle()
                        .fill(SkillLevelStyle.intermediateColor)
                        .frame(width: size * 0.6, height: size * 0.6)
                    SkiDiamondShape()
                        .fill(SkillLevelStyle.advancedColor)
                        .frame(width: size * 0.6, height: size * 0.6)
                }
            }
        }
        .frame(width: size, height: size)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch level {
        case .beginner: return "Beginner, green circle"
        case .intermediate: return "Intermediate, blue square"
        case .advanced: return "Advanced, black diamond"
        case .expert: return "Expert, double black diamond"
        case .all: return "All skill levels"
        }
    }
}

// MARK: - Diamond Shape (Authentic Ski Resort Style)

/// Custom diamond shape that matches authentic ski resort black diamond markers
struct SkiDiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let halfWidth = rect.width / 2
        let halfHeight = rect.height / 2

        path.move(to: CGPoint(x: center.x, y: center.y - halfHeight)) // Top
        path.addLine(to: CGPoint(x: center.x + halfWidth, y: center.y)) // Right
        path.addLine(to: CGPoint(x: center.x, y: center.y + halfHeight)) // Bottom
        path.addLine(to: CGPoint(x: center.x - halfWidth, y: center.y)) // Left
        path.closeSubpath()

        return path
    }
}

// MARK: - Style Constants

/// Standard ski resort trail marker colors
enum SkillLevelStyle {
    /// Green circle - Beginner/Easiest
    static let beginnerColor = Color(hex: "22C55E") ?? .green

    /// Blue square - Intermediate
    static let intermediateColor = Color(hex: "3B82F6") ?? .blue

    /// Black diamond - Advanced/Expert (using near-black for visibility)
    static let advancedColor = Color(hex: "1F2937") ?? .black

    /// Purple - All levels welcome
    static let allLevelsColor = Color(hex: "A855F7") ?? .purple
}

// MARK: - Preview

#Preview("Skill Level Badges") {
    VStack(spacing: 20) {
        Text("With Labels")
            .font(.headline)

        VStack(spacing: 12) {
            ForEach(SkillLevel.allCases, id: \.self) { level in
                HStack {
                    SkillLevelBadge(level: level, size: .compact)
                    SkillLevelBadge(level: level, size: .standard)
                    SkillLevelBadge(level: level, size: .large)
                }
            }
        }

        Divider()

        Text("Icon Only (No Label)")
            .font(.headline)

        HStack(spacing: 16) {
            ForEach(SkillLevel.allCases, id: \.self) { level in
                SkillLevelBadge(level: level, showLabel: false, size: .standard)
            }
        }

        Divider()

        Text("Standalone Icons")
            .font(.headline)

        HStack(spacing: 20) {
            ForEach(SkillLevel.allCases, id: \.self) { level in
                VStack {
                    SkiTrailIcon(level: level, size: 24)
                    Text(level.displayName)
                        .font(.caption2)
                }
            }
        }
    }
    .padding()
}

#Preview("Dark Mode") {
    VStack(spacing: 16) {
        ForEach(SkillLevel.allCases, id: \.self) { level in
            HStack {
                SkillLevelBadge(level: level, size: .standard)
                Spacer()
                SkiTrailIcon(level: level, size: 20)
            }
        }
    }
    .padding()
    .background(Color(.systemBackground))
    .preferredColorScheme(.dark)
}
