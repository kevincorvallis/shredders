//
//  SkiIcons.swift
//  PowderTracker
//
//  Ski-specific icon mappings using SF Symbols
//

import SwiftUI

// MARK: - Ski-Specific Icons

/// Ski-specific icon mappings using SF Symbols
/// Use these semantic names for consistent iconography throughout the app
enum SkiIcon {
    // MARK: - Weather & Conditions
    case snowfall
    case snowflake
    case freshPowder
    case temperature
    case wind
    case visibility
    case clouds
    case sunny
    case storm
    case avalanche

    // MARK: - Mountain & Terrain
    case mountain
    case mountainPeak
    case trail
    case terrain
    case trees
    case openBowl

    // MARK: - Lifts & Operations
    case lift
    case liftOpen
    case liftClosed
    case liftHold
    case gondola
    case chairlift
    case surfaceLift

    // MARK: - Activities & Actions
    case skiing
    case favorite
    case favoriteOutline
    case share
    case navigate
    case directions
    case refresh
    case alert
    case info
    case settings

    // MARK: - Status & Indicators
    case open
    case closed
    case limited
    case trending
    case trendingUp
    case trendingDown
    case score

    // MARK: - Time & Schedule
    case schedule
    case sunrise
    case sunset
    case clock
    case calendar

    /// The SF Symbol name for this icon
    var systemName: String {
        switch self {
        // Weather & Conditions
        case .snowfall: return "cloud.snow.fill"
        case .snowflake: return "snowflake"
        case .freshPowder: return "snowflake.circle.fill"
        case .temperature: return "thermometer.medium"
        case .wind: return "wind"
        case .visibility: return "eye"
        case .clouds: return "cloud.fill"
        case .sunny: return "sun.max.fill"
        case .storm: return "cloud.bolt.rain.fill"
        case .avalanche: return "exclamationmark.triangle.fill"

        // Mountain & Terrain
        case .mountain: return "mountain.2.fill"
        case .mountainPeak: return "mountain.2"
        case .trail: return "point.topleft.down.to.point.bottomright.curvepath"
        case .terrain: return "square.grid.3x3.topleft.filled"
        case .trees: return "tree.fill"
        case .openBowl: return "circle.hexagongrid.fill"

        // Lifts & Operations
        case .lift: return "arrow.up.right"
        case .liftOpen: return "arrow.up.right.circle.fill"
        case .liftClosed: return "xmark.circle.fill"
        case .liftHold: return "pause.circle.fill"
        case .gondola: return "cable.car.fill"
        case .chairlift: return "cablecar.fill"
        case .surfaceLift: return "arrow.up.to.line"

        // Activities & Actions
        case .skiing: return "figure.skiing.downhill"
        case .favorite: return "star.fill"
        case .favoriteOutline: return "star"
        case .share: return "square.and.arrow.up"
        case .navigate: return "location.fill"
        case .directions: return "arrow.triangle.turn.up.right.diamond.fill"
        case .refresh: return "arrow.clockwise"
        case .alert: return "bell.fill"
        case .info: return "info.circle"
        case .settings: return "gearshape"

        // Status & Indicators
        case .open: return "checkmark.circle.fill"
        case .closed: return "xmark.circle.fill"
        case .limited: return "exclamationmark.circle.fill"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .trendingUp: return "arrow.up.right"
        case .trendingDown: return "arrow.down.right"
        case .score: return "star.circle.fill"

        // Time & Schedule
        case .schedule: return "calendar.badge.clock"
        case .sunrise: return "sunrise.fill"
        case .sunset: return "sunset.fill"
        case .clock: return "clock"
        case .calendar: return "calendar"
        }
    }

    /// The filled variant if available, otherwise same as systemName
    var filledSystemName: String {
        switch self {
        case .mountainPeak: return "mountain.2.fill"
        case .favoriteOutline: return "star.fill"
        case .info: return "info.circle.fill"
        case .settings: return "gearshape.fill"
        case .clock: return "clock.fill"
        default: return systemName
        }
    }

    /// Recommended color for this icon
    var defaultColor: Color {
        switch self {
        // Weather colors
        case .snowfall, .snowflake, .freshPowder: return .cyan
        case .temperature: return .orange
        case .wind: return .gray
        case .sunny: return .yellow
        case .clouds: return .gray
        case .storm, .avalanche: return .red
        case .visibility: return .secondary

        // Mountain colors
        case .mountain, .mountainPeak, .trail, .terrain, .trees, .openBowl: return .blue

        // Lift status colors
        case .liftOpen, .open: return .green
        case .liftClosed, .closed: return .red
        case .liftHold, .limited: return .orange
        case .lift, .gondola, .chairlift, .surfaceLift: return .primary

        // Activity colors
        case .skiing: return .blue
        case .favorite: return .yellow
        case .favoriteOutline: return .secondary
        case .share, .navigate, .directions, .refresh, .info, .settings: return .blue
        case .alert: return .orange

        // Trend colors
        case .trending, .score: return .blue
        case .trendingUp: return .green
        case .trendingDown: return .red

        // Time colors
        case .schedule, .clock, .calendar: return .secondary
        case .sunrise: return .orange
        case .sunset: return .purple
        }
    }
}

/// SwiftUI Image view using SkiIcon
struct SkiIconView: View {
    let icon: SkiIcon
    var size: CGFloat = 24
    var filled: Bool = true
    var useDefaultColor: Bool = true
    var color: Color?

    var body: some View {
        Image(systemName: filled ? icon.filledSystemName : icon.systemName)
            .font(.system(size: size))
            .foregroundColor(color ?? (useDefaultColor ? icon.defaultColor : .primary))
            .symbolRenderingMode(.hierarchical)
    }
}
