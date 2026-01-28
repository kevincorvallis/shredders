//
//  HorizontalPowderOutlook.swift
//  PowderTracker
//
//  Horizontal scrolling 3-Day Forecast cards using actual forecast data
//

import SwiftUI

/// Horizontal scroll container for 3-day forecast cards
/// Now uses forecast data directly instead of powder day plans
struct HorizontalPowderOutlook: View {
    let mountains: [(mountain: Mountain, forecast: [ForecastDay])]

    var body: some View {
        if mountains.isEmpty {
            CardEmptyStateView(
                icon: "calendar.badge.clock",
                title: "No Forecast Data",
                message: "Add favorites to see 3-day outlook"
            )
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(mountains, id: \.mountain.id) { item in
                        Compact3DayCard(
                            mountain: item.mountain,
                            forecast: Array(item.forecast.prefix(3))
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

/// Compact card showing 3-day forecast for a single mountain
struct Compact3DayCard: View {
    let mountain: Mountain
    let forecast: [ForecastDay]

    private var totalSnow: Int {
        forecast.reduce(0) { $0 + Int($1.snowfall) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 6) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 20
                )

                Text(mountain.shortName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()

                // Total snow badge
                if totalSnow > 0 {
                    Text("\(totalSnow)\"")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.blue))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(.tertiarySystemBackground))

            // 3-day forecast rows
            if forecast.isEmpty {
                Text("No data")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(forecast.enumerated()), id: \.offset) { index, day in
                        dayRow(day, isFirst: index == 0)
                    }
                }
                .padding(8)
            }
        }
        .frame(width: 130)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusSmall)
    }

    private func dayRow(_ day: ForecastDay, isFirst: Bool) -> some View {
        HStack(spacing: 6) {
            // Day name
            Text(dayName(from: day.date, isFirst: isFirst))
                .font(.caption2)
                .fontWeight(.medium)
                .frame(width: 32, alignment: .leading)
                .foregroundColor(isFirst ? .primary : .secondary)

            // Weather icon
            Image(systemName: weatherIcon(for: day))
                .font(.system(size: 12))
                .foregroundColor(weatherColor(for: day))
                .frame(width: 16)

            Spacer()

            // High/Low temps
            HStack(spacing: 2) {
                Text("\(day.high)°")
                    .font(.caption2)
                    .foregroundColor(.primary)
                Text("/")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                Text("\(day.low)°")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Snowfall
            if day.snowfall > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 8))
                    Text("\(Int(day.snowfall))\"")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .frame(width: 28, alignment: .trailing)
            } else {
                Text("—")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 28, alignment: .trailing)
            }
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(day.snowfall >= 6 ? Color.blue.opacity(0.1) : Color.clear)
        )
    }

    private func dayName(from dateString: String, isFirst: Bool) -> String {
        if isFirst { return "Today" }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: String(dateString.prefix(10))) else {
            return "—"
        }

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        return dayFormatter.string(from: date)
    }

    private func weatherIcon(for day: ForecastDay) -> String {
        if day.snowfall >= 6 {
            return "cloud.snow.fill"
        } else if day.snowfall > 0 {
            return "cloud.snow"
        } else if day.precipProbability > 50 {
            return "cloud.fill"
        } else {
            return "sun.max.fill"
        }
    }

    private func weatherColor(for day: ForecastDay) -> Color {
        if day.snowfall >= 6 {
            return .blue
        } else if day.snowfall > 0 {
            return .cyan
        } else if day.precipProbability > 50 {
            return .gray
        } else {
            return .yellow
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        Text("3-Day Outlook")
            .font(.headline)
            .padding(.horizontal)

        HorizontalPowderOutlook(mountains: [])
    }
    .padding(.vertical)
    .background(Color(.systemGroupedBackground))
}
