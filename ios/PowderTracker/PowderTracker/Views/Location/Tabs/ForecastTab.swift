import SwiftUI

struct ForecastTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain
    @State private var forecastData: MountainForecastResponse?
    @State private var hourlyData: HourlyForecastResponse?
    @State private var powderDayData: PowderDayPlanResponse?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            // Powder Day Planner (3-day outlook)
            if let powderDay = powderDayData {
                PowderDayPlannerCard(data: powderDay)
            }

            // 7-Day Forecast
            if let forecast = forecastData {
                SevenDayForecastCard(forecast: forecast)
            }

            // Hourly Forecast
            if let hourly = hourlyData {
                APIHourlyForecastCard(hourly: hourly)
            }

            if isLoading {
                ProgressView("Loading forecast...")
            }
        }
        .task {
            await loadForecastData()
        }
    }

    private func loadForecastData() async {
        isLoading = true

        async let forecast = APIClient.shared.fetchForecast(for: mountain.id)
        async let hourly = APIClient.shared.fetchHourlyForecast(for: mountain.id)
        async let powderDay = APIClient.shared.fetchPowderDayPlan(for: mountain.id)

        do {
            forecastData = try await forecast
            hourlyData = try await hourly
            powderDayData = try await powderDay
        } catch {
            #if DEBUG
            print("Failed to load forecast data: \(error)")
            #endif
        }

        isLoading = false
    }
}

// MARK: - Powder Day Planner Card

struct PowderDayPlannerCard: View {
    let data: PowderDayPlanResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Best Days to Ride", systemImage: "star.fill")
                .font(.headline)
                .foregroundColor(.yellow)

            ForEach(data.days.prefix(3)) { day in
                ForecastPowderDayRow(day: day)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ForecastPowderDayRow: View {
    let day: PowderDay

    private var scoreColor: Color {
        if day.predictedPowderScore >= 8 { return .green }
        if day.predictedPowderScore >= 6 { return .blue }
        if day.predictedPowderScore >= 4 { return .orange }
        return .red
    }

    var body: some View {
        HStack(spacing: 12) {
            // Score badge
            ZStack {
                Circle()
                    .fill(scoreColor.opacity(0.2))
                    .frame(width: 44, height: 44)

                Text("\(Int(day.predictedPowderScore))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(scoreColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(day.dayOfWeek)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text("\(day.forecastSnapshot.snowfall)\" new snow")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Label(day.crowdRisk.rawValue.capitalized, systemImage: "person.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(day.verdict.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 7-Day Forecast Card

struct SevenDayForecastCard: View {
    let forecast: MountainForecastResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Forecast")
                .font(.headline)

            ForEach(forecast.forecast) { day in
                DayForecastRow(day: day)
                if day.id != forecast.forecast.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct DayForecastRow: View {
    let day: ForecastDay

    var body: some View {
        HStack(spacing: 12) {
            // Day
            Text(day.dayOfWeek)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)

            // Weather icon
            Image(systemName: weatherIcon(for: day.conditions))
                .font(.title3)
                .foregroundColor(weatherColor(for: day.conditions))
                .frame(width: 30)

            // Temperature
            HStack(spacing: 4) {
                Text("\(day.high)°")
                    .fontWeight(.semibold)
                Text("/")
                    .foregroundStyle(.secondary)
                Text("\(day.low)°")
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
            .frame(width: 70, alignment: .leading)

            Spacer()

            // Snow
            if day.snowfall > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "snow")
                        .font(.caption)
                    Text("\(Int(day.snowfall))\"")
                        .fontWeight(.semibold)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
    }

    private func weatherIcon(for conditions: String) -> String {
        let lowercased = conditions.lowercased()
        if lowercased.contains("snow") { return "cloud.snow.fill" }
        if lowercased.contains("rain") { return "cloud.rain.fill" }
        if lowercased.contains("cloud") { return "cloud.fill" }
        if lowercased.contains("clear") || lowercased.contains("sun") { return "sun.max.fill" }
        return "cloud.fill"
    }

    private func weatherColor(for conditions: String) -> Color {
        let lowercased = conditions.lowercased()
        if lowercased.contains("snow") { return .blue }
        if lowercased.contains("rain") { return .gray }
        if lowercased.contains("cloud") { return .gray }
        return .orange
    }
}

// MARK: - Hourly Forecast Card

struct APIHourlyForecastCard: View {
    let hourly: HourlyForecastResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next 24 Hours")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(hourly.hourly.prefix(24)) { hour in
                        HourlyForecastCell(hour: hour)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct HourlyForecastCell: View {
    let hour: HourlyForecastPeriod

    var body: some View {
        VStack(spacing: 8) {
            Text(hour.time)
                .font(.caption)
                .foregroundStyle(.secondary)

            Image(systemName: hour.shortForecast.lowercased().contains("snow") ? "cloud.snow.fill" : "cloud.fill")
                .font(.title3)
                .foregroundColor(hour.shortForecast.lowercased().contains("snow") ? .blue : .gray)

            Text("\(hour.temperature)°")
                .font(.subheadline)
                .fontWeight(.semibold)

            if let precip = hour.precipProbability, precip > 30 {
                Text("\(precip)%")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 60)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

// Note: All model types (ForecastResponse, ForecastDay, HourlyForecastResponse, PowderDayResponse, PowderDay)
// are defined in Models/Forecast.swift, Models/MountainResponses.swift, and Models/TripPlanning.swift

#Preview {
    ScrollView {
        ForecastTab(viewModel: LocationViewModel(mountain: .mock), mountain: .mock)
            .padding()
    }
}
