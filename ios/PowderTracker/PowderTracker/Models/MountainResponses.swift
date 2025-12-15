import Foundation

// MARK: - Mountain Info (embedded in responses)
struct MountainInfo: Codable {
    let id: String
    let name: String
    let shortName: String
}

// MARK: - Mountain Conditions Response
struct MountainConditions: Codable {
    let mountain: MountainInfo
    let snowDepth: Int?
    let snowWaterEquivalent: Double?
    let snowfall24h: Int
    let snowfall48h: Int
    let snowfall7d: Int
    let temperature: Int?
    let conditions: String
    let wind: WindInfo?
    let lastUpdated: String
    let dataSources: DataSources

    struct WindInfo: Codable {
        let speed: Int
        let direction: String
    }

    struct DataSources: Codable {
        let snotel: SnotelSource?
        let noaa: NOAASource

        struct SnotelSource: Codable {
            let available: Bool
            let stationName: String
        }

        struct NOAASource: Codable {
            let available: Bool
            let gridOffice: String
        }
    }
}

// MARK: - Mountain Forecast Response
struct MountainForecastResponse: Codable {
    let mountain: MountainInfo
    let forecast: [ForecastDay]
    let source: ForecastSource

    struct ForecastSource: Codable {
        let provider: String
        let gridOffice: String
    }
}

// MARK: - Mountain Powder Score Response
struct MountainPowderScore: Codable, Identifiable {
    var id: String { mountain.id }

    let mountain: MountainInfo
    let score: Double
    let factors: [ScoreFactor]
    let verdict: String
    let conditions: ScoreConditions
    let dataAvailable: DataAvailability

    struct ScoreFactor: Codable, Identifiable {
        var id: String { name }

        let name: String
        let value: Double
        let weight: Double
        let contribution: Double
        let description: String
    }

    struct ScoreConditions: Codable {
        let snowfall24h: Int
        let snowfall48h: Int
        let temperature: Int
        let windSpeed: Int
        let upcomingSnow: Int
    }

    struct DataAvailability: Codable {
        let snotel: Bool
        let noaa: Bool
    }
}

// MARK: - Mountain History Response
struct MountainHistoryResponse: Codable {
    let mountain: MountainInfo
    let history: [HistoryDataPoint]
    let days: Int
    let source: HistorySource

    struct HistorySource: Codable {
        let provider: String
        let stationName: String
        let stationId: String
    }
}

// MARK: - Mock Data
extension MountainConditions {
    static let mock = MountainConditions(
        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
        snowDepth: 142,
        snowWaterEquivalent: 58.4,
        snowfall24h: 8,
        snowfall48h: 14,
        snowfall7d: 32,
        temperature: 28,
        conditions: "Snow",
        wind: WindInfo(speed: 15, direction: "SW"),
        lastUpdated: ISO8601DateFormatter().string(from: Date()),
        dataSources: DataSources(
            snotel: DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
            noaa: DataSources.NOAASource(available: true, gridOffice: "SEW")
        )
    )
}

extension MountainPowderScore {
    static let mock = MountainPowderScore(
        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
        score: 7.2,
        factors: [
            ScoreFactor(name: "Fresh Snow", value: 8, weight: 0.35, contribution: 2.8, description: "8\" in last 24 hours"),
            ScoreFactor(name: "Temperature", value: 28, weight: 0.15, contribution: 1.2, description: "28°F - good powder temps"),
        ],
        verdict: "Great day for skiing - fresh snow awaits!",
        conditions: ScoreConditions(snowfall24h: 8, snowfall48h: 14, temperature: 28, windSpeed: 15, upcomingSnow: 6),
        dataAvailable: DataAvailability(snotel: true, noaa: true)
    )
}
