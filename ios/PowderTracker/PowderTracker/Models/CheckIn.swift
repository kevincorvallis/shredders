import Foundation

struct CheckIn: Codable, Identifiable {
    let id: String
    let userId: String
    let mountainId: String
    let checkInTime: Date
    let checkOutTime: Date?
    let tripReport: String?
    let rating: Int?
    let snowQuality: String?
    let crowdLevel: String?
    let weatherConditions: [String: String]?
    let likesCount: Int
    let commentsCount: Int
    let isPublic: Bool
    let user: CheckInUser?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mountainId = "mountain_id"
        case checkInTime = "check_in_time"
        case checkOutTime = "check_out_time"
        case tripReport = "trip_report"
        case rating
        case snowQuality = "snow_quality"
        case crowdLevel = "crowd_level"
        case weatherConditions = "weather_conditions"
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case isPublic = "is_public"
        case user
    }
}

struct CheckInUser: Codable {
    let id: String
    let username: String
    let displayName: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}

// Response wrappers
struct CheckInsResponse: Codable {
    let checkIns: [CheckIn]

    enum CodingKeys: String, CodingKey {
        case checkIns = "checkIns"
    }
}

struct CheckInResponse: Codable {
    let checkIn: CheckIn

    enum CodingKeys: String, CodingKey {
        case checkIn = "checkIn"
    }
}

// Enums for dropdown values
enum SnowQuality: String, CaseIterable {
    case powder = "powder"
    case packedPowder = "packed-powder"
    case groomed = "groomed"
    case hardPack = "hard-pack"
    case icy = "icy"
    case slushy = "slushy"
    case variable = "variable"

    var displayName: String {
        switch self {
        case .powder: return "Powder"
        case .packedPowder: return "Packed Powder"
        case .groomed: return "Groomed"
        case .hardPack: return "Hard Pack"
        case .icy: return "Icy"
        case .slushy: return "Slushy"
        case .variable: return "Variable"
        }
    }
}

enum CrowdLevel: String, CaseIterable {
    case empty = "empty"
    case light = "light"
    case moderate = "moderate"
    case busy = "busy"
    case packed = "packed"

    var displayName: String {
        rawValue.capitalized
    }
}
