import SwiftUI

struct SnowfallTableView: View {
    @State private var viewModel = SnowfallTableViewModel()
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"

    let daysBack: Int
    let daysForward: Int

    init(daysBack: Int = 7, daysForward: Int = 7) {
        self.daysBack = daysBack
        self.daysForward = daysForward
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("Snowfall Tracker")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                // Legend
                HStack(spacing: 8) {
                    legendItem(color: .gray.opacity(0.3), label: "0\"")
                    legendItem(color: .blue.opacity(0.3), label: "1-3\"")
                    legendItem(color: .blue.opacity(0.6), label: "4-8\"")
                    legendItem(color: .blue, label: "9+\"")
                }
                .font(.caption2)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                // Scrollable Table
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        // Fixed Mountain Names Column
                        VStack(alignment: .leading, spacing: 0) {
                            // Header Cell
                            Text("Mountain")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 120, height: 40)
                                .padding(.horizontal, 8)

                            // Mountain Names
                            ForEach(viewModel.mountains) { mountain in
                                Button {
                                    selectedMountainId = mountain.id
                                } label: {
                                    HStack(spacing: 8) {
                                        // Mountain color indicator
                                        Circle()
                                            .fill(Color(hex: mountain.color) ?? .blue)
                                            .frame(width: 8, height: 8)

                                        Text(mountain.shortName)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 120, height: 50, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .background(
                                        selectedMountainId == mountain.id ?
                                            Color.blue.opacity(0.1) : Color.clear
                                    )
                                }
                            }
                        }
                        .background(Color(.systemGroupedBackground))

                        // Scrollable Data Area
                        VStack(alignment: .leading, spacing: 0) {
                            // Date Headers
                            HStack(spacing: 0) {
                                ForEach(viewModel.dateRange, id: \.self) { date in
                                    dateHeader(for: date)
                                }
                            }

                            // Snowfall Data Grid
                            ForEach(viewModel.mountains) { mountain in
                                HStack(spacing: 0) {
                                    ForEach(viewModel.dateRange, id: \.self) { date in
                                        snowfallCell(mountain: mountain, date: date)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
        .task {
            await viewModel.loadData(daysBack: daysBack, daysForward: daysForward)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
            Text(label)
        }
    }

    private func dateHeader(for date: Date) -> some View {
        let isToday = Calendar.current.isDateInToday(date)
        let dayOfWeek = date.formatted(.dateTime.weekday(.abbreviated))
        let dayOfMonth = date.formatted(.dateTime.day())

        return VStack(spacing: 2) {
            Text(dayOfWeek)
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .blue : .secondary)

            Text(dayOfMonth)
                .font(.caption)
                .fontWeight(isToday ? .bold : .semibold)
                .foregroundColor(isToday ? .blue : .primary)
        }
        .frame(width: 60, height: 40)
        .background(isToday ? Color.blue.opacity(0.1) : Color.clear)
    }

    private func snowfallCell(mountain: Mountain, date: Date) -> some View {
        let snowfall = viewModel.getSnowfall(for: mountain.id, date: date)
        let isForecast = date > Date()
        let isToday = Calendar.current.isDateInToday(date)

        return VStack {
            if let inches = snowfall {
                Text("\(inches)\"")
                    .font(.caption)
                    .fontWeight(isForecast ? .regular : .semibold)
                    .foregroundColor(isForecast ? .secondary : .primary)
            } else {
                Text("—")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 60, height: 50)
        .background(snowfallColor(for: snowfall))
        .border(Color(.separator), width: 0.5)
        .opacity(isForecast ? 0.7 : 1.0)
        .overlay(
            isToday ?
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.blue, lineWidth: 2)
                : nil
        )
    }

    private func snowfallColor(for inches: Int?) -> Color {
        guard let inches = inches else { return .gray.opacity(0.1) }

        switch inches {
        case 0: return .gray.opacity(0.3)
        case 1...3: return .blue.opacity(0.3)
        case 4...8: return .blue.opacity(0.6)
        default: return .blue
        }
    }
}

// MARK: - ViewModel

@MainActor
@Observable
class SnowfallTableViewModel {
    var mountains: [Mountain] = []
    var snowfallData: [String: [Date: Int]] = [:] // mountainId -> date -> inches
    var dateRange: [Date] = []
    var isLoading = false
    var error: String?

    func loadData(daysBack: Int, daysForward: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load all mountains
            let response = try await APIClient.shared.fetchMountains()
            mountains = response.mountains

            // Generate date range
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            dateRange = (-daysBack...daysForward).compactMap { offset in
                calendar.date(byAdding: .day, value: offset, to: today)
            }

            // Load snowfall data for each mountain
            for mountain in mountains {
                await loadSnowfallData(for: mountain.id, daysBack: daysBack, daysForward: daysForward)
            }
        } catch {
            self.error = "Failed to load snowfall data: \(error.localizedDescription)"
        }
    }

    private func loadSnowfallData(for mountainId: String, daysBack: Int, daysForward: Int) async {
        // Load history
        if let historyResponse = try? await APIClient.shared.fetchHistory(
            for: mountainId,
            days: daysBack + 1
        ) {
            var mountainData: [Date: Int] = [:]

            for dataPoint in historyResponse.history {
                if let date = ISO8601DateFormatter().date(from: dataPoint.date) {
                    let startOfDay = Calendar.current.startOfDay(for: date)
                    mountainData[startOfDay] = dataPoint.snowfall
                }
            }

            snowfallData[mountainId] = mountainData
        }

        // Load forecast
        if let forecastResponse = try? await APIClient.shared.fetchForecast(
            for: mountainId
        ) {
            var mountainData = snowfallData[mountainId] ?? [:]

            for day in forecastResponse.forecast {
                if let date = ISO8601DateFormatter().date(from: day.date) {
                    let startOfDay = Calendar.current.startOfDay(for: date)
                    mountainData[startOfDay] = day.snowfall
                }
            }

            snowfallData[mountainId] = mountainData
        }
    }

    func getSnowfall(for mountainId: String, date: Date) -> Int? {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return snowfallData[mountainId]?[startOfDay]
    }
}

#Preview {
    SnowfallTableView()
        .padding()
}
