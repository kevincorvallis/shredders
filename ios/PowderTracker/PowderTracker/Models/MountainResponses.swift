import Foundation

// MARK: - Mountain Info (embedded in responses)
struct MountainInfo: Codable {
    let id: String
    let name: String
    let shortName: String
}

// MARK: - Weather Alert
struct WeatherAlert: Codable, Identifiable {
    let id: String
    let event: String
    let headline: String
    let severity: String
    let urgency: String
    let certainty: String
    let onset: String?
    let expires: String?
    let description: String
    let instruction: String?
    let areaDesc: String
}

struct WeatherAlertsResponse: Codable {
    let mountain: MountainInfo
    let alerts: [WeatherAlert]
    let count: Int
    let source: String
}

// MARK: - Weather.gov Links
struct WeatherGovLinks: Codable {
    let forecast: String
    let hourly: String
    let detailed: String?
    let alerts: String
    let discussion: String?
}

struct WeatherGovLinksResponse: Codable {
    let mountain: MountainInfo
    let weatherGov: WeatherGovLinks
    let location: Location

    struct Location: Codable {
        let lat: Double
        let lng: Double
    }
}

// MARK: - Hourly Forecast
struct HourlyForecastPeriod: Codable, Identifiable {
    var id: String { time }

    let time: String
    let temperature: Int
    let temperatureUnit: String
    let dewpoint: Double?
    let windSpeed: Int
    let windDirection: String
    let windDirectionDegrees: Int?
    let icon: String
    let shortForecast: String
    let precipProbability: Int?
    let relativeHumidity: Int?
}

struct HourlyForecastResponse: Codable {
    let mountain: MountainInfo
    let hourly: [HourlyForecastPeriod]
    let source: ForecastSource

    struct ForecastSource: Codable {
        let provider: String
        let gridOffice: String
    }
}

// MARK: - Lift Status
struct LiftStatus: Codable {
    let isOpen: Bool
    let liftsOpen: Int
    let liftsTotal: Int
    let runsOpen: Int
    let runsTotal: Int
    let message: String?
    let lastUpdated: String

    var percentOpen: Int {
        guard liftsTotal > 0 else { return 0 }
        return Int(round(Double(liftsOpen) / Double(liftsTotal) * 100))
    }

    var statusColor: String {
        isOpen ? "green" : "red"
    }

    var percentColor: String {
        percentOpen >= 80 ? "green" : percentOpen >= 50 ? "yellow" : "orange"
    }
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
    let temperatureByElevation: TemperatureByElevation?
    let conditions: String
    let wind: WindInfo?
    let lastUpdated: String
    let liftStatus: LiftStatus?
    let dataSources: DataSources

    struct TemperatureByElevation: Codable {
        let base: Int
        let mid: Int
        let summit: Int
        let referenceElevation: Int
        let referenceTemp: Int
        let lapseRate: Double
    }

    struct WindInfo: Codable {
        let speed: Int
        let direction: String
    }

    struct DataSources: Codable {
        let snotel: SnotelSource?
        let noaa: NOAASource
        let liftStatus: LiftStatusSource?

        struct SnotelSource: Codable {
            let available: Bool
            let stationName: String
        }

        struct NOAASource: Codable {
            let available: Bool
            let gridOffice: String
        }

        struct LiftStatusSource: Codable {
            let available: Bool
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
    let verdict: String?
    let conditions: ScoreConditions?
    let dataAvailable: DataAvailability?

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

// MARK: - Batched Mountain Data Response
struct MountainBatchedResponse: Codable {
    let mountain: MountainDetail
    let conditions: MountainConditions
    let powderScore: MountainPowderScore
    let forecast: [ForecastDay]
    let sunData: SunData?
    let roads: RoadsResponse?
    let tripAdvice: TripAdviceResponse?
    let powderDay: PowderDayPlanResponse?
    let alerts: [WeatherAlert]
    let weatherGovLinks: WeatherGovLinks?
    let status: MountainStatus?
    let cachedAt: String
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
        liftStatus: LiftStatus(
            isOpen: true,
            liftsOpen: 9,
            liftsTotal: 10,
            runsOpen: 45,
            runsTotal: 52,
            message: nil,
            lastUpdated: ISO8601DateFormatter().string(from: Date())
        ),
        dataSources: DataSources(
            snotel: DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
            noaa: DataSources.NOAASource(available: true, gridOffice: "SEW"),
            liftStatus: DataSources.LiftStatusSource(available: true)
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
