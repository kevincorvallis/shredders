import SwiftUI

/// A polished card showing powder day suggestions when creating events
/// Displays forecast strip, best day suggestion, and mountain comparison
struct PowderDaySuggestionCard: View {
    let forecasts: [ForecastDay]
    let selectedDate: Date
    let selectedMountainId: String
    let mountainName: String
    let onSelectDate: (ForecastDay) -> Void
    let onSelectMountain: ((id: String, name: String, forecast: ForecastDay)) -> Void

    // Mountain comparisons
    var mountainComparisons: [(id: String, name: String, forecast: ForecastDay)] = []
    var isLoadingComparisons: Bool = false

    @State private var showAllDays = false

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }

    private var selectedDateStr: String {
        dateFormatter.string(from: selectedDate)
    }

    private var todayStr: String {
        dateFormatter.string(from: Date())
    }

    /// Best powder day from forecasts (future only, excluding selected)
    private var bestPowderDay: ForecastDay? {
        forecasts
            .filter { $0.date >= todayStr && $0.date != selectedDateStr }
            .filter { $0.snowfall >= 3 || ($0.precipProbability >= 60 && $0.precipType == "snow") }
            .max { scoreForecast($0) < scoreForecast($1) }
    }

    /// Absolute best option across all mountains and days
    private var smartPick: (mountain: (id: String, name: String), day: ForecastDay)? {
        // Check current mountain's best day
        var bestScore = 0
        var bestOption: (mountain: (id: String, name: String), day: ForecastDay)?

        if let best = bestPowderDay {
            let score = scoreForecast(best)
            if score > bestScore {
                bestScore = score
                bestOption = (mountain: (id: selectedMountainId, name: mountainName), day: best)
            }
        }

        // Check other mountains
        for comparison in mountainComparisons {
            let score = scoreForecast(comparison.forecast)
            if score > bestScore {
                bestScore = score
                bestOption = (mountain: (id: comparison.id, name: comparison.name), day: comparison.forecast)
            }
        }

        // Only return if significantly better than current selection
        if let current = forecasts.first(where: { $0.date == selectedDateStr }) {
            let currentScore = scoreForecast(current)
            if bestScore <= currentScore + 15 {
                return nil // Not significantly better
            }
        }

        return bestOption
    }

    var body: some View {
        VStack(spacing: .spacingM) {
            // Smart Pick Banner (if there's a significantly better option)
            if let pick = smartPick {
                smartPickBanner(pick)
            }

            // 7-Day Forecast Strip
            forecastStrip

            // Mountain Leaderboard (if we have comparison data)
            if !mountainComparisons.isEmpty {
                mountainLeaderboard
            }
        }
    }

    // MARK: - Smart Pick Banner

    private func smartPickBanner(_ pick: (mountain: (id: String, name: String), day: ForecastDay)) -> some View {
        Button {
            HapticFeedback.medium.trigger()

            // Switch to best mountain if different
            if pick.mountain.id != selectedMountainId {
                onSelectMountain((id: pick.mountain.id, name: pick.mountain.name, forecast: pick.day))
            } else {
                onSelectDate(pick.day)
            }
        } label: {
            HStack(spacing: .spacingM) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .shadow(color: .cyan.opacity(0.4), radius: 8, y: 2)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Smart Pick")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)

                    HStack(spacing: 4) {
                        if pick.mountain.id != selectedMountainId {
                            Text(pick.mountain.name)
                                .fontWeight(.medium)
                        }
                        Text(pick.day.dayOfWeek)
                        Text("•")
                        HStack(spacing: 2) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 10))
                            Text("\(pick.day.snowfall)\"")
                        }
                        .foregroundColor(.cyan)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Apply button
                Text("Apply")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingS)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }
            .padding(.spacingM)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: .cornerRadiusCard)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.5), .blue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Forecast Strip

    private var forecastStrip: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text("7-Day Outlook")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if let totalSnow = totalExpectedSnow, totalSnow > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "snowflake")
                            .font(.caption2)
                        Text("\(totalSnow)\" expected")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.cyan)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingS) {
                    ForEach(forecasts.prefix(7), id: \.date) { day in
                        forecastDayCell(day)
                    }
                }
            }
        }
    }

    private var totalExpectedSnow: Int? {
        let total = forecasts.prefix(7).reduce(0) { $0 + $1.snowfall }
        return total > 0 ? total : nil
    }

    private func forecastDayCell(_ day: ForecastDay) -> some View {
        let isSelected = day.date == selectedDateStr
        let isBestDay = day.date == bestPowderDay?.date
        let isPowderDay = day.snowfall >= 6
        let hasSnow = day.snowfall > 0

        return Button {
            HapticFeedback.selection.trigger()
            onSelectDate(day)
        } label: {
            VStack(spacing: .spacingXS) {
                // Day name
                Text(shortDayName(day.dayOfWeek))
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .secondary)

                // Weather icon
                ZStack {
                    if isPowderDay {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 36, height: 36)
                    } else if hasSnow {
                        Circle()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 36, height: 36)
                    } else {
                        Circle()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 36, height: 36)
                    }

                    if hasSnow {
                        Image(systemName: isPowderDay ? "snowflake.circle.fill" : "snowflake")
                            .font(.system(size: isPowderDay ? 20 : 16))
                            .foregroundColor(isPowderDay ? .white : .cyan)
                            .symbolEffect(.variableColor, isActive: isPowderDay)
                    } else {
                        Text(day.iconEmoji)
                            .font(.system(size: 16))
                    }
                }

                // Snowfall amount
                if hasSnow {
                    Text("\(day.snowfall)\"")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(isPowderDay ? .cyan : .primary)
                } else {
                    Text("—")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 52)
            .padding(.vertical, .spacingS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .stroke(isBestDay && !isSelected ? Color.cyan : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func shortDayName(_ dayOfWeek: String) -> String {
        let mapping: [String: String] = [
            "Monday": "Mon",
            "Tuesday": "Tue",
            "Wednesday": "Wed",
            "Thursday": "Thu",
            "Friday": "Fri",
            "Saturday": "Sat",
            "Sunday": "Sun",
            "Today": "Today"
        ]
        return mapping[dayOfWeek] ?? String(dayOfWeek.prefix(3))
    }

    // MARK: - Mountain Leaderboard

    private var mountainLeaderboard: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text("Top Mountains for \(selectedDateDisplay)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Spacer()

                if isLoadingComparisons {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            VStack(spacing: .spacingS) {
                // Current mountain
                mountainComparisonRow(
                    rank: nil,
                    name: mountainName,
                    forecast: forecasts.first { $0.date == selectedDateStr },
                    isSelected: true,
                    onTap: nil
                )

                // Other mountains
                ForEach(Array(mountainComparisons.enumerated()), id: \.element.id) { index, comparison in
                    mountainComparisonRow(
                        rank: index + 1,
                        name: comparison.name,
                        forecast: comparison.forecast,
                        isSelected: false,
                        onTap: {
                            HapticFeedback.selection.trigger()
                            onSelectMountain(comparison)
                        }
                    )
                }
            }
        }
    }

    private var selectedDateDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: selectedDate)
    }

    private func mountainComparisonRow(
        rank: Int?,
        name: String,
        forecast: ForecastDay?,
        isSelected: Bool,
        onTap: (() -> Void)?
    ) -> some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: .spacingM) {
                // Rank badge or checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                        .frame(width: 24)
                } else if let rank = rank {
                    Text("\(rank)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(rank == 1 ? Color.purple : Color.secondary)
                        )
                        .frame(width: 24)
                }

                // Mountain name
                Text(name)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)

                Spacer()

                // Forecast info
                if let forecast = forecast {
                    HStack(spacing: .spacingS) {
                        // Snowfall
                        HStack(spacing: 2) {
                            Image(systemName: "snowflake")
                                .font(.system(size: 10))
                            Text("\(forecast.snowfall)\"")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(forecast.snowfall >= 6 ? .cyan : (forecast.snowfall > 0 ? .blue : .secondary))

                        // Temp
                        Text("\(forecast.high)°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Switch button (for non-selected)
                    if !isSelected {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No forecast")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.tertiarySystemFill))
            )
        }
        .buttonStyle(.plain)
        .disabled(isSelected || onTap == nil)
    }

    // MARK: - Scoring

    private func scoreForecast(_ day: ForecastDay) -> Int {
        var score = 0

        // Snowfall is most important
        score += day.snowfall * 10

        // Fresh snow bonuses
        if day.snowfall >= 6 { score += 20 }
        if day.snowfall >= 12 { score += 30 }

        // Cold temps
        if day.high < 32 { score += 10 }
        if day.high < 28 { score += 5 }

        // High precip probability
        if day.precipProbability >= 70 && day.precipType == "snow" {
            score += 15
        }

        // Wind penalty
        if day.wind.gust > 40 { score -= 10 }
        if day.wind.gust > 50 { score -= 15 }

        return score
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            PowderDaySuggestionCard(
                forecasts: [
                    ForecastDay(
                        date: "2026-02-03",
                        dayOfWeek: "Today",
                        high: 32,
                        low: 24,
                        snowfall: 2,
                        precipProbability: 40,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 15, gust: 25),
                        conditions: "Cloudy",
                        icon: "cloudy"
                    ),
                    ForecastDay(
                        date: "2026-02-04",
                        dayOfWeek: "Tuesday",
                        high: 28,
                        low: 20,
                        snowfall: 8,
                        precipProbability: 80,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 20, gust: 35),
                        conditions: "Snow",
                        icon: "snow"
                    ),
                    ForecastDay(
                        date: "2026-02-05",
                        dayOfWeek: "Wednesday",
                        high: 30,
                        low: 22,
                        snowfall: 0,
                        precipProbability: 20,
                        precipType: "none",
                        wind: ForecastDay.ForecastWind(speed: 10, gust: 15),
                        conditions: "Partly Cloudy",
                        icon: "partly_cloudy"
                    ),
                    ForecastDay(
                        date: "2026-02-06",
                        dayOfWeek: "Thursday",
                        high: 34,
                        low: 26,
                        snowfall: 0,
                        precipProbability: 10,
                        precipType: "none",
                        wind: ForecastDay.ForecastWind(speed: 8, gust: 12),
                        conditions: "Sunny",
                        icon: "sunny"
                    ),
                    ForecastDay(
                        date: "2026-02-07",
                        dayOfWeek: "Friday",
                        high: 26,
                        low: 18,
                        snowfall: 12,
                        precipProbability: 90,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 25, gust: 40),
                        conditions: "Heavy Snow",
                        icon: "snow"
                    ),
                    ForecastDay(
                        date: "2026-02-08",
                        dayOfWeek: "Saturday",
                        high: 28,
                        low: 20,
                        snowfall: 4,
                        precipProbability: 60,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 15, gust: 20),
                        conditions: "Snow Showers",
                        icon: "snow_showers"
                    ),
                    ForecastDay(
                        date: "2026-02-09",
                        dayOfWeek: "Sunday",
                        high: 32,
                        low: 24,
                        snowfall: 1,
                        precipProbability: 30,
                        precipType: "none",
                        wind: ForecastDay.ForecastWind(speed: 10, gust: 15),
                        conditions: "Mostly Cloudy",
                        icon: "cloudy"
                    )
                ],
                selectedDate: Date(),
                selectedMountainId: "baker",
                mountainName: "Mt. Baker",
                onSelectDate: { _ in },
                onSelectMountain: { _ in },
                mountainComparisons: [
                    (id: "crystal", name: "Crystal Mountain", forecast: ForecastDay(
                        date: "2026-02-03",
                        dayOfWeek: "Today",
                        high: 30,
                        low: 22,
                        snowfall: 6,
                        precipProbability: 70,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 12, gust: 20),
                        conditions: "Snow",
                        icon: "snow"
                    )),
                    (id: "stevens", name: "Stevens Pass", forecast: ForecastDay(
                        date: "2026-02-03",
                        dayOfWeek: "Today",
                        high: 28,
                        low: 20,
                        snowfall: 3,
                        precipProbability: 50,
                        precipType: "snow",
                        wind: ForecastDay.ForecastWind(speed: 18, gust: 30),
                        conditions: "Light Snow",
                        icon: "snow_showers"
                    ))
                ]
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
