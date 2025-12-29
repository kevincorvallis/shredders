import SwiftUI

/// OpenSnow-inspired snowfall tracker with fixed mountain name and scrollable timeline
struct OpenSnowStyleSnowfallView: View {
    @State private var viewModel = OpenSnowSnowfallViewModel()
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"

    let daysBack: Int
    let daysForward: Int

    init(daysBack: Int = 3, daysForward: Int = 7) {
        self.daysBack = daysBack
        self.daysForward = daysForward
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with totals
            header

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Main timeline content
                HStack(alignment: .top, spacing: 0) {
                    // Fixed mountain name section
                    mountainNameSection

                    // Scrollable timeline
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(viewModel.timelineData) { day in
                                timelineCell(day: day)
                            }
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .task(id: selectedMountainId) {
            await viewModel.loadData(
                for: selectedMountainId,
                daysBack: daysBack,
                daysForward: daysForward
            )
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Snowfall Tracker")
                    .font(.headline)
                    .fontWeight(.bold)

                if let totals = viewModel.totals {
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totals.past24h)\" (24h)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("\(totals.forecast7Day)\" (7d forecast)")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var mountainNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // "Mountain" label
            Text("Mountain")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(height: 30)

            // Mountain name with icon
            if let mountain = viewModel.mountain {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: mountain.color) ?? .blue)
                        .frame(width: 10, height: 10)

                    Text(mountain.shortName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
            } else {
                Text("Loading...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 100, alignment: .leading)
        .padding(.leading, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }

    private func timelineCell(day: TimelineDay) -> some View {
        VStack(spacing: 8) {
            // Date header
            VStack(spacing: 2) {
                Text(day.dayLabel)
                    .font(.caption2)
                    .fontWeight(day.isToday ? .bold : .semibold)
                    .foregroundColor(day.isToday ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        day.isToday ?
                            Color.blue : Color.clear
                    )
                    .cornerRadius(4)

                Text(day.dateLabel)
                    .font(.caption)
                    .fontWeight(day.isToday ? .bold : .regular)
                    .foregroundColor(day.isToday ? .blue : .primary)
            }
            .frame(height: 30)

            // Snowfall amount with visual indicator
            VStack(spacing: 4) {
                // Snowfall bar
                ZStack(alignment: .bottom) {
                    // Background bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 40, height: 60)

                    // Actual snowfall bar
                    if day.snowfall > 0 {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        snowfallColor(for: day.snowfall).opacity(0.8),
                                        snowfallColor(for: day.snowfall)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 40, height: min(CGFloat(day.snowfall) * 6, 60))
                            .opacity(day.isForecast ? 0.7 : 1.0)
                    }

                    // Snowfall text
                    Text(day.snowfall > 0 ? "\(day.snowfall)\"" : "—")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(day.snowfall > 0 ? .white : .secondary)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }

                // Forecast indicator
                if day.isForecast {
                    Text("fcst")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 60)
        .padding(.vertical, 12)
        .background(
            day.isToday ?
                Color.blue.opacity(0.05) : Color.clear
        )
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1),
            alignment: .trailing
        )
    }

    private func snowfallColor(for inches: Int) -> Color {
        switch inches {
        case 0: return .gray
        case 1...3: return .blue.opacity(0.6)
        case 4...8: return .blue.opacity(0.8)
        default: return .blue
        }
    }
}

// MARK: - Data Models

struct TimelineDay: Identifiable {
    let id = UUID()
    let date: Date
    let dayLabel: String      // "Mon", "Tue", "Today"
    let dateLabel: String      // "1/15"
    let snowfall: Int          // Inches
    let isToday: Bool
    let isForecast: Bool
}

struct SnowfallTotals {
    let past24h: Int
    let past72h: Int
    let forecast7Day: Int
}

// MARK: - ViewModel

@MainActor
@Observable
class OpenSnowSnowfallViewModel {
    var mountain: Mountain?
    var timelineData: [TimelineDay] = []
    var totals: SnowfallTotals?
    var isLoading = false
    var error: String?

    func loadData(for mountainId: String, daysBack: Int, daysForward: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load mountain info
            let mountainsResponse = try await APIClient.shared.fetchMountains()
            mountain = mountainsResponse.mountains.first { $0.id == mountainId }

            // Generate date range
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let dateRange = (-daysBack...daysForward).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: today)
            }

            // Load historical data
            var snowfallByDate: [Date: Int] = [:]
            if let historyResponse = try? await APIClient.shared.fetchHistory(
                for: mountainId,
                days: daysBack + 1
            ) {
                for dataPoint in historyResponse.history {
                    if let date = ISO8601DateFormatter().date(from: dataPoint.date) {
                        let startOfDay = calendar.startOfDay(for: date)
                        snowfallByDate[startOfDay] = dataPoint.snowfall
                    }
                }
            }

            // Load forecast data
            if let forecastResponse = try? await APIClient.shared.fetchForecast(for: mountainId) {
                for day in forecastResponse.forecast {
                    if let date = ISO8601DateFormatter().date(from: day.date) {
                        let startOfDay = calendar.startOfDay(for: date)
                        snowfallByDate[startOfDay] = day.snowfall
                    }
                }
            }

            // Build timeline
            timelineData = dateRange.map { date in
                let isToday = calendar.isDateInToday(date)
                let isForecast = date > Date()

                let dayLabel: String
                if isToday {
                    dayLabel = "Today"
                } else {
                    dayLabel = date.formatted(.dateTime.weekday(.abbreviated))
                }

                let dateLabel = date.formatted(.dateTime.month().day())
                let snowfall = snowfallByDate[date] ?? 0

                return TimelineDay(
                    date: date,
                    dayLabel: dayLabel,
                    dateLabel: dateLabel,
                    snowfall: snowfall,
                    isToday: isToday,
                    isForecast: isForecast
                )
            }

            // Calculate totals
            let past24h = timelineData
                .filter { calendar.isDateInToday($0.date) }
                .reduce(0) { $0 + $1.snowfall }

            let past72h = timelineData
                .filter { !$0.isForecast && calendar.dateComponents([.day], from: $0.date, to: today).day ?? 0 <= 3 }
                .reduce(0) { $0 + $1.snowfall }

            let forecast7Day = timelineData
                .filter { $0.isForecast }
                .reduce(0) { $0 + $1.snowfall }

            totals = SnowfallTotals(
                past24h: past24h,
                past72h: past72h,
                forecast7Day: forecast7Day
            )

        } catch {
            self.error = "Failed to load snowfall data: \(error.localizedDescription)"
        }
    }
}

#Preview {
    OpenSnowStyleSnowfallView()
        .padding()
}
