//
//  QuickStatsRow.swift
//  PowderTracker
//
//  Quick summary stats row shown below the forecast chart
//

import SwiftUI

/// Compact row showing key forecast summary stats
struct QuickStatsRow: View {
    let totalSnow7Day: Int
    let bestDay: (name: String, snowfall: Int)?
    let alertCount: Int

    var body: some View {
        HStack(spacing: 0) {
            // Total Snow Next 7 Days
            statItem(
                value: "\(totalSnow7Day)\"",
                label: "next 7 days",
                icon: "snowflake",
                color: totalSnow7Day >= 12 ? .blue : .secondary
            )

            Divider()
                .frame(height: 40)

            // Best Day
            if let best = bestDay {
                statItem(
                    value: best.name,
                    label: "\(best.snowfall)\" expected",
                    icon: "star.fill",
                    color: .yellow
                )
            } else {
                statItem(
                    value: "—",
                    label: "best day",
                    icon: "star",
                    color: .secondary
                )
            }

            Divider()
                .frame(height: 40)

            // Active Alerts
            statItem(
                value: "\(alertCount)",
                label: alertCount == 1 ? "alert" : "alerts",
                icon: alertCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle",
                color: alertCount > 0 ? .orange : .green
            )
        }
        .padding(.vertical, .spacingS)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: .spacingXS) {
            HStack(spacing: .spacingXS) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        QuickStatsRow(
            totalSnow7Day: 24,
            bestDay: ("Sat", 12),
            alertCount: 2
        )

        QuickStatsRow(
            totalSnow7Day: 6,
            bestDay: nil,
            alertCount: 0
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
