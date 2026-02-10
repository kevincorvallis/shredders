import Foundation

struct MountainBasic: Codable {
    let id: String
    let name: String
    let elevation: Elevation

    struct Elevation: Codable {
        let base: Int
        let summit: Int
    }
}

struct Temperature: Codable {
    let base: Int
    let summit: Int
}

struct Wind: Codable {
    let speed: Int
    let direction: String
    let gust: Int
}

struct Conditions: Codable, Identifiable {
    var id: String { timestamp }

    let timestamp: String
    let mountain: MountainBasic
    let temperature: Temperature
    let snowDepth: Int
    let snowfall24h: Int
    let snowfall48h: Int
    let snowfall7d: Int
    let snowWaterEquivalent: Double
    let freezingLevel: Int
    let wind: Wind
    let visibility: String

    var formattedTimestamp: Date? {
        DateFormatters.parseISO8601(timestamp)
    }

    var lastUpdatedString: String {
        guard let date = formattedTimestamp else { return "Unknown" }
        return DateFormatters.formatRelative(date)
    }
}

// MARK: - Mock Data
extension Conditions {
    static let mock = Conditions(
        timestamp: DateFormatters.iso8601.string(from: Date()),
        mountain: MountainBasic(id: "baker", name: "Mt. Baker", elevation: .init(base: 3500, summit: 5089)),
        temperature: Temperature(base: 28, summit: 18),
        snowDepth: 142,
        snowfall24h: 8,
        snowfall48h: 14,
        snowfall7d: 32,
        snowWaterEquivalent: 58.4,
        freezingLevel: 3200,
        wind: Wind(speed: 15, direction: "SW", gust: 28),
        visibility: "snowing"
    )
}
