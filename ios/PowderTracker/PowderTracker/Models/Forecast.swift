import Foundation

struct ForecastResponse: Codable {
    let generated: String
    let location: ForecastLocation
    let forecast: [ForecastDay]
}

struct ForecastLocation: Codable {
    let name: String
    let lat: Double
    let lng: Double
}

struct ForecastDay: Codable, Identifiable {
    var id: String { date }

    let date: String
    let dayOfWeek: String
    let high: Int
    let low: Int
    let snowfall: Int
    let precipProbability: Int
    let precipType: String
    let wind: ForecastWind
    let conditions: String
    let icon: String

    struct ForecastWind: Codable {
        let speed: Int
        let gust: Int
    }

    var iconEmoji: String {
        switch icon {
        case "snow": return "❄️"
        case "rain": return "🌧️"
        case "cloud": return "☁️"
        case "sun": return "☀️"
        case "mixed": return "🌨️"
        case "fog": return "🌫️"
        default: return "🌤️"
        }
    }

    var formattedDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: date)
    }
}

// MARK: - Mock Data
extension ForecastDay {
    static let mockWeek: [ForecastDay] = [
        ForecastDay(date: "2024-12-14", dayOfWeek: "Sat", high: 30, low: 22, snowfall: 6, precipProbability: 90, precipType: "snow", wind: .init(speed: 12, gust: 25), conditions: "Heavy snow", icon: "snow"),
        ForecastDay(date: "2024-12-15", dayOfWeek: "Sun", high: 28, low: 20, snowfall: 10, precipProbability: 95, precipType: "snow", wind: .init(speed: 18, gust: 35), conditions: "Heavy snow, windy", icon: "snow"),
        ForecastDay(date: "2024-12-16", dayOfWeek: "Mon", high: 32, low: 24, snowfall: 4, precipProbability: 70, precipType: "snow", wind: .init(speed: 8, gust: 15), conditions: "Light snow", icon: "snow"),
        ForecastDay(date: "2024-12-17", dayOfWeek: "Tue", high: 35, low: 28, snowfall: 0, precipProbability: 20, precipType: "none", wind: .init(speed: 5, gust: 10), conditions: "Partly cloudy", icon: "cloud"),
        ForecastDay(date: "2024-12-18", dayOfWeek: "Wed", high: 34, low: 26, snowfall: 2, precipProbability: 45, precipType: "snow", wind: .init(speed: 10, gust: 18), conditions: "Scattered flurries", icon: "cloud"),
        ForecastDay(date: "2024-12-19", dayOfWeek: "Thu", high: 30, low: 22, snowfall: 8, precipProbability: 85, precipType: "snow", wind: .init(speed: 14, gust: 28), conditions: "Snow showers", icon: "snow"),
        ForecastDay(date: "2024-12-20", dayOfWeek: "Fri", high: 28, low: 20, snowfall: 12, precipProbability: 95, precipType: "snow", wind: .init(speed: 20, gust: 40), conditions: "Heavy snow", icon: "snow"),
    ]
}
