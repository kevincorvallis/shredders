import SwiftUI

/// Consolidated tab combining Forecast and History
struct ConditionsTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain
    @State private var selectedSection: Section = .forecast

    enum Section: String, CaseIterable {
        case forecast = "Forecast"
        case history = "History"
    }

    var body: some View {
        VStack(spacing: .spacingL) {
            // Section picker
            sectionPicker

            // Content
            switch selectedSection {
            case .forecast:
                forecastContent
            case .history:
                historyContent
            }
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        Picker("Section", selection: $selectedSection) {
            ForEach(Section.allCases, id: \.self) { section in
                Text(section.rawValue)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Forecast Content

    private var forecastContent: some View {
        VStack(spacing: .spacingL) {
            if let forecast = viewModel.locationData?.forecast, !forecast.isEmpty {
                ForecastSection(forecast: forecast)
            } else {
                Text("No forecast data available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .frame(alignment: .center)
            }
        }
    }

    // MARK: - History Content

    private var historyContent: some View {
        VStack(spacing: .spacingL) {
            // Historical data summary
            if let conditions = viewModel.locationData?.conditions {
                VStack(alignment: .leading, spacing: .spacingM) {
                    Text("Recent Snow Totals")
                        .sectionHeader()

                    HStack(spacing: .spacingL) {
                        MetricView(
                            icon: "snowflake",
                            label: "24h",
                            value: "\(Int(conditions.snowfall24h))\"",
                            color: .blue
                        )

                        MetricView(
                            icon: "snowflake",
                            label: "48h",
                            value: "\(conditions.snowfall48h)\"",
                            color: .blue.opacity(0.8)
                        )

                        MetricView(
                            icon: "snowflake",
                            label: "7 days",
                            value: "\(conditions.snowfall7d)\"",
                            color: .blue.opacity(0.6)
                        )
                    }
                    .padding(.spacingM)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusCard)
                }
            }
        }
    }
}

// MARK: - Forecast Section (reused from ForecastTab)

struct ForecastSection: View {
    let forecast: [ForecastDay]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("7-Day Forecast")
                .sectionHeader()

            ForEach(forecast.prefix(7)) { period in
                ForecastRow(period: period)
            }
        }
    }
}

struct ForecastRow: View {
    let period: ForecastDay

    var body: some View {
        HStack(spacing: .spacingM) {
            // Date
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(formatDate(period.date))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(formatWeekday(period.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)

            // Weather icon
            Image(systemName: weatherIcon(for: period.conditions))
                .font(.title3)
                .foregroundColor(weatherColor(for: period.conditions))
                .frame(width: 40)

            Spacer()

            // Snow
            if period.snowfall > 0 {
                HStack(spacing: .spacingXS) {
                    Image(systemName: "snowflake")
                        .font(.caption)
                    Text("\(period.snowfall)\"")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .frame(width: 50)
            }

            // Temperature range
            HStack(spacing: .spacingXS) {
                Text("\(period.low)°")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("/")
                    .foregroundStyle(.secondary)
                Text("\(period.high)°")
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        return dateFormatter.string(from: date)
    }

    private func formatWeekday(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: date)
    }

    private func weatherIcon(for weather: String) -> String {
        let lower = weather.lowercased()
        if lower.contains("snow") { return "cloud.snow.fill" }
        if lower.contains("rain") { return "cloud.rain.fill" }
        if lower.contains("cloud") { return "cloud.fill" }
        if lower.contains("clear") || lower.contains("sunny") { return "sun.max.fill" }
        return "cloud.sun.fill"
    }

    private func weatherColor(for weather: String) -> Color {
        let lower = weather.lowercased()
        if lower.contains("snow") { return .blue }
        if lower.contains("rain") { return .gray }
        if lower.contains("clear") || lower.contains("sunny") { return .orange }
        return .cyan
    }
}

#Preview {
    ScrollView {
        ConditionsTab(viewModel: {
            let vm = LocationViewModel(mountain: .mock)
            return vm
        }(), mountain: .mock)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
