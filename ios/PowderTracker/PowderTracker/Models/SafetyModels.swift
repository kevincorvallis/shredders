//
//  SafetyModels.swift
//  PowderTracker
//
//  Models for safety data from the patrol endpoint
//

import Foundation

// MARK: - Safety Response

struct SafetyData: Codable {
    let mountain: SafetyMountainInfo
    let assessment: SafetyAssessment
    let weather: SafetyWeather
    let hazards: SafetyHazards?
}

struct SafetyMountainInfo: Codable {
    let id: String
    let name: String
    let shortName: String
}

struct SafetyAssessment: Codable {
    let level: String
    let description: String
    let recommendations: [String]
}

struct SafetyWeather: Codable {
    let temperature: Int?
    let feelsLike: Int?
    let humidity: Int?
    let visibility: Double?
    let pressure: Double?
    let uvIndex: Int?
    let wind: SafetyWindData?
}

struct SafetyWindData: Codable {
    let speed: Int
    let gust: Int?
    let direction: String
}

struct SafetyHazards: Codable {
    let avalanche: SafetyHazardLevel?
    let treeWells: SafetyHazardLevel?
    let icy: SafetyHazardLevel?
    let crowded: SafetyHazardLevel?
}

struct SafetyHazardLevel: Codable {
    let level: String
    let description: String?
}

// MARK: - Safety Level Enum

enum SafetyLevel: String, CaseIterable {
    case low = "low"
    case moderate = "moderate"
    case considerable = "considerable"
    case high = "high"
    case extreme = "extreme"

    init(from string: String) {
        self = SafetyLevel(rawValue: string.lowercased()) ?? .moderate
    }

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .considerable: return "Considerable"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }

    var dotCount: Int {
        switch self {
        case .low: return 1
        case .moderate: return 2
        case .considerable: return 3
        case .high: return 4
        case .extreme: return 5
        }
    }
}
