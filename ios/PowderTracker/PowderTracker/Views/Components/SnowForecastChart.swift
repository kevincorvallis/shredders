import SwiftUI
import Charts

/// 7-day snow forecast chart showing all favorite mountains overlaid
/// Uses Swift Charts with multi-line visualization
struct SnowForecastChart: View {
    let favorites: [(mountain: Mountain, forecast: [ForecastDay])]
    var showHeader: Bool = false
    var onDayTap: ((Mountain, ForecastDay) -> Void)? = nil

    // Chart height - compact for homepage
    private let chartHeight: CGFloat = 160

    // Range toggle state
    @State private var selectedRange: ForecastRange = .sevenDays
    @State private var selectedDataPoint: (mountain: Mountain, day: ForecastDay)? = nil
    @State private var showingHourlySheet: Bool = false

    enum ForecastRange: String, CaseIterable {
        case threeDays = "3D"
        case sevenDays = "7D"
        case fifteenDays = "15D"

        var days: Int {
            switch self {
            case .threeDays: return 3
            case .sevenDays: return 7
            case .fifteenDays: return 15
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with range toggle
            headerWithToggle

            if favorites.isEmpty {
                emptyState
            } else {
                chart
            }
        }
        .sheet(isPresented: $showingHourlySheet) {
            if let selected = selectedDataPoint {
                HourlyBreakdownSheet(
                    mountain: selected.mountain,
                    day: selected.day,
                    isPresented: $showingHourlySheet
                )
            }
        }
    }

    // MARK: - Header with Range Toggle

    private var headerWithToggle: some View {
        HStack {
            if showHeader {
                Text("Snow Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Range toggle picker
            Picker("Range", selection: $selectedRange) {
                ForEach(ForecastRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(favorites, id: \.mountain.id) { favorite in
                // Get forecast based on selected range
                let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))

                ForEach(Array(forecastDays.enumerated()), id: \.offset) { index, day in
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
        .frame(minWidth: 100) // Prevent 0x0 CAMetalLayer error
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

// MARK: - Hourly Breakdown Sheet

struct HourlyBreakdownSheet: View {
    let mountain: Mountain
    let day: ForecastDay
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingL) {
                    // Day summary header
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text(day.dayOfWeek)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(day.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Summary stats
                    HStack(spacing: .spacingL) {
                        statCard(
                            icon: "snowflake",
                            value: "\(day.snowfall)\"",
                            label: "Expected Snow"
                        )

                        statCard(
                            icon: "thermometer.medium",
                            value: "\(day.high)°/\(day.low)°",
                            label: "High/Low"
                        )

                        statCard(
                            icon: "wind",
                            value: "\(day.wind.speed)mph",
                            label: "Wind"
                        )
                    }
                    .padding(.horizontal)

                    // Conditions
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Conditions")
                            .font(.headline)

                        HStack(spacing: .spacingS) {
                            Text(day.iconEmoji)
                                .font(.title)

                            Text(day.conditions)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                    .padding(.horizontal)

                    // Precipitation probability
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Precipitation")
                            .font(.headline)

                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("\(day.precipProbability)% chance of \(day.precipType)")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle(mountain.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SnowForecastChart(
                favorites: [],
                showHeader: true
            )
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
