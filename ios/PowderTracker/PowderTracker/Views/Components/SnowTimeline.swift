//
//  SnowTimeline.swift
//  PowderTracker
//
//  OpenSnow-inspired snow timeline showing past + future snowfall at a glance
//

import SwiftUI

/// OpenSnow-style horizontal timeline showing past and future snow totals
struct SnowTimeline: View {
    let conditions: MountainConditions?
    let forecast: [ForecastDay]
    let mountainName: String

    // Time periods
    private var last24h: Int {
        conditions?.snowfall24h ?? 0
    }

    private var last48h: Int {
        conditions?.snowfall48h ?? 0
    }

    private var last7d: Int {
        conditions?.snowfall7d ?? 0
    }

    private var next3Days: Int {
        forecast.prefix(3).reduce(0) { $0 + $1.snowfall }
    }

    private var next7Days: Int {
        forecast.prefix(7).reduce(0) { $0 + $1.snowfall }
    }

    private var days4to7: Int {
        let allDays = Array(forecast.prefix(7))
        return allDays.dropFirst(3).reduce(0) { $0 + $1.snowfall }
    }

    private var maxValue: Int {
        max(last7d, next7Days, 1) // Avoid division by zero
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Snow Timeline")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Text(mountainName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Main timeline
            HStack(spacing: 0) {
                // Past section
                timelinePeriod(
                    label: "Past 7D",
                    value: last7d,
                    subValue: "(\(last48h)\" in 48h)",
                    color: .gray,
                    alignment: .leading
                )

                Spacer()

                // Center highlight - Last 24h
                centerHighlight

                Spacer()

                // Future section
                timelinePeriod(
                    label: "Next 7D",
                    value: next7Days,
                    subValue: "(\(next3Days)\" in 3D)",
                    color: .blue,
                    alignment: .trailing
                )
            }

            // Visual bar representation
            timelineBar

            // Daily breakdown dots
            if !forecast.isEmpty {
                dailyDots
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Center Highlight (Last 24h)

    private var centerHighlight: some View {
        VStack(spacing: 4) {
            Text("Last 24h")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text("\(last24h)\"")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    last24h >= 6 ?
                        LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom) :
                        LinearGradient(colors: [.primary, .primary], startPoint: .top, endPoint: .bottom)
                )

            if last24h >= 6 {
                HStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                    Text("FRESH")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(.cyan)
            } else if last24h > 0 {
                Text("Reported")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Text("No new snow")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(minWidth: 90)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(last24h >= 6 ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(last24h >= 6 ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }

    // MARK: - Period Label

    private func timelinePeriod(
        label: String,
        value: Int,
        subValue: String,
        color: Color,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("\(value)\"")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(value > 0 ? color : .secondary)

            Text(subValue)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 70)
    }

    // MARK: - Timeline Bar

    private var timelineBar: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let centerWidth: CGFloat = 90
            let sideWidth = (width - centerWidth) / 2 - 8

            HStack(spacing: 4) {
                // Past bar (gray, right-aligned)
                HStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth(for: last7d, maxWidth: sideWidth))
                }
                .frame(width: sideWidth)

                // Center indicator
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: centerWidth)

                // Future bar (blue, left-aligned)
                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth(for: next7Days, maxWidth: sideWidth))
                    Spacer()
                }
                .frame(width: sideWidth)
            }
        }
        .frame(height: 8)
    }

    private func barWidth(for value: Int, maxWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        let ratio = CGFloat(value) / CGFloat(maxValue)
        return max(value > 0 ? 8 : 0, ratio * maxWidth)
    }

    // MARK: - Daily Dots

    private var dailyDots: some View {
        HStack(spacing: 0) {
            // Spacer for past section
            Spacer()

            // Future days dots
            HStack(spacing: 4) {
                ForEach(Array(forecast.prefix(7).enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 2) {
                        // Snowfall dot
                        Circle()
                            .fill(dotColor(for: day.snowfall))
                            .frame(width: dotSize(for: day.snowfall), height: dotSize(for: day.snowfall))

                        // Day label
                        Text(String(day.dayOfWeek.prefix(1)))
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 4)
    }

    private func dotColor(for snowfall: Int) -> Color {
        if snowfall >= 12 {
            return .purple
        } else if snowfall >= 6 {
            return .cyan
        } else if snowfall > 0 {
            return .blue.opacity(0.6)
        }
        return Color(.systemGray4)
    }

    private func dotSize(for snowfall: Int) -> CGFloat {
        if snowfall >= 12 {
            return 12
        } else if snowfall >= 6 {
            return 10
        } else if snowfall > 0 {
            return 8
        }
        return 6
    }
}

// MARK: - Compact Version

struct SnowTimelineCompact: View {
    let last24h: Int
    let next3Days: Int

    var body: some View {
        HStack(spacing: 12) {
            // Past
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("\(last24h)\"")
                    .font(.caption)
                    .fontWeight(.medium)
            }

            // Divider
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 16)

            // Future
            HStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text("\(next3Days)\"")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                Text("next 3D")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(.tertiarySystemFill))
        )
    }
}

// MARK: - Preview

#Preview("Full Timeline") {
    VStack(spacing: 20) {
        SnowTimeline(
            conditions: MountainConditions.mock,
            forecast: ForecastDay.mockWeek,
            mountainName: "Crystal Mountain"
        )

        SnowTimeline(
            conditions: nil,
            forecast: [],
            mountainName: "No Data"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact") {
    SnowTimelineCompact(last24h: 8, next3Days: 12)
        .padding()
}
