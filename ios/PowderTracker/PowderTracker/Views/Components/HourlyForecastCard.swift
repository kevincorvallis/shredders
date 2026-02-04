import SwiftUI

/// Displays hourly forecast from WeatherKit
struct HourlyForecastCard: View {
    let hourlyForecast: [WeatherKitService.HourlyWeather]
    private let weatherKitService = WeatherKitService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                Text("Hourly Forecast")
                    .font(.headline)
                Spacer()
                WeatherAttributionInline()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Array(hourlyForecast.enumerated()), id: \.offset) { index, hour in
                        HourlyForecastItem(
                            hour: hour,
                            isNow: index == 0,
                            weatherKitService: weatherKitService
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct HourlyForecastItem: View {
    let hour: WeatherKitService.HourlyWeather
    let isNow: Bool
    let weatherKitService: WeatherKitService
    
    var body: some View {
        VStack(spacing: 8) {
            // Time
            Text(isNow ? "Now" : timeString)
                .font(.caption)
                .fontWeight(isNow ? .bold : .medium)
                .foregroundStyle(isNow ? .blue : .secondary)
            
            // Weather icon
            Image(systemName: hour.symbolName)
                .font(.title2)
                .foregroundStyle(.blue)
                .symbolRenderingMode(.multicolor)
                .frame(height: 30)
            
            // Temperature
            Text("\(Int(weatherKitService.celsiusToFahrenheit(hour.temperature)))°")
                .font(.title3)
                .fontWeight(.semibold)
            
            // Precipitation chance
            if hour.precipitationChance > 0.1 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text("\(Int(hour.precipitationChance * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Snowfall amount
            if let snowfall = hour.snowfallAmount, snowfall > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                    Text("\(Int(weatherKitService.millimetersToInches(snowfall)))\"")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Wind speed
            let windMph = Int(weatherKitService.metersPerSecondToMph(hour.windSpeed))
            if windMph > 10 {
                HStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(windMph)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .fill(isNow ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .stroke(isNow ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: hour.date).lowercased()
    }
}

#Preview {
    let sampleHourly: [WeatherKitService.HourlyWeather] = (0..<24).map { offset -> WeatherKitService.HourlyWeather in
        let offsetDouble = Double(offset)
        let timeInterval = TimeInterval(offset * 3600)
        let date = Date().addingTimeInterval(timeInterval)
        let temp = 0 - offsetDouble * 0.5
        let apparentTemp = -2 - offsetDouble * 0.5
        let precipChance = offset % 3 == 0 ? 0.3 : 0.1
        let precipAmount = offset % 3 == 0 ? 2.0 : 0.0
        let snowfall: Double? = offset % 3 == 0 ? 25.4 : nil
        let windSpeed = 10 + Double(offset % 5)
        let windGust = 15 + Double(offset % 5)
        let uvIdx = max(0, 5 - offset / 2)
        
        return WeatherKitService.HourlyWeather(
            date: date,
            temperature: temp,
            apparentTemperature: apparentTemp,
            humidity: 0.7,
            precipitationChance: precipChance,
            precipitationAmount: precipAmount,
            snowfallAmount: snowfall,
            windSpeed: windSpeed,
            windDirection: 270,
            windGust: windGust,
            condition: "Snow",
            symbolName: "cloud.snow.fill",
            uvIndex: uvIdx,
            visibility: 10000
        )
    }
    
    return ScrollView {
        HourlyForecastCard(hourlyForecast: sampleHourly)
            .padding()
    }
}
