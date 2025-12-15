import Foundation

// MARK: - Roads/Pass Conditions

struct RoadsResponse: Codable {
    let mountain: MountainInfo
    let supported: Bool
    let configured: Bool
    let provider: String?
    let passes: [PassCondition]
    let message: String?
}

struct PassCondition: Codable, Identifiable {
    let id: Int
    let name: String
    let roadCondition: String
    let weatherCondition: String
    let temperatureInFahrenheit: Int?
    let travelAdvisory: Bool
    let restrictions: [PassRestriction]
}

struct PassRestriction: Codable {
    let direction: String
    let text: String
}

// MARK: - Trip Advice

struct TripAdviceResponse: Codable {
    let generated: String
    let crowd: RiskLevel
    let trafficRisk: RiskLevel
    let roadRisk: RiskLevel
    let headline: String
    let notes: [String]
    let suggestedDepartures: [DepartureSuggestion]
}

struct DepartureSuggestion: Codable, Identifiable {
    var id: String { from }
    let from: String
    let suggestion: String
}

enum RiskLevel: String, Codable {
    case low
    case medium
    case high

    var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "amber"
        case .high: return "red"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Powder Day Plan

struct PowderDayPlanResponse: Codable {
    let generated: String
    let mountainId: String
    let mountainName: String
    let days: [PowderDay]
}

struct PowderDay: Codable, Identifiable {
    var id: String { date }
    let date: String
    let dayOfWeek: String
    let predictedPowderScore: Double
    let confidence: Double
    let verdict: PowderVerdict
    let bestWindow: String
    let crowdRisk: RiskLevel
    let travelNotes: [String]
    let forecastSnapshot: ForecastSnapshot
}

enum PowderVerdict: String, Codable {
    case send
    case maybe
    case wait

    var displayName: String {
        rawValue.uppercased()
    }

    var emoji: String {
        switch self {
        case .send: return "🚀"
        case .maybe: return "🤔"
        case .wait: return "⏳"
        }
    }
}

struct ForecastSnapshot: Codable {
    let snowfall: Int
    let high: Int
    let low: Int
    let windSpeed: Int
    let precipProbability: Int
    let precipType: String
    let conditions: String
}

// MARK: - Mock Data

extension RoadsResponse {
    static let mock = RoadsResponse(
        mountain: MountainInfo(id: "stevens", name: "Stevens Pass", shortName: "Stevens"),
        supported: true,
        configured: true,
        provider: "WSDOT",
        passes: [
            PassCondition(
                id: 1,
                name: "Stevens Pass",
                roadCondition: "Wet",
                weatherCondition: "Light Snow",
                temperatureInFahrenheit: 28,
                travelAdvisory: false,
                restrictions: []
            )
        ],
        message: nil
    )
}

extension TripAdviceResponse {
    static let mock = TripAdviceResponse(
        generated: ISO8601DateFormatter().string(from: Date()),
        crowd: .medium,
        trafficRisk: .medium,
        roadRisk: .low,
        headline: "Moderate crowds expected. Leave early to beat traffic.",
        notes: [
            "Weekend powder day - expect higher demand",
            "Roads are clear but temperatures dropping tonight",
            "Consider carpooling to reduce I-90 congestion"
        ],
        suggestedDepartures: [
            DepartureSuggestion(from: "Seattle", suggestion: "Depart by 6:00 AM"),
            DepartureSuggestion(from: "Bellevue", suggestion: "Depart by 6:15 AM")
        ]
    )
}

extension PowderDayPlanResponse {
    static let mock = PowderDayPlanResponse(
        generated: ISO8601DateFormatter().string(from: Date()),
        mountainId: "baker",
        mountainName: "Mt. Baker",
        days: [
            PowderDay(
                date: "2025-12-15",
                dayOfWeek: "Sun",
                predictedPowderScore: 8.5,
                confidence: 0.85,
                verdict: .send,
                bestWindow: "First chair to noon",
                crowdRisk: .medium,
                travelNotes: ["Roads clear", "Storm arriving mid-afternoon"],
                forecastSnapshot: ForecastSnapshot(
                    snowfall: 12,
                    high: 28,
                    low: 22,
                    windSpeed: 15,
                    precipProbability: 90,
                    precipType: "snow",
                    conditions: "Heavy snow"
                )
            ),
            PowderDay(
                date: "2025-12-16",
                dayOfWeek: "Mon",
                predictedPowderScore: 7.2,
                confidence: 0.72,
                verdict: .send,
                bestWindow: "All day",
                crowdRisk: .low,
                travelNotes: ["Weekday - lighter crowds"],
                forecastSnapshot: ForecastSnapshot(
                    snowfall: 6,
                    high: 30,
                    low: 24,
                    windSpeed: 10,
                    precipProbability: 70,
                    precipType: "snow",
                    conditions: "Light snow"
                )
            ),
            PowderDay(
                date: "2025-12-17",
                dayOfWeek: "Tue",
                predictedPowderScore: 5.5,
                confidence: 0.65,
                verdict: .maybe,
                bestWindow: "Morning groomers",
                crowdRisk: .low,
                travelNotes: ["Clearing skies", "Good groomer day"],
                forecastSnapshot: ForecastSnapshot(
                    snowfall: 0,
                    high: 34,
                    low: 26,
                    windSpeed: 5,
                    precipProbability: 20,
                    precipType: "none",
                    conditions: "Partly cloudy"
                )
            )
        ]
    )
}
