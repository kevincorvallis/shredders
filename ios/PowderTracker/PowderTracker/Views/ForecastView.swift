import SwiftUI

struct ForecastView: View {
    @State private var viewModel = ForecastViewModel()

    var body: some View {
        List {
            if viewModel.isLoading && viewModel.forecast.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(Array(viewModel.forecast.enumerated()), id: \.element.id) { index, day in
                        ForecastDayRow(day: day, isToday: index == 0)
                    }
                } header: {
                    HStack {
                        Text("7-Day Forecast")
                        Spacer()
                        Text("Mt. Baker")
                            .foregroundColor(.secondary)
                    }
                }

                if !viewModel.forecast.isEmpty {
                    Section {
                        snowfallSummary
                    } header: {
                        Text("Snowfall Summary")
                    }
                }
            }
        }
        .navigationTitle("Forecast")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadForecast()
        }
        .task {
            if viewModel.forecast.isEmpty {
                await viewModel.loadForecast()
            }
        }
    }

    private var snowfallSummary: some View {
        let totalSnow = viewModel.forecast.reduce(0) { $0 + $1.snowfall }
        let snowDays = viewModel.forecast.filter { $0.snowfall > 0 }.count
        let bestDay = viewModel.forecast.max(by: { $0.snowfall < $1.snowfall })

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SummaryItem(title: "Total Expected", value: "\(totalSnow)\"", icon: "snowflake")
                Spacer()
                SummaryItem(title: "Snow Days", value: "\(snowDays)", icon: "calendar")
            }

            if let best = bestDay, best.snowfall > 0 {
                Divider()
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Best Day: \(best.dayOfWeek) with \(best.snowfall)\" expected")
                        .font(.subheadline)
                }
            }
        }
    }
}

struct SummaryItem: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}

#Preview {
    NavigationStack {
        ForecastView()
    }
}
