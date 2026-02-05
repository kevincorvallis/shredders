import Foundation
import WeatherKit
import CoreLocation

/// Service for fetching weather data using Apple's WeatherKit framework
/// Provides current conditions, hourly forecasts, daily forecasts, and weather alerts
@MainActor
class WeatherKitService: ObservableObject {
    static let shared = WeatherKitService()
    
    private let weatherService = WeatherService.shared
    
    @Published var isAvailable: Bool = true
    @Published var lastError: Error?
    
    private init() {}
    
    // MARK: - Weather Data Models
    
    struct WeatherData {
        let currentWeather: CurrentWeather
        let hourlyForecast: [HourlyWeather]
        let dailyForecast: [DailyWeather]
        let alerts: [WeatherKitAlert]
        let minuteForecast: MinuteForecast?
    }
    
    struct CurrentWeather {
        let temperature: Double // Celsius
        let apparentTemperature: Double
        let humidity: Double // 0-1
        let dewPoint: Double
        let pressure: Double // millibars
        let windSpeed: Double // m/s
        let windDirection: Int // degrees
        let windGust: Double? // m/s
        let uvIndex: Int
        let visibility: Double // meters
        let cloudCover: Double // 0-1
        let condition: String
        let symbolName: String
        let precipitation: Double // mm
        let snowfall: Double? // mm
        let asOfDate: Date
    }
    
    struct HourlyWeather {
        let date: Date
        let temperature: Double
        let apparentTemperature: Double
        let humidity: Double
        let precipitationChance: Double // 0-1
        let precipitationAmount: Double // mm
        let snowfallAmount: Double? // mm
        let windSpeed: Double
        let windDirection: Int
        let windGust: Double?
        let condition: String
        let symbolName: String
        let uvIndex: Int
        let visibility: Double
    }
    
    struct DailyWeather {
        let date: Date
        let highTemperature: Double
        let lowTemperature: Double
        let precipitationChance: Double
        let precipitationAmount: Double
        let snowfallAmount: Double?
        let windSpeed: Double
        let windGust: Double?
        let condition: String
        let symbolName: String
        let uvIndex: Int
        let sunrise: Date?
        let sunset: Date?
        let moonPhase: Double // 0-1
    }
    
    struct MinuteForecast {
        let startDate: Date
        let endDate: Date
        let summary: String
        let minutes: [MinuteWeather]
    }
    
    struct MinuteWeather {
        let date: Date
        let precipitationChance: Double
        let precipitationIntensity: Double // mm/hr
    }
    
    // MARK: - Fetch Methods
    
    /// Fetch comprehensive weather data for a location
    func fetchWeather(for location: CLLocation) async throws -> WeatherData {
        do {
            // Fetch all weather data in parallel
            async let current = weatherService.weather(for: location)
            async let hourly = weatherService.weather(for: location, including: .hourly)
            async let daily = weatherService.weather(for: location, including: .daily)
            async let alerts = weatherService.weather(for: location, including: .alerts)
            
            // Minute forecast only available in some regions
            let minute: Forecast<WeatherKit.MinuteWeather>?
            do {
                minute = try await weatherService.weather(for: location, including: .minute)
            } catch {
                minute = nil
            }
            
            let (currentWeather, hourlyForecast, dailyForecast, weatherAlerts) = try await (current, hourly, daily, alerts ?? [])
            
            return WeatherData(
                currentWeather: mapCurrentWeather(currentWeather.currentWeather),
                hourlyForecast: hourlyForecast.map { mapHourlyWeather($0) },
                dailyForecast: dailyForecast.map { mapDailyWeather($0) },
                alerts: weatherAlerts.compactMap { mapWeatherAlert($0) },
                minuteForecast: minute != nil ? mapMinuteForecast(minute!) : nil
            )
        } catch {
            lastError = error
            isAvailable = false
            throw error
        }
    }
    
    /// Fetch current weather conditions only
    func fetchCurrentWeather(for location: CLLocation) async throws -> CurrentWeather {
        let weather = try await weatherService.weather(for: location)
        return mapCurrentWeather(weather.currentWeather)
    }
    
    /// Fetch hourly forecast (next 240 hours / 10 days)
    func fetchHourlyForecast(for location: CLLocation, hours: Int = 24) async throws -> [HourlyWeather] {
        let forecast = try await weatherService.weather(for: location, including: .hourly)
        return Array(forecast.prefix(hours)).map { mapHourlyWeather($0) }
    }
    
    /// Fetch daily forecast (next 10 days)
    func fetchDailyForecast(for location: CLLocation, days: Int = 10) async throws -> [DailyWeather] {
        let forecast = try await weatherService.weather(for: location, including: .daily)
        return Array(forecast.prefix(days)).map { mapDailyWeather($0) }
    }
    
    /// Fetch weather alerts
    func fetchAlerts(for location: CLLocation) async throws -> [WeatherKitAlert] {
        let alerts = try await weatherService.weather(for: location, including: .alerts)
        return (alerts ?? []).compactMap { mapWeatherAlert($0) }
    }
    
    /// Fetch minute-by-minute precipitation forecast (next hour)
    func fetchMinuteForecast(for location: CLLocation) async throws -> MinuteForecast? {
        do {
            let forecast = try await weatherService.weather(for: location, including: .minute)
            guard let forecastData = forecast else { return nil }
            return mapMinuteForecast(forecastData)
        } catch {
            // Minute forecast not available in all regions
            return nil
        }
    }
    
    // MARK: - Attribution
    
    /// Returns the required Apple Weather attribution mark and link
    /// IMPORTANT: Must display this when showing WeatherKit data per Apple's terms
    var attribution: (mark: URL, link: URL) {
        (
            mark: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!,
            link: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!
        )
    }
    
    // MARK: - Mapping Functions
    
    private func mapCurrentWeather(_ weather: WeatherKit.CurrentWeather) -> CurrentWeather {
        CurrentWeather(
            temperature: weather.temperature.value,
            apparentTemperature: weather.apparentTemperature.value,
            humidity: weather.humidity,
            dewPoint: weather.dewPoint.value,
            pressure: weather.pressure.value,
            windSpeed: weather.wind.speed.value,
            windDirection: Int(weather.wind.direction.value),
            windGust: weather.wind.gust?.value,
            uvIndex: weather.uvIndex.value,
            visibility: weather.visibility.value,
            cloudCover: weather.cloudCover,
            condition: weather.condition.description,
            symbolName: weather.symbolName,
            precipitation: weather.precipitationIntensity.value,
            snowfall: isSnow(temperature: weather.temperature.value) ? weather.precipitationIntensity.value : 0,
            asOfDate: weather.date
        )
    }
    
    private func mapHourlyWeather(_ weather: WeatherKit.HourWeather) -> HourlyWeather {
        var snowfall: Double? = nil
        if #available(iOS 18.0, *) {
            snowfall = weather.snowfallAmount.value
        }
        
        return HourlyWeather(
            date: weather.date,
            temperature: weather.temperature.value,
            apparentTemperature: weather.apparentTemperature.value,
            humidity: weather.humidity,
            precipitationChance: weather.precipitationChance,
            precipitationAmount: weather.precipitationAmount.value,
            snowfallAmount: snowfall,
            windSpeed: weather.wind.speed.value,
            windDirection: Int(weather.wind.direction.value),
            windGust: weather.wind.gust?.value,
            condition: weather.condition.description,
            symbolName: weather.symbolName,
            uvIndex: weather.uvIndex.value,
            visibility: weather.visibility.value
        )
    }
    
    private func mapDailyWeather(_ weather: WeatherKit.DayWeather) -> DailyWeather {
        var snowfall: Double? = nil
        var rainfall: Double = 0
        if #available(iOS 18.0, *) {
            snowfall = weather.snowfallAmount.value
            rainfall = weather.precipitationAmountByType.rainfall.value
        } else {
            rainfall = weather.rainfallAmount.value
        }
        
        return DailyWeather(
            date: weather.date,
            highTemperature: weather.highTemperature.value,
            lowTemperature: weather.lowTemperature.value,
            precipitationChance: weather.precipitationChance,
            precipitationAmount: rainfall,
            snowfallAmount: snowfall,
            windSpeed: weather.wind.speed.value,
            windGust: weather.wind.gust?.value,
            condition: weather.condition.description,
            symbolName: weather.symbolName,
            uvIndex: weather.uvIndex.value,
            sunrise: weather.sun.sunrise,
            sunset: weather.sun.sunset,
            moonPhase: 0.5 // WeatherKit doesn't expose raw moon phase value
        )
    }
    
    private func mapWeatherAlert(_ alert: WeatherKit.WeatherAlert) -> WeatherKitAlert? {
        WeatherKitAlert(
            id: UUID().uuidString,
            source: alert.source,
            severity: mapSeverity(alert.severity),
            summary: alert.summary,
            detailsURL: alert.detailsURL,
            region: alert.region ?? "Unknown Region"
        )
    }
    
    private func mapMinuteForecast(_ forecast: Forecast<WeatherKit.MinuteWeather>) -> MinuteForecast {
        let minutes = Array(forecast)
        return MinuteForecast(
            startDate: minutes.first?.date ?? Date(),
            endDate: minutes.last?.date ?? Date(),
            summary: "Minute-by-minute precipitation forecast",
            minutes: minutes.map { minute in
                MinuteWeather(
                    date: minute.date,
                    precipitationChance: minute.precipitationChance,
                    precipitationIntensity: minute.precipitationIntensity.value
                )
            }
        )
    }
    
    private func mapSeverity(_ severity: WeatherKit.WeatherSeverity) -> String {
        switch severity {
        case .minor: return "minor"
        case .moderate: return "moderate"
        case .severe: return "severe"
        case .extreme: return "extreme"
        case .unknown: return "unknown"
        @unknown default: return "unknown"
        }
    }
    
    // MARK: - Utility Methods
    
    /// Convert Celsius to Fahrenheit
    func celsiusToFahrenheit(_ celsius: Double) -> Double {
        return (celsius * 9/5) + 32
    }
    
    /// Convert meters per second to miles per hour
    func metersPerSecondToMph(_ mps: Double) -> Double {
        return mps * 2.23694
    }
    
    /// Convert millimeters to inches
    func millimetersToInches(_ mm: Double) -> Double {
        return mm / 25.4
    }
    
    /// Check if precipitation is likely snow based on temperature
    func isSnow(temperature: Double) -> Bool {
        return temperature <= 0 // Below 0°C / 32°F
    }
    
    /// Get human-readable wind direction from degrees
    func windDirectionFromDegrees(_ degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((Double(degrees) + 11.25) / 22.5) % 16
        return directions[index]
    }
}

// MARK: - Weather Alert Model

struct WeatherKitAlert: Identifiable {
    let id: String
    let source: String
    let severity: String
    let summary: String
    let detailsURL: URL
    let region: String
}
