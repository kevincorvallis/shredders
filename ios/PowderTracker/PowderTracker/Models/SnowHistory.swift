import Foundation

/// Response from the /api/mountains/[mountainId]/history endpoint
struct SnowHistoryResponse: Codable {
    let mountain: SnowHistoryMountain?
    let history: [SnowHistoryPoint]
    let days: Int?
    let source: SnowHistorySource?
}

/// Mountain info in the history response
struct SnowHistoryMountain: Codable {
    let id: String
    let name: String
    let shortName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
    }
}

/// A single data point in the snow history
struct SnowHistoryPoint: Codable, Identifiable {
    var id: String { date }
    let date: String
    let snowDepth: Int?
    let snowfall: Int?
    let temperature: Int?

    enum CodingKeys: String, CodingKey {
        case date
        case snowDepth = "snow_depth"
        case snowfall
        case temperature
    }
}

/// Source information for the snow data
struct SnowHistorySource: Codable {
    let provider: String?
    let stationName: String?
    let stationId: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case stationName = "station_name"
        case stationId = "station_id"
    }
}
