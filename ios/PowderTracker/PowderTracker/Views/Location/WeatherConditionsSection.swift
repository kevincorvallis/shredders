import SwiftUI

struct WeatherConditionsSection: View {
    var viewModel: LocationViewModel
    var onNavigateToForecast: (() -> Void)?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header (Tappable)
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
                Text("Current Conditions")
                    .font(.headline)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .foregroundColor(.secondary)
                    .imageScale(.large)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                handleTap()
            }

            // Powder Score (if available)
            if let score = viewModel.powderScore {
                PowderScoreBanner(score: score)
            }

            // Weather Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                if let temp = viewModel.temperature {
                    WeatherMetricCard(
                        icon: "thermometer",
                        label: "Temperature",
                        value: "\(Int(temp))°F",
                        color: temperatureColor(temp)
                    )
                }
                
                // Feels like temperature from WeatherKit
                if let feelsLike = viewModel.apparentTemperature {
                    WeatherMetricCard(
                        icon: "thermometer.snowflake",
                        label: "Feels Like",
                        value: "\(Int(feelsLike))°F",
                        color: temperatureColor(feelsLike)
                    )
                }

                if let wind = viewModel.windSpeed {
                    WeatherMetricCard(
                        icon: "wind",
                        label: "Wind Speed",
                        value: "\(Int(wind)) mph",
                        color: windColor(wind)
                    )
                }
                
                // Wind gust from WeatherKit
                if let gust = viewModel.windGust {
                    WeatherMetricCard(
                        icon: "wind.snow",
                        label: "Wind Gust",
                        value: "\(Int(gust)) mph",
                        color: windColor(gust)
                    )
                }
                
                // Humidity from WeatherKit
                if let humidity = viewModel.humidity {
                    WeatherMetricCard(
                        icon: "humidity.fill",
                        label: "Humidity",
                        value: "\(Int(humidity * 100))%",
                        color: .blue
                    )
                }
                
                // UV Index from WeatherKit
                if let uvIndex = viewModel.uvIndex {
                    WeatherMetricCard(
                        icon: "sun.max.fill",
                        label: "UV Index",
                        value: "\(uvIndex)",
                        color: uvIndexColor(uvIndex)
                    )
                }
                
                // Visibility from WeatherKit
                if let visibility = viewModel.visibility {
                    WeatherMetricCard(
                        icon: "eye.fill",
                        label: "Visibility",
                        value: String(format: "%.1f mi", visibility),
                        color: .cyan
                    )
                }

                if let description = viewModel.weatherDescription {
                    WeatherDescriptionCard(description: description)
                }
            }
            
            // WeatherKit Attribution
            if viewModel.hasWeatherKitData {
                HStack {
                    Spacer()
                    WeatherAttributionInline()
                }
                .padding(.top, 4)
            }

            // Expanded Content
            if isExpanded {
                VStack(spacing: 12) {
                    // Temperature by Elevation (if available)
                    if let tempData = viewModel.locationData?.conditions.temperatureByElevation,
                       let mountainDetail = viewModel.locationData?.mountain {
                        NavigationLink(destination: TemperatureElevationMapView(
                            mountain: mountainDetail,
                            temperatureData: tempData
                        )) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Temperature by Elevation")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    HStack(spacing: 12) {
                                        Text("Base: \(tempData.base)°F")
                                            .font(.caption)
                                        Text("Mid: \(tempData.mid)°F")
                                            .font(.caption)
                                        Text("Summit: \(tempData.summit)°F")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(.cornerRadiusButton)
                        }
                        .buttonStyle(.plain)
                    }

                    // Navigate to Forecast Button
                    if onNavigateToForecast != nil {
                        Button {
                            onNavigateToForecast?()
                        } label: {
                            HStack {
                                Text("View 7-Day Forecast")
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(.cornerRadiusButton)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Tap Handler

    private func handleTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        withAnimation(.spring(response: 0.3)) {
            if isExpanded {
                // Second tap: Navigate to Forecast tab
                onNavigateToForecast?()
            } else {
                // First tap: Expand inline
                isExpanded = true
            }
        }
    }

    private func temperatureColor(_ temp: Double) -> Color {
        if temp < 20 { return .blue }
        if temp < 32 { return .cyan }
        if temp < 40 { return .green }
        return .orange
    }

    private func windColor(_ speed: Double) -> Color {
        if speed < 10 { return .green }
        if speed < 20 { return .yellow }
        if speed < 30 { return .orange }
        return .red
    }
    
    private func uvIndexColor(_ index: Int) -> Color {
        if index <= 2 { return .green }
        if index <= 5 { return .yellow }
        if index <= 7 { return .orange }
        if index <= 10 { return .red }
        return .purple
    }
}

struct PowderScoreBanner: View {
    let score: Double

    var scoreColor: Color {
        if score >= 8.0 { return .green }
        if score >= 6.0 { return .yellow }
        if score >= 4.0 { return .orange }
        return .red
    }

    var scoreText: String {
        if score >= 8.0 { return "Epic" }
        if score >= 6.0 { return "Good" }
        if score >= 4.0 { return "Fair" }
        return "Poor"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Powder Score")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    Text("/ 10")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                Text(scoreText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(scoreColor)
                Image(systemName: scoreIcon)
                    .font(.title)
                    .foregroundColor(scoreColor)
            }
        }
        .padding()
        .background(scoreColor.opacity(0.1))
        .cornerRadius(.cornerRadiusCard)
    }

    private var scoreIcon: String {
        if score >= 8.0 { return "star.fill" }
        if score >= 6.0 { return "hand.thumbsup.fill" }
        if score >= 4.0 { return "minus.circle.fill" }
        return "hand.thumbsdown.fill"
    }
}

struct WeatherMetricCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
    }
}

struct WeatherDescriptionCard: View {
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: weatherIcon)
                    .foregroundColor(.blue)
                Text("Conditions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(description)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
    }

    private var weatherIcon: String {
        let lower = description.lowercased()
        if lower.contains("clear") || lower.contains("sunny") {
            return "sun.max.fill"
        } else if lower.contains("cloud") {
            return "cloud.fill"
        } else if lower.contains("rain") {
            return "cloud.rain.fill"
        } else if lower.contains("snow") {
            return "cloud.snow.fill"
        } else if lower.contains("wind") {
            return "wind"
        }
        return "cloud.sun.fill"
    }
}
