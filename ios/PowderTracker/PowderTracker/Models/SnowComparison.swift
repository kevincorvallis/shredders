import Foundation

struct SnowComparisonResponse: Codable {
    let mountain: MountainElevationInfo
    let comparison: YearOverYearComparison
    let baseDepthGuidelines: BaseDepthGuidelines
}

struct MountainElevationInfo: Codable {
    let id: String
    let name: String
    let elevation: MountainElevation
    let elevationCategory: String
}

struct YearOverYearComparison: Codable {
    let current: SnowDepthDataPoint?
    let lastYear: SnowDepthDataPoint?
    let difference: Int?
    let percentChange: Int?
}

struct SnowDepthDataPoint: Codable {
    let date: String
    let snowDepth: Int
}

struct BaseDepthGuidelines: Codable {
    let elevationCategory: String
    let thresholds: DepthThresholds
    let currentRating: BaseDepthRating?
}

struct DepthThresholds: Codable {
    let minimal: Int
    let poor: Int
    let fair: Int
    let good: Int
    let excellent: Int
}

struct BaseDepthRating: Codable {
    let rating: String
    let description: String
    let color: String
}
