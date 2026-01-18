import SwiftUI

// MARK: - Map Overlay Type

enum MapOverlayType: String, CaseIterable, Identifiable {
    case snowfall
    case snowDepth
    case radar
    case clouds
    case temperature
    case wind
    case avalanche
    case smoke
    case landOwnership
    case offlineMaps

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .snowfall: return "Snowfall"
        case .snowDepth: return "Depth"
        case .radar: return "Radar"
        case .clouds: return "Clouds"
        case .temperature: return "Temp"
        case .wind: return "Wind"
        case .avalanche: return "Avalanche"
        case .smoke: return "Smoke"
        case .landOwnership: return "Land"
        case .offlineMaps: return "Offline"
        }
    }

    var fullName: String {
        switch self {
        case .snowfall: return "Snowfall Forecast"
        case .snowDepth: return "Snow Depth"
        case .radar: return "Radar / Precipitation"
        case .clouds: return "Cloud Cover"
        case .temperature: return "Temperature"
        case .wind: return "Wind"
        case .avalanche: return "Avalanche Advisory"
        case .smoke: return "Smoke / Air Quality"
        case .landOwnership: return "Land Ownership"
        case .offlineMaps: return "Offline Maps"
        }
    }

    var icon: String {
        switch self {
        case .snowfall: return "❄️"
        case .snowDepth: return "📏"
        case .radar: return "🌧️"
        case .clouds: return "☁️"
        case .temperature: return "🌡️"
        case .wind: return "💨"
        case .avalanche: return "⚠️"
        case .smoke: return "🔥"
        case .landOwnership: return "🏞️"
        case .offlineMaps: return "📥"
        }
    }

    var systemIcon: String {
        switch self {
        case .snowfall: return "snowflake"
        case .snowDepth: return "ruler"
        case .radar: return "cloud.rain.fill"
        case .clouds: return "cloud.fill"
        case .temperature: return "thermometer.medium"
        case .wind: return "wind"
        case .avalanche: return "exclamationmark.triangle.fill"
        case .smoke: return "smoke.fill"
        case .landOwnership: return "map"
        case .offlineMaps: return "arrow.down.circle"
        }
    }

    var description: String {
        switch self {
        case .snowfall: return "Accumulation over time"
        case .snowDepth: return "Current snowpack depth"
        case .radar: return "Live + forecast"
        case .clouds: return "Satellite imagery"
        case .temperature: return "Surface temps"
        case .wind: return "Speed and direction"
        case .avalanche: return "NWAC danger ratings"
        case .smoke: return "AQI overlay"
        case .landOwnership: return "Public/private land"
        case .offlineMaps: return "Download for offline"
        }
    }

    var category: OverlayCategory {
        switch self {
        case .snowfall, .snowDepth, .radar, .clouds, .temperature, .wind:
            return .weather
        case .avalanche, .smoke:
            return .safety
        case .landOwnership, .offlineMaps:
            return .other
        }
    }

    var isTimeBased: Bool {
        switch self {
        case .snowfall, .radar:
            return true
        default:
            return false
        }
    }

    var isComingSoon: Bool {
        switch self {
        case .landOwnership, .offlineMaps:
            return true
        default:
            return false
        }
    }

    /// Time intervals available for time-based overlays
    var timeIntervals: [TimeInterval]? {
        guard isTimeBased else { return nil }
        switch self {
        case .snowfall:
            return [3, 6, 12, 24, 48, 72].map { $0 * 3600 }
        case .radar:
            return [0, 1, 2, 3, 4, 5, 6].map { $0 * 3600 }
        default:
            return nil
        }
    }
}

// MARK: - Overlay Category

enum OverlayCategory: String, CaseIterable {
    case weather = "Weather"
    case safety = "Safety"
    case other = "Other"

    var overlays: [MapOverlayType] {
        MapOverlayType.allCases.filter { $0.category == self }
    }
}

// MARK: - Map Overlay State

@MainActor
class MapOverlayState: ObservableObject, @unchecked Sendable {
    @Published var activeOverlay: MapOverlayType? = nil
    @Published var selectedTimeOffset: TimeInterval = 0
    @Published var isAnimating: Bool = false

    func toggle(_ overlay: MapOverlayType) {
        if activeOverlay == overlay {
            activeOverlay = nil
        } else {
            activeOverlay = overlay
            selectedTimeOffset = 0
        }
    }

    func clear() {
        activeOverlay = nil
        selectedTimeOffset = 0
        isAnimating = false
    }
}

// MARK: - Legend Configuration

struct OverlayLegend {
    let title: String
    let items: [LegendItem]

    struct LegendItem {
        let color: Color
        let label: String
    }
}

extension MapOverlayType {
    var legend: OverlayLegend? {
        switch self {
        case .snowfall:
            return OverlayLegend(
                title: "Snowfall",
                items: [
                    .init(color: .white.opacity(0.3), label: "0\""),
                    .init(color: .blue.opacity(0.5), label: "6\""),
                    .init(color: .blue.opacity(0.7), label: "12\""),
                    .init(color: .purple.opacity(0.7), label: "24\""),
                    .init(color: .purple, label: "36\"+")
                ]
            )
        case .snowDepth:
            return OverlayLegend(
                title: "Snow Depth",
                items: [
                    .init(color: .gray.opacity(0.3), label: "0\""),
                    .init(color: .cyan.opacity(0.5), label: "24\""),
                    .init(color: .cyan.opacity(0.7), label: "48\""),
                    .init(color: .blue.opacity(0.8), label: "72\""),
                    .init(color: .blue, label: "96\"+")
                ]
            )
        case .avalanche:
            return OverlayLegend(
                title: "Avalanche Danger",
                items: [
                    .init(color: .green, label: "Low"),
                    .init(color: .yellow, label: "Moderate"),
                    .init(color: .orange, label: "Considerable"),
                    .init(color: .red, label: "High"),
                    .init(color: .black, label: "Extreme")
                ]
            )
        case .temperature:
            return OverlayLegend(
                title: "Temperature",
                items: [
                    .init(color: .purple, label: "<10°F"),
                    .init(color: .blue, label: "20°F"),
                    .init(color: .cyan, label: "32°F"),
                    .init(color: .green, label: "40°F"),
                    .init(color: .yellow, label: "50°F+")
                ]
            )
        default:
            return nil
        }
    }
}
