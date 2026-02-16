//
//  GradientPresets.swift
//  PowderTracker
//
//  Gradient presets, score-based gradients, and PookieBSnow branding
//

import SwiftUI

// MARK: - Gradient Presets

extension LinearGradient {
    /// Powder blue gradient for snow/ski themes
    static let powderBlue = LinearGradient(
        colors: [Color(red: 0.4, green: 0.6, blue: 0.9), Color(red: 0.2, green: 0.4, blue: 0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Sunny day gradient for clear weather
    static let sunnyDay = LinearGradient(
        colors: [Color(red: 1.0, green: 0.85, blue: 0.4), Color(red: 1.0, green: 0.6, blue: 0.2)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Fresh snow gradient for powder alerts
    static let freshSnow = LinearGradient(
        colors: [Color.white, Color(red: 0.9, green: 0.95, blue: 1.0)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Night ski gradient for evening conditions
    static let nightSki = LinearGradient(
        colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.05, green: 0.05, blue: 0.15)],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Powder day alert gradient (animated shimmer)
    static let powderAlert = LinearGradient(
        colors: [
            Color(red: 0.3, green: 0.7, blue: 1.0),
            Color(red: 0.5, green: 0.8, blue: 1.0),
            Color.white.opacity(0.9),
            Color(red: 0.5, green: 0.8, blue: 1.0),
            Color(red: 0.3, green: 0.7, blue: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Status gradient for excellent conditions (green)
    static let statusExcellent = LinearGradient(
        colors: [Color.green.opacity(0.8), Color.green],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Status gradient for good conditions (yellow)
    static let statusGood = LinearGradient(
        colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Status gradient for poor conditions (red)
    static let statusPoor = LinearGradient(
        colors: [Color.orange, Color.red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Score-Based Gradient

extension LinearGradient {
    /// Returns appropriate gradient for a score (0-10)
    static func forScore(_ score: Double) -> LinearGradient {
        switch score {
        case 8.0...: return .statusExcellent
        case 5.0..<8.0: return .statusGood
        default: return .statusPoor
        }
    }
}

// MARK: - PookieBSnow Branding

extension LinearGradient {
    /// PookieBSnow signature gradient (pink → purple → cyan)
    /// Named after Pookie (Beryl) and Brock the golden doodle
    static let pookieBSnow = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.5, blue: 0.7),   // Pink
            Color(red: 0.7, green: 0.4, blue: 0.9),   // Purple
            Color(red: 0.4, green: 0.75, blue: 1.0)   // Cyan
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Warm golden doodle gradient (inspired by Brock's fur)
    static let brockGolden = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.88, blue: 0.5),  // Light golden
            Color(red: 1.0, green: 0.75, blue: 0.35)  // Warm golden
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Cozy winter sunset (warm colors for a cold day)
    static let winterSunset = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.65, blue: 0.45), // Peach
            Color(red: 0.95, green: 0.45, blue: 0.6), // Rose
            Color(red: 0.65, green: 0.35, blue: 0.85) // Purple
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Deep winter night (background for intro/welcome)
    static let winterNight = LinearGradient(
        colors: [
            Color(red: 0.08, green: 0.12, blue: 0.22),
            Color(red: 0.12, green: 0.18, blue: 0.28),
            Color(red: 0.18, green: 0.24, blue: 0.38)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    /// PookieBSnow brand colors
    static let pookiePink = Color(red: 1.0, green: 0.5, blue: 0.7)
    static let pookiePurple = Color(red: 0.7, green: 0.4, blue: 0.9)
    static let pookieCyan = Color(red: 0.4, green: 0.75, blue: 1.0)
    static let brockGold = Color(red: 1.0, green: 0.85, blue: 0.5)
}
