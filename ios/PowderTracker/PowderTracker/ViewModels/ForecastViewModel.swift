import Foundation
import SwiftUI
import CoreLocation

@MainActor
@Observable
class ForecastViewModel {
    var forecast: [ForecastDay] = []
    var isLoading = false
    var error: String?
    
    // WeatherKit integration
    var weatherKitDailyForecast: [WeatherKitService.DailyWeather] = []
    var weatherKitHourlyForecast: [WeatherKitService.HourlyWeather] = []
    var weatherKitAlerts: [WeatherKitAlert] = []

    private let apiClient = APIClient.shared
    private let weatherKitService = WeatherKitService.shared

    func loadForecast() async {
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.fetchForecast()
            self.forecast = response.forecast
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
    
    func loadWeatherKitForecast(for location: CLLocation) async {
        isLoading = true
        error = nil
        
        do {
            async let daily = weatherKitService.fetchDailyForecast(for: location, days: 10)
            async let hourly = weatherKitService.fetchHourlyForecast(for: location, hours: 24)
            async let alerts = weatherKitService.fetchAlerts(for: location)
            
            let (dailyData, hourlyData, alertsData) = try await (daily, hourly, alerts)
            
            self.weatherKitDailyForecast = dailyData
            self.weatherKitHourlyForecast = hourlyData
            self.weatherKitAlerts = alertsData
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("Failed to fetch WeatherKit forecast: \(error)")
            #endif
        }
        
        isLoading = false
    }
    
    // Convert WeatherKit daily forecast to app's ForecastDay model
    func convertedDailyForecast() -> [ForecastDay] {
        return weatherKitDailyForecast.map { day in
            let fahrenheitHigh = weatherKitService.celsiusToFahrenheit(day.highTemperature)
            let fahrenheitLow = weatherKitService.celsiusToFahrenheit(day.lowTemperature)
            let snowfallInches = weatherKitService.millimetersToInches(day.snowfallAmount ?? 0)
            let windMph = weatherKitService.metersPerSecondToMph(day.windSpeed)

            return ForecastDay(
                date: DateFormatters.dateParser.string(from: day.date),
                dayOfWeek: DateFormatters.dayOfWeek.string(from: day.date),
                high: Int(fahrenheitHigh),
                low: Int(fahrenheitLow),
                snowfall: Int(snowfallInches),
                precipProbability: Int(day.precipitationChance * 100),
                precipType: day.snowfallAmount != nil && day.snowfallAmount! > 0 ? "snow" : "rain",
                wind: ForecastDay.ForecastWind(
                    speed: Int(windMph),
                    gust: day.windGust.map { Int(weatherKitService.metersPerSecondToMph($0)) } ?? Int(windMph)
                ),
                conditions: day.condition,
                icon: day.symbolName
            )
        }
    }
}
