import SwiftUI
import Charts

/// 7-day snow forecast chart showing all favorite mountains overlaid
/// Uses Swift Charts with multi-line visualization
struct SnowForecastChart: View {
    let favorites: [(mountain: Mountain, forecast: [ForecastDay])]
    var showHeader: Bool = false

    // Chart height
    private let chartHeight: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header (optional - parent views may provide their own)
            if showHeader {
                Text("7-Day Snow Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            if favorites.isEmpty {
                emptyState
            } else {
                chart
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(favorites, id: \.mountain.id) { favorite in
                // Get first 7 days of forecast with valid dates
                let sevenDayForecast = Array(favorite.forecast.prefix(7))

                ForEach(Array(sevenDayForecast.enumerated()), id: \.offset) { index, day in
                    // Convert date string to Date, fallback to index-based date
                    let chartDate = parseDate(day.date) ?? Calendar.current.date(byAdding: .day, value: index, to: Date())!

                    // Line mark for trend
                    LineMark(
                        x: .value("Day", chartDate),
                        y: .value("Snow", day.snowfall)
                    )
                    .foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    // Area fill below line
                    AreaMark(
                        x: .value("Day", chartDate),
                        y: .value("Snow", day.snowfall)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                mountainColor(for: favorite.mountain).opacity(0.3),
                                mountainColor(for: favorite.mountain).opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .frame(height: chartHeight)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(dayLabel(for: date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                // Try Double first (in case data comes as Double), then Int
                let snowfall: Int? = value.as(Int.self) ?? value.as(Double.self).map { Int($0) }
                if let snowfall = snowfall {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text("\(snowfall)\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartLegend(position: .bottom, spacing: 8) {
            HStack(spacing: 12) {
                ForEach(favorites, id: \.mountain.id) { favorite in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mountainColor(for: favorite.mountain))
                            .frame(width: 8, height: 8)

                        Text(favorite.mountain.shortName)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }

    /// Parse date string (YYYY-MM-DD format) to Date
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundStyle(.secondary)

            Text("No forecast data available")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: chartHeight)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    /// Get color for a mountain (use mountain's color if available, otherwise generate from name)
    private func mountainColor(for mountain: Mountain) -> Color {
        if let color = Color(hex: mountain.color) {
            return color
        }

        // Fallback colors if hex color not available
        let colors: [Color] = [.blue, .purple, .green, .orange, .red, .cyan, .indigo, .mint]
        let hash = abs(mountain.id.hashValue)
        return colors[hash % colors.count]
    }

    /// Format date to day label (Mon, Tue, Wed, etc.)
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        if isToday {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, Wed
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SnowForecastChart(
                favorites: []
            )
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
