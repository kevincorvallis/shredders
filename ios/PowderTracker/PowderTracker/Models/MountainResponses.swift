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

extension WeatherAlert {
    /// Check if this alert has expired
    var isExpired: Bool {
        guard let expires = expires else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        // Try with fractional seconds first, then without
        if let expiresDate = formatter.date(from: expires) {
            return expiresDate < Date()
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let expiresDate = formatter.date(from: expires) {
            return expiresDate < Date()
        }
        return false
    }

    /// Check if this is a powder-boosting storm event
    var isPowderBoostEvent: Bool {
        let powderEvents = [
            "Winter Storm Warning",
            "Blizzard Warning",
            "Heavy Snow Warning",
            "Winter Weather Advisory",
            "Snow Squall Warning",
            "Lake Effect Snow Warning",
            "Winter Storm Watch",
            "Blizzard Watch"
        ]
        return powderEvents.contains { event.localizedCaseInsensitiveContains($0) || $0.localizedCaseInsensitiveContains(event) }
    }

    /// Hours remaining until this alert expires
    var hoursRemaining: Int? {
        guard let expires = expires else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var expiresDate: Date?
        expiresDate = formatter.date(from: expires)
        if expiresDate == nil {
            formatter.formatOptions = [.withInternetDateTime]
            expiresDate = formatter.date(from: expires)
        }
        guard let date = expiresDate else { return nil }
        let hours = Int(date.timeIntervalSince(Date()) / 3600)
        return max(0, hours)
    }
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

// MARK: - Storm Info (from powder score endpoint)
struct StormInfo: Codable {
    let isActive: Bool
    let isPowderBoost: Bool
    let eventType: String?
    let hoursRemaining: Int?
    let expectedSnowfall: Int?
    let severity: String?
    let scoreBoost: Double?

    /// Calculated intensity based on expected snowfall and severity
    var intensity: StormIntensity {
        guard isActive else { return .light }
        let snowfall = expectedSnowfall ?? 0
        let severityLevel = severity?.lowercased() ?? ""

        if severityLevel == "extreme" || snowfall >= 24 {
            return .extreme
        } else if severityLevel == "severe" || snowfall >= 12 {
            return .heavy
        } else if snowfall >= 6 {
            return .moderate
        }
        return .light
    }
}

enum StormIntensity: String, Codable {
    case light
    case moderate
    case heavy
    case extreme

    var displayName: String {
        switch self {
        case .light: return "Light Snow"
        case .moderate: return "Moderate Storm"
        case .heavy: return "Heavy Storm"
        case .extreme: return "Extreme Storm"
        }
    }

    var iconName: String {
        switch self {
        case .light: return "cloud.snow"
        case .moderate: return "cloud.snow.fill"
        case .heavy: return "wind.snow"
        case .extreme: return "snowflake"
        }
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
    let stormInfo: StormInfo?
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
        temperatureByElevation: TemperatureByElevation(
            base: 32,
            mid: 28,
            summit: 25,
            referenceElevation: 4500,
            referenceTemp: 28,
            lapseRate: 3.5
        ),
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
        stormInfo: nil,
        dataAvailable: DataAvailability(snotel: true, noaa: true)
    )

    static let mockWithStorm = MountainPowderScore(
        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
        score: 8.5,
        factors: [
            ScoreFactor(name: "Fresh Snow", value: 8, weight: 0.35, contribution: 2.8, description: "8\" in last 24 hours"),
            ScoreFactor(name: "Temperature", value: 25, weight: 0.15, contribution: 1.5, description: "25°F - cold powder"),
        ],
        verdict: "SEND IT! Epic powder conditions!",
        conditions: ScoreConditions(snowfall24h: 12, snowfall48h: 18, temperature: 25, windSpeed: 10, upcomingSnow: 18),
        stormInfo: StormInfo(
            isActive: true,
            isPowderBoost: true,
            eventType: "Winter Storm Warning",
            hoursRemaining: 18,
            expectedSnowfall: 18,
            severity: "Severe",
            scoreBoost: 1.5
        ),
        dataAvailable: DataAvailability(snotel: true, noaa: true)
    )
}

extension MountainBatchedResponse {
    static let mock = MountainBatchedResponse(
        mountain: MountainDetail(
            id: "baker",
            name: "Mt. Baker",
            shortName: "Baker",
            location: MountainLocation(lat: 48.857, lng: -121.669),
            elevation: MountainElevation(base: 3500, summit: 5089),
            region: "washington",
            snotel: MountainDetail.SnotelInfo(stationId: "909", stationName: "Wells Creek"),
            noaa: MountainDetail.NOAAInfo(gridOffice: "SEW", gridX: 150, gridY: 75),
            webcams: [
                MountainDetail.Webcam(id: "1", name: "Base Lodge", url: "https://example.com/cam1.jpg", refreshUrl: nil),
                MountainDetail.Webcam(id: "2", name: "Summit", url: "https://example.com/cam2.jpg", refreshUrl: nil)
            ],
            roadWebcams: nil,
            color: "#3b82f6",
            website: "https://www.mtbaker.us",
            logo: "/logos/baker.svg",
            status: MountainStatus(isOpen: true, percentOpen: 85, liftsOpen: "8/10", runsOpen: "70/82", message: "Great conditions!", lastUpdated: nil),
            passType: .independent
        ),
        conditions: .mock,
        powderScore: .mock,
        forecast: ForecastDay.mockWeek,
        sunData: .mock,
        roads: nil,
        tripAdvice: .mock,
        powderDay: nil,
        alerts: [],
        weatherGovLinks: nil,
        status: MountainStatus(isOpen: true, percentOpen: 85, liftsOpen: "8/10", runsOpen: "70/82", message: "Great conditions!", lastUpdated: nil),
        cachedAt: ISO8601DateFormatter().string(from: Date())
    )
}
