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
                label: "7-day total",
                icon: "snowflake",
                color: totalSnow7Day >= 12 ? .blue : .secondary
            )

            Divider()
                .frame(height: 32)

            // Best Day
            if let best = bestDay {
                statItem(
                    value: best.name,
                    label: "\(best.snowfall)\" snow",
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
                .frame(height: 32)

            // Active Alerts
            statItem(
                value: "\(alertCount)",
                label: alertCount == 1 ? "alert" : "alerts",
                icon: alertCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle",
                color: alertCount > 0 ? .orange : .green
            )
        }
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11))
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
