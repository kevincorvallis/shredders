//
//  SeasonProgressRing.swift
//  PowderTracker
//
//  Apple Fitness+ style progress rings for season goals
//

import SwiftUI

/// Progress ring style configuration
struct ProgressRingStyle {
    let lineWidth: CGFloat
    let color: Color
    let backgroundColor: Color

    static let `default` = ProgressRingStyle(
        lineWidth: 12,
        color: .blue,
        backgroundColor: Color(.systemGray5)
    )

    static let compact = ProgressRingStyle(
        lineWidth: 8,
        color: .blue,
        backgroundColor: Color(.systemGray5)
    )

    static let large = ProgressRingStyle(
        lineWidth: 16,
        color: .blue,
        backgroundColor: Color(.systemGray5)
    )
}

/// A single animated progress ring
struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0+
    let style: ProgressRingStyle

    @State private var animatedProgress: Double = 0

    init(progress: Double, style: ProgressRingStyle = .default) {
        self.progress = progress
        self.style = style
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    style.backgroundColor,
                    style: StrokeStyle(lineWidth: style.lineWidth, lineCap: .round)
                )

            // Progress ring
            Circle()
                .trim(from: 0, to: min(animatedProgress, 1.0))
                .stroke(
                    style.color,
                    style: StrokeStyle(lineWidth: style.lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: style.color.opacity(0.3), radius: 4, x: 0, y: 2)

            // Overflow indicator (for > 100%)
            if animatedProgress > 1.0 {
                Circle()
                    .trim(from: 0, to: min(animatedProgress - 1.0, 1.0))
                    .stroke(
                        style.color.opacity(0.5),
                        style: StrokeStyle(lineWidth: style.lineWidth * 0.6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = newValue
            }
        }
    }
}

/// Season progress ring with label and value
struct SeasonProgressRing: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let icon: String
    let color: Color
    var size: CGFloat = 100
    var showPercentage: Bool = true

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(current) / Double(goal)
    }

    private var percentage: Int {
        Int(progress * 100)
    }

    var body: some View {
        VStack(spacing: .spacingS) {
            // Ring with center content
            ZStack {
                ProgressRing(
                    progress: progress,
                    style: ProgressRingStyle(
                        lineWidth: size * 0.12,
                        color: color,
                        backgroundColor: Color(.systemGray5)
                    )
                )
                .frame(width: size, height: size)

                // Center content
                VStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: size * 0.2))
                        .foregroundStyle(color)

                    if showPercentage {
                        Text("\(percentage)%")
                            .font(.system(size: size * 0.18, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                }
            }

            // Labels
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)

                Text("\(current)/\(goal) \(unit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Multi-ring display (like Apple Fitness)
struct SeasonProgressRings: View {
    let daysSkied: SeasonGoal
    let powderDays: SeasonGoal
    let totalSnowfall: SeasonGoal

    var body: some View {
        HStack(spacing: .spacingL) {
            // Days Skied Ring
            SeasonProgressRing(
                title: "Days Skied",
                current: daysSkied.current,
                goal: daysSkied.goal,
                unit: "days",
                icon: "figure.skiing.downhill",
                color: .green,
                size: 90
            )

            // Powder Days Ring
            SeasonProgressRing(
                title: "Powder Days",
                current: powderDays.current,
                goal: powderDays.goal,
                unit: "days",
                icon: "snowflake",
                color: .cyan,
                size: 90
            )

            // Total Snowfall Ring
            SeasonProgressRing(
                title: "Snowfall",
                current: totalSnowfall.current,
                goal: totalSnowfall.goal,
                unit: "\"",
                icon: "cloud.snow.fill",
                color: .blue,
                size: 90
            )
        }
    }
}

/// Season goal data model
struct SeasonGoal {
    let current: Int
    let goal: Int

    var progress: Double {
        guard goal > 0 else { return 0 }
        return Double(current) / Double(goal)
    }

    var isComplete: Bool {
        current >= goal
    }

    var remaining: Int {
        max(0, goal - current)
    }

    // Mock data
    static let mockDaysSkied = SeasonGoal(current: 12, goal: 25)
    static let mockPowderDays = SeasonGoal(current: 5, goal: 10)
    static let mockTotalSnowfall = SeasonGoal(current: 287, goal: 400)
}

/// Compact inline progress indicator
struct CompactProgressIndicator: View {
    let progress: Double
    let color: Color
    var width: CGFloat = 100
    var height: CGFloat = 6

    @State private var animatedProgress: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color(.systemGray5))

                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * min(animatedProgress, 1.0))
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
    }
}

/// Animated counting text
struct AnimatedCountText: View {
    let targetValue: Int
    let font: Font
    let color: Color

    @State private var displayValue: Int = 0

    var body: some View {
        Text("\(displayValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear {
                // Animate count up
                withAnimation(.easeOut(duration: 1.0)) {
                    displayValue = targetValue
                }
            }
            .onChange(of: targetValue) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    displayValue = newValue
                }
            }
    }
}

// MARK: - Preview

#Preview("Progress Ring") {
    VStack(spacing: 40) {
        ProgressRing(progress: 0.65, style: .default)
            .frame(width: 100, height: 100)

        ProgressRing(progress: 1.2, style: .large)
            .frame(width: 120, height: 120)

        HStack(spacing: 20) {
            ProgressRing(
                progress: 0.3,
                style: ProgressRingStyle(lineWidth: 8, color: .green, backgroundColor: Color(.systemGray5))
            )
            .frame(width: 60, height: 60)

            ProgressRing(
                progress: 0.7,
                style: ProgressRingStyle(lineWidth: 8, color: .cyan, backgroundColor: Color(.systemGray5))
            )
            .frame(width: 60, height: 60)

            ProgressRing(
                progress: 0.9,
                style: ProgressRingStyle(lineWidth: 8, color: .blue, backgroundColor: Color(.systemGray5))
            )
            .frame(width: 60, height: 60)
        }
    }
    .padding()
}

#Preview("Season Progress Ring") {
    VStack(spacing: 30) {
        SeasonProgressRing(
            title: "Days Skied",
            current: 12,
            goal: 25,
            unit: "days",
            icon: "figure.skiing.downhill",
            color: .green
        )

        SeasonProgressRing(
            title: "Powder Days",
            current: 8,
            goal: 10,
            unit: "days",
            icon: "snowflake",
            color: .cyan,
            size: 120
        )
    }
    .padding()
}

#Preview("Season Progress Rings") {
    SeasonProgressRings(
        daysSkied: .mockDaysSkied,
        powderDays: .mockPowderDays,
        totalSnowfall: .mockTotalSnowfall
    )
    .padding()
}

#Preview("Compact Progress") {
    VStack(spacing: 20) {
        CompactProgressIndicator(progress: 0.3, color: .green)
        CompactProgressIndicator(progress: 0.7, color: .cyan)
        CompactProgressIndicator(progress: 1.0, color: .blue)
    }
    .padding()
}
