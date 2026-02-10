import Foundation

struct SunData: Codable {
    let sunrise: String // ISO 8601 time (e.g., "2024-12-28T07:45:00-08:00")
    let sunset: String  // ISO 8601 time

    var sunriseDate: Date? {
        DateFormatters.parseISO8601(sunrise)
    }

    var sunsetDate: Date? {
        DateFormatters.parseISO8601(sunset)
    }

    var sunriseTime: String {
        guard let date = sunriseDate else { return "--:--" }
        return DateFormatters.time.string(from: date)
    }

    var sunsetTime: String {
        guard let date = sunsetDate else { return "--:--" }
        return DateFormatters.time.string(from: date)
    }

    var daylightHours: String {
        guard let sunrise = sunriseDate, let sunset = sunsetDate else { return "--h --m" }
        let interval = sunset.timeIntervalSince(sunrise)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Mock Data
extension SunData {
    static let mock = SunData(
        sunrise: "2024-12-28T07:45:00-08:00",
        sunset: "2024-12-28T16:30:00-08:00"
    )
}
