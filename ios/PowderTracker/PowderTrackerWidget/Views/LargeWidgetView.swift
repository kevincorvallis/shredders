import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: PowderEntry

    private var scoreColor: Color {
        switch entry.powderScore {
        case 9...10: return .green
        case 7...8: return .mint
        case 5...6: return .yellow
        case 3...4: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header with mountain name and score
            headerSection

            Divider()

            // Current conditions
            conditionsSection

            Divider()

            // Extended forecast
            forecastSection
        }
        .padding()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            // Mountain info
            HStack(spacing: 8) {
                Text("🏔️")
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.mountainName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(1)

                    Text("Updated \(timeAgo(from: entry.date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Powder score badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.powderScore)")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)

                Text(entry.scoreLabel)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor)
            }
        }
    }

    // MARK: - Conditions Section

    private var conditionsSection: some View {
        HStack(spacing: 0) {
            // Snow depth
            conditionTile(
                value: "\(entry.snowDepth)\"",
                label: "Base Depth",
                icon: "mountain.2.fill",
                color: .blue
            )

            Divider()
                .frame(height: 50)

            // 24h snowfall
            conditionTile(
                value: "+\(entry.snowfall24h)\"",
                label: "24hr Snow",
                icon: "snowflake",
                color: entry.snowfall24h > 0 ? .cyan : .secondary
            )

            Divider()
                .frame(height: 50)

            // Last updated
            conditionTile(
                value: timeAgo(from: entry.date),
                label: "Updated",
                icon: "clock.fill",
                color: .secondary
            )
        }
    }

    private func conditionTile(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Forecast Section

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("3-Day Forecast")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(entry.forecast) { day in
                    forecastDayTile(day: day)
                }
            }
        }
    }

    private func forecastDayTile(day: WidgetForecastDay) -> some View {
        VStack(spacing: 8) {
            Text(day.dayOfWeek)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Text(day.icon)
                .font(.title2)

            if day.snowfall > 0 {
                Text("\(day.snowfall)\"")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            } else {
                Text("—")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground).opacity(0.5))
        )
    }

    // MARK: - Helpers

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 1 {
            return "Now"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            return "\(hours)h"
        }
    }
}

#Preview(as: .systemLarge) {
    PowderTrackerWidget()
} timeline: {
    PowderEntry(
        date: Date(),
        mountainId: "crystal-mountain",
        mountainName: "Crystal Mountain",
        snowDepth: 142,
        snowfall24h: 8,
        powderScore: 8,
        scoreLabel: "Great",
        forecast: [
            WidgetForecastDay(dayOfWeek: "Sat", snowfall: 6, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Sun", snowfall: 10, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Mon", snowfall: 4, icon: "❄️")
        ]
    )
}
