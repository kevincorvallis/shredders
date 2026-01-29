//
//  SeasonGoalsCard.swift
//  PowderTracker
//
//  Dashboard card combining progress rings, stats, and motivational messaging
//

import SwiftUI

/// Complete season goals data model
struct SeasonGoalsData {
    var daysSkied: SeasonGoal
    var powderDays: SeasonGoal
    var totalSnowfall: SeasonGoal
    var seasonStartDate: Date
    var seasonEndDate: Date

    // Computed properties
    var daysRemaining: Int {
        let calendar = Calendar.current
        let today = Date()
        return max(0, calendar.dateComponents([.day], from: today, to: seasonEndDate).day ?? 0)
    }

    var seasonProgress: Double {
        let calendar = Calendar.current
        let totalDays = calendar.dateComponents([.day], from: seasonStartDate, to: seasonEndDate).day ?? 1
        let daysElapsed = calendar.dateComponents([.day], from: seasonStartDate, to: Date()).day ?? 0
        return Double(daysElapsed) / Double(totalDays)
    }

    var averagePerTrip: Double {
        guard daysSkied.current > 0 else { return 0 }
        return Double(totalSnowfall.current) / Double(daysSkied.current) * 0.1 // Rough estimate
    }

    // Mock data
    static let mock = SeasonGoalsData(
        daysSkied: .mockDaysSkied,
        powderDays: .mockPowderDays,
        totalSnowfall: .mockTotalSnowfall,
        seasonStartDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 15))!,
        seasonEndDate: Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 15))!
    )
}

/// Season goals dashboard card
struct SeasonGoalsCard: View {
    let goals: SeasonGoalsData
    var onEditGoals: (() -> Void)? = nil
    var onViewDetails: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            // Header
            headerSection

            // Progress rings
            SeasonProgressRings(
                daysSkied: goals.daysSkied,
                powderDays: goals.powderDays,
                totalSnowfall: goals.totalSnowfall
            )
            .frame(maxWidth: .infinity)

            // Motivational message
            motivationSection

            // Season progress bar
            seasonProgressSection

            // Action buttons
            if onEditGoals != nil || onViewDetails != nil {
                actionButtons
            }
        }
        .padding(.spacingL)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Components

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text("Season Goals")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(goals.daysRemaining) days remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Season indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(seasonStatusColor)
                    .frame(width: 8, height: 8)

                Text(seasonStatusText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(seasonStatusColor)
            }
        }
    }

    private var motivationSection: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: motivationIcon)
                .font(.title2)
                .foregroundStyle(motivationColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(motivationTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Text(motivationSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.spacingM)
        .background(motivationColor.opacity(0.1))
        .cornerRadius(.cornerRadiusCard)
    }

    private var seasonProgressSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text("Season Progress")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int(goals.seasonProgress * 100))%")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }

            CompactProgressIndicator(
                progress: goals.seasonProgress,
                color: .indigo,
                width: .infinity,
                height: 8
            )
            .frame(maxWidth: .infinity)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: .spacingM) {
            if let onViewDetails = onViewDetails {
                Button {
                    HapticFeedback.light.trigger()
                    onViewDetails()
                } label: {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "chart.bar.xaxis")
                        Text("View Stats")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.spacingM)
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.primary)
                    .cornerRadius(.cornerRadiusCard)
                }
            }

            if let onEditGoals = onEditGoals {
                Button {
                    HapticFeedback.light.trigger()
                    onEditGoals()
                } label: {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "pencil")
                        Text("Edit Goals")
                    }
                    .font(.subheadline.weight(.medium))
                    .frame(maxWidth: .infinity)
                    .padding(.spacingM)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .cornerRadius(.cornerRadiusCard)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var seasonStatusColor: Color {
        if goals.seasonProgress >= 1.0 {
            return .secondary
        } else if goals.seasonProgress >= 0.8 {
            return .orange
        } else if goals.seasonProgress >= 0.5 {
            return .green
        }
        return .blue
    }

    private var seasonStatusText: String {
        if goals.seasonProgress >= 1.0 {
            return "Season Ended"
        } else if goals.seasonProgress >= 0.8 {
            return "Final Push"
        } else if goals.seasonProgress >= 0.5 {
            return "Mid-Season"
        }
        return "Early Season"
    }

    private var motivationIcon: String {
        if goals.daysSkied.isComplete && goals.powderDays.isComplete {
            return "trophy.fill"
        } else if goals.daysSkied.progress >= 0.8 || goals.powderDays.progress >= 0.8 {
            return "flame.fill"
        } else if goals.powderDays.current > 0 {
            return "star.fill"
        }
        return "figure.skiing.downhill"
    }

    private var motivationColor: Color {
        if goals.daysSkied.isComplete && goals.powderDays.isComplete {
            return .yellow
        } else if goals.daysSkied.progress >= 0.8 || goals.powderDays.progress >= 0.8 {
            return .orange
        } else if goals.powderDays.current > 0 {
            return .cyan
        }
        return .green
    }

    private var motivationTitle: String {
        if goals.daysSkied.isComplete && goals.powderDays.isComplete {
            return "All Goals Achieved! 🎉"
        } else if goals.daysSkied.progress >= 0.8 && goals.powderDays.progress >= 0.8 {
            return "Almost there!"
        } else if goals.daysSkied.progress >= 0.5 {
            return "Great progress!"
        } else if goals.daysSkied.current > 0 {
            return "Keep it up!"
        }
        return "Season is underway!"
    }

    private var motivationSubtitle: String {
        if goals.daysSkied.isComplete && goals.powderDays.isComplete {
            return "You've crushed all your season goals"
        } else if !goals.daysSkied.isComplete {
            let remaining = goals.daysSkied.remaining
            return "\(remaining) more \(remaining == 1 ? "day" : "days") to reach your ski day goal"
        } else if !goals.powderDays.isComplete {
            let remaining = goals.powderDays.remaining
            return "\(remaining) more powder \(remaining == 1 ? "day" : "days") to go"
        }
        return "You're making great progress this season"
    }
}

/// Compact version of the goals card
struct CompactSeasonGoalsCard: View {
    let goals: SeasonGoalsData

    var body: some View {
        HStack(spacing: .spacingM) {
            // Mini rings
            HStack(spacing: .spacingS) {
                miniRing(progress: goals.daysSkied.progress, color: .green)
                miniRing(progress: goals.powderDays.progress, color: .cyan)
                miniRing(progress: goals.totalSnowfall.progress, color: .blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Season Goals")
                    .font(.subheadline.weight(.medium))

                Text("\(goals.daysSkied.current) days • \(goals.powderDays.current) powder")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func miniRing(progress: Double, color: Color) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: 24, height: 24)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(-90))
        }
    }
}

// MARK: - Preview

#Preview("Season Goals Card") {
    ScrollView {
        VStack(spacing: 20) {
            SeasonGoalsCard(
                goals: .mock,
                onEditGoals: { },
                onViewDetails: { }
            )

            SeasonGoalsCard(
                goals: SeasonGoalsData(
                    daysSkied: SeasonGoal(current: 25, goal: 25),
                    powderDays: SeasonGoal(current: 10, goal: 10),
                    totalSnowfall: SeasonGoal(current: 420, goal: 400),
                    seasonStartDate: Calendar.current.date(from: DateComponents(year: 2024, month: 11, day: 15))!,
                    seasonEndDate: Calendar.current.date(from: DateComponents(year: 2025, month: 4, day: 15))!
                )
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Card") {
    VStack(spacing: 16) {
        CompactSeasonGoalsCard(goals: .mock)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
