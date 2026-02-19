import SwiftUI

/// OpenSnow-style snow forecast card for a single mountain.
/// Shows vertical bar chart with daily snowfall, period totals with bracket lines,
/// and color-coded bars by intensity.
struct SnowForecastCardView: View {
    let mountain: Mountain
    let forecast: [ForecastDay]
    var daysToShow: Int = 10
    var onTap: (() -> Void)? = nil

    private let barWidth: CGFloat = 28
    private let maxBarHeight: CGFloat = 80
    private let powderThreshold = 6

    private var days: [ForecastDay] {
        Array(forecast.prefix(daysToShow))
    }

    private var maxSnowfall: Int {
        max(days.map(\.snowfall).max() ?? 1, 1)
    }

    private var totalSnowfall: Int {
        days.reduce(0) { $0 + $1.snowfall }
    }

    private var mountainAccentColor: Color {
        Color(hex: mountain.color) ?? .blue
    }

    var body: some View {
        Button {
            onTap?()
            HapticFeedback.light.trigger()
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mountain.name) snow forecast. \(totalSnowfall) inches total over \(days.count) days.")
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Mountain header
            header

            if totalSnowfall > 0 {
                // Period bracket totals
                periodBrackets

                // Bar chart
                barChart
            } else {
                noSnowState
            }

            // Day labels
            dayLabels
        }
        .padding(.spacingM)
        .frame(width: CGFloat(days.count) * (barWidth + 6) + 28)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .strokeBorder(mountainAccentColor.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacingS) {
            Circle()
                .fill(mountainAccentColor)
                .frame(width: 10, height: 10)

            Text(mountain.shortName)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)

            Spacer()

            if totalSnowfall > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(mountainAccentColor)

                    Text("\(totalSnowfall)\"")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(mountainAccentColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(mountainAccentColor.opacity(0.12))
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Period Brackets

    private var periodBrackets: some View {
        let midpoint = min(5, days.count)
        let firstHalf = days.prefix(midpoint)
        let secondHalf = days.dropFirst(midpoint)
        let firstTotal = firstHalf.reduce(0) { $0 + $1.snowfall }
        let secondTotal = secondHalf.reduce(0) { $0 + $1.snowfall }

        return HStack(spacing: 0) {
            if firstTotal > 0 {
                bracketView(total: firstTotal, count: firstHalf.count)
            } else {
                Color.clear.frame(width: CGFloat(firstHalf.count) * (barWidth + 6))
            }

            if !secondHalf.isEmpty {
                if secondTotal > 0 {
                    bracketView(total: secondTotal, count: secondHalf.count)
                } else {
                    Color.clear.frame(width: CGFloat(secondHalf.count) * (barWidth + 6))
                }
            }
        }
    }

    private func bracketView(total: Int, count: Int) -> some View {
        let width = CGFloat(count) * (barWidth + 6)

        return VStack(spacing: 2) {
            Text("\(total)\"")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.primary)

            // Bracket line
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 6)

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(height: 1)

                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 1, height: 6)
            }
        }
        .frame(width: width)
    }

    // MARK: - Bar Chart

    private var barChart: some View {
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                barColumn(for: day)
            }
        }
    }

    private func barColumn(for day: ForecastDay) -> some View {
        let height = day.snowfall > 0
            ? max(CGFloat(day.snowfall) / CGFloat(maxSnowfall) * maxBarHeight, 6)
            : 2
        let isPowder = day.snowfall >= powderThreshold

        return VStack(spacing: 3) {
            // Snowfall label above bar
            if day.snowfall > 0 {
                Text("\(day.snowfall)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(barLabelColor(for: day.snowfall))
            } else {
                Text("\u{2014}")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(.systemGray4))
            }

            // Bar with optional powder indicator
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: .cornerRadiusTiny)
                    .fill(barGradient(for: day.snowfall))
                    .frame(width: barWidth, height: height)

                if isPowder {
                    Image(systemName: "snowflake")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                        .offset(y: 4)
                }
            }
        }
    }

    private func barGradient(for snowfall: Int) -> LinearGradient {
        let colors: [Color]
        if snowfall >= 8 {
            // Heavy snow - warm orange/coral
            colors = [.orange, Color(red: 0.95, green: 0.4, blue: 0.3)]
        } else if snowfall >= powderThreshold {
            // Powder day - blue-orange blend
            colors = [mountainAccentColor.opacity(0.8), .orange.opacity(0.7)]
        } else if snowfall >= 3 {
            // Moderate snow - blue
            colors = [mountainAccentColor.opacity(0.5), mountainAccentColor.opacity(0.8)]
        } else if snowfall > 0 {
            // Light snow - soft purple/lavender
            colors = [Color.purple.opacity(0.3), Color.purple.opacity(0.5)]
        } else {
            // No snow - thin gray
            colors = [Color(.systemGray4), Color(.systemGray4)]
        }
        return LinearGradient(colors: colors, startPoint: .bottom, endPoint: .top)
    }

    private func barLabelColor(for snowfall: Int) -> Color {
        if snowfall >= 8 {
            return .orange
        } else if snowfall >= powderThreshold {
            return mountainAccentColor
        } else {
            return .secondary
        }
    }

    // MARK: - Day Labels

    private var dayLabels: some View {
        HStack(alignment: .top, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let isToday = isDateToday(day.date)

                VStack(spacing: 1) {
                    Text(isToday ? "Today" : String(day.dayOfWeek.prefix(3)))
                        .font(.system(size: isToday ? 9 : 10, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? mountainAccentColor : .secondary)

                    if !isToday {
                        Text(dayNumber(from: day.date))
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(width: barWidth)
            }
        }
    }

    // MARK: - No Snow State

    private var noSnowState: some View {
        VStack(spacing: .spacingS) {
            Image(systemName: "sun.max.fill")
                .font(.title2)
                .foregroundStyle(.orange.opacity(0.6))

            Text("No snow expected")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: maxBarHeight)
    }

    // MARK: - Helpers

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private func dayNumber(from dateString: String) -> String {
        guard let date = Self.dateParser.date(from: dateString) else {
            return ""
        }
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: date))"
    }

    private func isDateToday(_ dateString: String) -> Bool {
        guard let date = Self.dateParser.date(from: dateString) else { return false }
        return Calendar.current.isDateInToday(date)
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 12) {
            SnowForecastCardView(
                mountain: .mock,
                forecast: ForecastDay.mockWeek
            )

            SnowForecastCardView(
                mountain: .mock,
                forecast: []
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
