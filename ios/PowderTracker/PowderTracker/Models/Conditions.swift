import Foundation

struct Mountain: Codable {
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
    let mountain: Mountain
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
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: timestamp)
    }

    var lastUpdatedString: String {
        guard let date = formattedTimestamp else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Mock Data
extension Conditions {
    static let mock = Conditions(
        timestamp: ISO8601DateFormatter().string(from: Date()),
        mountain: Mountain(id: "mt-baker", name: "Mt. Baker", elevation: .init(base: 3500, summit: 5089)),
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
