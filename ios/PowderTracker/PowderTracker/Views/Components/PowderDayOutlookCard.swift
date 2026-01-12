//
//  PowderDayOutlookCard.swift
//  PowderTracker
//
//  3-day powder outlook card with SEND/MAYBE/WAIT verdicts
//

import SwiftUI

struct PowderDayOutlookCard: View {
    let mountain: Mountain
    let plan: PowderDayPlanResponse?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 40
                )

                Text(mountain.shortName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()
            }
            .padding()
            .background(Color(.tertiarySystemBackground))

            if let plan = plan {
                // 3-day grid
                HStack(spacing: 0) {
                    ForEach(plan.days.prefix(3)) { day in
                        dayColumn(day)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
            } else {
                // No data available
                Text("Forecast unavailable")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dayColumn(_ day: PowderDay) -> some View {
        VStack(spacing: 8) {
            // Day of week
            Text(day.dayOfWeek)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            // Verdict emoji
            Text(day.verdict.emoji)
                .font(.title2)

            // Verdict text
            Text(day.verdict.displayName)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(verdictColor(day.verdict))

            Divider()
                .padding(.vertical, 4)

            // Powder score gauge
            ZStack {
                Circle()
                    .stroke(Color(.tertiarySystemBackground), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: day.predictedPowderScore / 10)
                    .stroke(scoreColor(day.predictedPowderScore), lineWidth: 4)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.1f", day.predictedPowderScore))
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(width: 50, height: 50)

            // Snowfall forecast
            HStack(spacing: 2) {
                Image(systemName: "snowflake")
                    .font(.caption2)
                Text("\(day.forecastSnapshot.snowfall)\"")
                    .font(.caption2)
            }
            .foregroundStyle(.blue)

            // Confidence badge
            Text("\(Int(day.confidence * 100))%")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.tertiarySystemBackground))
                .clipShape(Capsule())

            // Crowd risk
            HStack(spacing: 2) {
                Image(systemName: "person.3")
                    .font(.caption2)
                Text(day.crowdRisk.displayName)
                    .font(.caption2)
            }
            .foregroundStyle(crowdColor(day.crowdRisk))
        }
        .padding(.vertical, 8)
    }

    private func verdictColor(_ verdict: PowderVerdict) -> Color {
        switch verdict {
        case .send: return .green
        case .maybe: return .orange
        case .wait: return .gray
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 8.0 { return .green }
        if score >= 6.0 { return .blue }
        if score >= 4.0 { return .orange }
        return .gray
    }

    private func crowdColor(_ risk: RiskLevel) -> Color {
        switch risk {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
