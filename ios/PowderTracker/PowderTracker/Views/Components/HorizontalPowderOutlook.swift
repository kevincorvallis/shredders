//
//  HorizontalPowderOutlook.swift
//  PowderTracker
//
//  Horizontal scrolling 3-Day Powder Outlook cards
//

import SwiftUI

/// Horizontal scroll container for powder day outlook cards
struct HorizontalPowderOutlook: View {
    let mountains: [(mountain: Mountain, plan: PowderDayPlanResponse?)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingM) {
                ForEach(mountains, id: \.mountain.id) { item in
                    HorizontalPowderCard(
                        mountain: item.mountain,
                        plan: item.plan
                    )
                }
            }
            .padding(.horizontal, .spacingXS)
        }
    }
}

/// Compact horizontal card showing 3-day powder outlook for a single mountain
struct HorizontalPowderCard: View {
    let mountain: Mountain
    let plan: PowderDayPlanResponse?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: .spacingS) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 28
                )

                Text(mountain.shortName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingS)
            .background(Color(.tertiarySystemBackground))

            if let plan = plan {
                // 3-day vertical list
                VStack(spacing: .spacingXS) {
                    ForEach(plan.days.prefix(3)) { day in
                        dayRow(day)
                    }
                }
                .padding(.spacingS)
            } else {
                Text("No forecast")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.spacingM)
            }
        }
        .frame(width: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func dayRow(_ day: PowderDay) -> some View {
        HStack(spacing: .spacingS) {
            Text(day.dayOfWeek)
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: 28, alignment: .leading)

            Text(day.verdict.emoji)
                .font(.caption)

            Spacer()

            if day.forecastSnapshot.snowfall > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 8))
                    Text("\(day.forecastSnapshot.snowfall)\"")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, .spacingXS)
        .padding(.vertical, .spacingXS / 2)
        .background(verdictBackground(day.verdict))
        .cornerRadius(.cornerRadiusMicro)
    }

    private func verdictBackground(_ verdict: PowderVerdict) -> Color {
        switch verdict {
        case .send: return Color.green.opacity(0.15)
        case .maybe: return Color.orange.opacity(0.15)
        case .wait: return Color(.tertiarySystemBackground)
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Text("3-Day Powder Outlook")
            .font(.headline)

        HorizontalPowderOutlook(mountains: [])
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
