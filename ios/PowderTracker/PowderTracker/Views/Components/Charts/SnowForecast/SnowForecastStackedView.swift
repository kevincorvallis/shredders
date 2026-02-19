import SwiftUI

/// Stacked vertical snow forecast view — all mountains as rows in a single card,
/// with shared day labels at the top and bar charts aligned across rows.
/// The name column is fixed; the bar area scrolls horizontally showing ~3 days at a time.
struct SnowForecastStackedView: View {
    let favorites: [(mountain: Mountain, forecast: [ForecastDay])]
    var onMountainTap: ((Mountain) -> Void)? = nil

    private let nameColumnWidth: CGFloat = 80
    private let dayColumnWidth: CGFloat = 36
    private let barWidth: CGFloat = 26
    private let maxBarHeight: CGFloat = 34
    private let fadeWidth: CGFloat = 20

    /// All mountains sorted by total snowfall descending (across all 10 days)
    private var sortedFavorites: [(mountain: Mountain, forecast: [ForecastDay])] {
        favorites.sorted { a, b in
            let aTotal = a.forecast.reduce(0) { $0 + $1.snowfall }
            let bTotal = b.forecast.reduce(0) { $0 + $1.snowfall }
            return aTotal > bTotal
        }
    }

    /// Global max snowfall across all mountains for proportional scaling
    private var globalMax: Int {
        let maxVal = favorites.flatMap(\.forecast)
            .map(\.snowfall)
            .max() ?? 1
        return max(maxVal, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Snow Forecast", icon: "snowflake", iconColor: .blue)

            if favorites.isEmpty {
                emptyState
            } else {
                cardContent
            }
        }
    }

    // MARK: - Card

    private var cardContent: some View {
        HStack(alignment: .top, spacing: 0) {
            // Fixed left column: spacer for day labels + mountain names
            fixedColumn

            // Scrollable bar area with trailing fade hint
            ScrollView(.horizontal, showsIndicators: false) {
                scrollableContent
            }
            .mask(
                HStack(spacing: 0) {
                    Color.black
                    LinearGradient(
                        stops: [
                            .init(color: .black, location: 0),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: fadeWidth)
                }
            )
        }
        .padding(.horizontal, .spacingM)
        .padding(.vertical, .spacingS)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .strokeBorder(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Fixed Column

    private var fixedColumn: some View {
        VStack(spacing: 0) {
            // Spacer matching day labels height
            Color.clear
                .frame(height: dayLabelHeight)
                .padding(.bottom, 4)

            // Mountain name rows
            ForEach(Array(sortedFavorites.enumerated()), id: \.element.mountain.id) { index, fav in
                let total = fav.forecast.reduce(0) { $0 + $1.snowfall }
                let isTop = index == 0 && total > 0
                let accentColor = Color(hex: fav.mountain.color) ?? .blue

                Button {
                    onMountainTap?(fav.mountain)
                    HapticFeedback.light.trigger()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            if isTop {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.orange)
                            } else {
                                Circle()
                                    .fill(accentColor)
                                    .frame(width: 6, height: 6)
                            }

                            Text(fav.mountain.shortName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }

                        if total > 0 {
                            totalPill(total: total, color: accentColor)
                                .padding(.leading, 10)
                        }
                    }
                    .frame(height: rowHeight, alignment: .leading)
                }
                .buttonStyle(.plain)
                .background(rowBackground(at: index))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(fav.mountain.name), \(total) inches total")

                if index < sortedFavorites.count - 1 {
                    Divider()
                }
            }
        }
        .frame(width: nameColumnWidth)
    }

    // MARK: - Total Pill

    private func totalPill(total: Int, color: Color) -> some View {
        Text("\(total)\"")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    // MARK: - Scrollable Content

    private var scrollableContent: some View {
        let sampleForecast = sortedFavorites.first?.forecast ?? []

        return VStack(spacing: 0) {
            // Day labels row
            HStack(spacing: 0) {
                ForEach(Array(sampleForecast.enumerated()), id: \.offset) { _, day in
                    dayLabel(for: day)
                        .frame(width: dayColumnWidth)
                        .background(columnBackground(for: day))
                }
            }
            .frame(height: dayLabelHeight)
            .padding(.bottom, 4)

            // Bar rows
            ForEach(Array(sortedFavorites.enumerated()), id: \.element.mountain.id) { index, fav in
                let accentColor = Color(hex: fav.mountain.color) ?? .blue

                HStack(spacing: 0) {
                    ForEach(Array(fav.forecast.enumerated()), id: \.offset) { _, day in
                        barCell(day: day, accentColor: accentColor)
                            .frame(width: dayColumnWidth)
                            .background(columnBackground(for: day))
                    }
                }
                .frame(height: rowHeight)
                .background(rowBackground(at: index))

                if index < sortedFavorites.count - 1 {
                    Divider()
                }
            }
        }
    }

    // MARK: - Row Background

    private func rowBackground(at index: Int) -> Color {
        index.isMultiple(of: 2) ? .clear : Color(.systemGray5).opacity(0.25)
    }

    // MARK: - Column Background

    private func columnBackground(for day: ForecastDay) -> Color {
        if isDateToday(day.date) {
            return .blue.opacity(0.08)
        } else if isWeekend(day.dayOfWeek) {
            return Color(.systemGray5).opacity(0.4)
        }
        return .clear
    }

    // MARK: - Day Label

    private let dayLabelHeight: CGFloat = 16

    private func dayLabel(for day: ForecastDay) -> some View {
        let isToday = isDateToday(day.date)

        return Text(isToday ? "Today" : String(day.dayOfWeek.prefix(3)))
            .font(.system(size: 10, weight: isToday ? .bold : .medium))
            .foregroundStyle(isToday ? .blue : .secondary)
    }

    /// Total row height: bar + label
    private var rowHeight: CGFloat {
        maxBarHeight + 12
    }

    // MARK: - Bar Cell

    private func barCell(day: ForecastDay, accentColor: Color) -> some View {
        let snowfall = day.snowfall
        let height: CGFloat = snowfall > 0
            ? max(CGFloat(snowfall) / CGFloat(globalMax) * maxBarHeight, 4)
            : 2
        let isPowder = snowfall >= 6

        return VStack(spacing: 1) {
            if snowfall > 0 {
                Text("\(snowfall)")
                    .font(.system(size: 9, weight: snowfall >= 3 ? .bold : .medium))
                    .foregroundStyle(barLabelColor(for: snowfall, accent: accentColor))
            } else {
                Text("\u{2013}")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(.systemGray4))
            }

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(barFill(for: snowfall, accent: accentColor))
                    .frame(width: barWidth, height: height)

                if isPowder {
                    Image(systemName: "snowflake")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .offset(y: 3)
                }
            }
        }
        .frame(height: rowHeight)
    }

    // MARK: - Bar Styling

    private func barFill(for snowfall: Int, accent: Color) -> AnyShapeStyle {
        if snowfall >= 8 {
            // Epic day — cyan→blue gradient (matches InteractiveBarChart)
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.cyan, Color.blue],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        } else if snowfall >= 6 {
            return AnyShapeStyle(accent.opacity(0.9))
        } else if snowfall >= 3 {
            return AnyShapeStyle(accent.opacity(0.6))
        } else if snowfall > 0 {
            return AnyShapeStyle(accent.opacity(0.35))
        } else {
            return AnyShapeStyle(Color(.systemGray4))
        }
    }

    private func barLabelColor(for snowfall: Int, accent: Color) -> Color {
        if snowfall >= 8 {
            return .cyan
        } else if snowfall >= 6 {
            return accent
        } else {
            return .secondary
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "snowflake")
                .font(.largeTitle)
                .foregroundStyle(.blue.opacity(0.4))

            Text("Add favorites to see forecasts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
    }

    // MARK: - Date Helpers

    private static let dateParser: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    private func isDateToday(_ dateString: String) -> Bool {
        guard let date = Self.dateParser.date(from: dateString) else { return false }
        return Calendar.current.isDateInToday(date)
    }

    private func isWeekend(_ dayOfWeek: String) -> Bool {
        dayOfWeek == "Saturday" || dayOfWeek == "Sunday"
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        SnowForecastStackedView(
            favorites: [
                (mountain: .mock, forecast: ForecastDay.mockWeek),
                (mountain: Mountain.mockMountains[1], forecast: ForecastDay.mockWeek),
                (mountain: Mountain.mockMountains[2], forecast: ForecastDay.mockWeek),
            ]
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
