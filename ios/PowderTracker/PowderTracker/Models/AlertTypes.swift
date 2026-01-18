import SwiftUI

// MARK: - Alert Severity

enum AlertSeverity: String, Codable, CaseIterable {
    case info
    case advisory
    case watch
    case warning
    case emergency

    var color: Color {
        switch self {
        case .info: return .blue
        case .advisory: return .yellow
        case .watch: return .orange
        case .warning: return .red
        case .emergency: return .purple
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .advisory: return "exclamationmark.circle.fill"
        case .watch: return "eye.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .emergency: return "bolt.fill"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    /// Convert from NWS severity string
    init(from nwsSeverity: String) {
        switch nwsSeverity.lowercased() {
        case "extreme": self = .emergency
        case "severe": self = .warning
        case "moderate": self = .watch
        case "minor": self = .advisory
        default: self = .info
        }
    }
}

// MARK: - Alert Type

enum AlertType: String, Codable, CaseIterable {
    case weather
    case avalanche
    case road
    case lift
    case general

    var icon: String {
        switch self {
        case .weather: return "cloud.bolt.fill"
        case .avalanche: return "mountain.2.fill"
        case .road: return "car.fill"
        case .lift: return "cablecar.fill"
        case .general: return "exclamationmark.circle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .weather: return "Weather"
        case .avalanche: return "Avalanche"
        case .road: return "Road"
        case .lift: return "Lift"
        case .general: return "General"
        }
    }
}

// MARK: - Mountain Alert (Enhanced)

struct MountainAlert: Identifiable, Codable {
    let id: String
    let mountainId: String?
    let type: AlertType
    let severity: AlertSeverity
    let title: String
    let message: String
    let source: String
    let sourceUrl: String?
    let issuedAt: Date
    let expiresAt: Date?
    let affectedAreas: [String]

    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() > expires
    }
}

// MARK: - WeatherAlert Extensions

extension WeatherAlert {
    var alertSeverity: AlertSeverity {
        AlertSeverity(from: severity)
    }

    var alertType: AlertType {
        let eventLower = event.lowercased()
        if eventLower.contains("avalanche") {
            return .avalanche
        } else if eventLower.contains("road") || eventLower.contains("travel") {
            return .road
        }
        return .weather
    }
}

// MARK: - Mock Data

extension MountainAlert {
    static let mock = MountainAlert(
        id: "alert-1",
        mountainId: "crystal-mountain",
        type: .weather,
        severity: .warning,
        title: "Winter Storm Warning",
        message: "Heavy snow expected. 12-18 inches above 4000 feet through Saturday morning.",
        source: "NWS Seattle",
        sourceUrl: "https://weather.gov/alerts",
        issuedAt: Date(),
        expiresAt: Date().addingTimeInterval(86400),
        affectedAreas: ["Crystal Mountain", "White Pass", "Stevens Pass"]
    )

    static let mockAvalanche = MountainAlert(
        id: "alert-2",
        mountainId: nil,
        type: .avalanche,
        severity: .watch,
        title: "Avalanche Watch",
        message: "Considerable avalanche danger on north-facing slopes above treeline.",
        source: "NWAC",
        sourceUrl: "https://nwac.us",
        issuedAt: Date(),
        expiresAt: Date().addingTimeInterval(43200),
        affectedAreas: ["West Slopes North", "West Slopes Central"]
    )
}
