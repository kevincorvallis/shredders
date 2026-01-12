//
//  DesignSystem.swift
//  PowderTracker
//
//  Design system constants following iOS HIG and 8pt grid system
//

import SwiftUI
import UIKit

// MARK: - Spacing Constants

extension CGFloat {
    /// 8-Point Grid System
    /// All spacing follows multiples of 8pt for consistency
    static let spacingXS: CGFloat = 4    // Micro-spacing within tightly grouped elements
    static let spacingS: CGFloat = 8     // Tight spacing between related items
    static let spacingM: CGFloat = 12    // Default card padding (RECOMMENDED)
    static let spacingL: CGFloat = 16    // Section padding and between-card spacing
    static let spacingXL: CGFloat = 20   // Major section breaks
    static let spacingXXL: CGFloat = 24  // Hero sections and screen margins
}

// MARK: - Opacity Tokens

extension Double {
    /// Standard opacity levels for consistent visual hierarchy
    static let opacitySubtle: Double = 0.08   // Very subtle overlays, light shadows
    static let opacityLight: Double = 0.12    // Light overlays, secondary shadows
    static let opacityMedium: Double = 0.15   // Medium emphasis overlays
    static let opacityBold: Double = 0.3      // Strong emphasis overlays
}

// MARK: - Icon & Indicator Sizes

extension CGFloat {
    /// Standard icon sizes
    static let iconSmall: CGFloat = 16     // Inline icons, small badges
    static let iconMedium: CGFloat = 24    // Default icon size
    static let iconLarge: CGFloat = 32     // Feature icons
    static let iconHero: CGFloat = 60      // Hero section icons

    /// Status indicator sizes
    static let statusDotSize: CGFloat = 6      // Small status dots
    static let statusIndicatorSize: CGFloat = 8 // Default status indicators
}

// MARK: - Corner Radius

extension CGFloat {
    /// Corner Radius Standards (2025)
    static let cornerRadiusMicro: CGFloat = 6    // Small pills and badges
    static let cornerRadiusButton: CGFloat = 8   // Buttons and action items
    static let cornerRadiusCard: CGFloat = 12    // Standard cards (DEFAULT)
    static let cornerRadiusHero: CGFloat = 16    // Hero/featured cards

    /// Concentric Corner Radius Calculation
    /// For nested elements: childRadius = parentRadius - padding
    static func concentricRadius(parent: CGFloat, padding: CGFloat) -> CGFloat {
        Swift.max(0, parent - padding)
    }
}

// MARK: - Shadow Styles

extension View {
    /// Subtle shadow for cards (dark mode compatible)
    func cardShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
    }

    /// Elevated shadow for hero cards
    func heroShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Typography Helpers

extension View {
    /// Apply consistent font styling
    func heroNumber() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .fontDesign(.rounded)
    }

    func sectionHeader() -> some View {
        self
            .font(.headline)
            .fontWeight(.semibold)
    }

    func cardTitle() -> some View {
        self
            .font(.title3)
            .fontWeight(.semibold)
    }

    func metric() -> some View {
        self
            .font(.subheadline)
            .fontWeight(.semibold)
    }

    func badge() -> some View {
        self
            .font(.caption2)
            .fontWeight(.bold)
    }
}

// MARK: - Standard Modifiers

extension View {
    /// Standard card styling with tight spacing
    func standardCard(padding: CGFloat = .spacingM) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
            .cardShadow()
    }

    /// Hero card styling with more prominent appearance
    func heroCard(padding: CGFloat = .spacingL) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusHero)
            .heroShadow()
    }

    /// Compact list item styling
    func listCard(padding: CGFloat = .spacingM) -> some View {
        self
            .padding(padding)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
    }

    /// Status pill/badge styling with color background
    func statusPill(color: Color, padding: CGFloat = .spacingS) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.5)
            .background(color.opacity(.opacityMedium))
            .cornerRadius(.cornerRadiusMicro)
    }

    /// Focus border overlay for selected/highlighted states
    func focusBorder(color: Color = .blue, width: CGFloat = 2) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .stroke(color, lineWidth: width)
        )
    }

    /// Metric value styling for numeric displays
    func metricValue(size: Font.TextStyle = .subheadline) -> some View {
        self
            .font(.system(size, design: .rounded))
            .fontWeight(.semibold)
            .monospacedDigit()
    }
}

// MARK: - Animation Constants

extension Animation {
    /// Standard spring animation for UI interactions
    static let standardSpring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Smooth ease for subtle transitions
    static let smoothEase = Animation.easeInOut(duration: 0.3)
}

// MARK: - Color Helpers

extension Color {
    /// Status colors that adapt to dark mode
    static func statusColor(for value: Double, greenThreshold: Double = 7.0, yellowThreshold: Double = 5.0) -> Color {
        if value >= greenThreshold {
            return Color(UIColor.systemGreen)
        } else if value >= yellowThreshold {
            return Color(UIColor.systemYellow)
        } else {
            return Color(UIColor.systemRed)
        }
    }

    /// Crowd level colors
    static func crowdColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "low": return Color(UIColor.systemGreen)
        case "medium": return Color(UIColor.systemYellow)
        case "high", "extreme": return Color(UIColor.systemRed)
        default: return Color(UIColor.systemGray)
        }
    }

    /// Powder score color mapping (0-10 scale)
    static func forPowderScore(_ score: Double) -> Color {
        switch score {
        case 8.0...: return Color(UIColor.systemGreen)
        case 6.0..<8.0: return Color(UIColor.systemYellow)
        case 4.0..<6.0: return Color(UIColor.systemOrange)
        default: return Color(UIColor.systemRed)
        }
    }

    /// Lift percentage color mapping (0-100%)
    static func forLiftPercentage(_ percentage: Int) -> Color {
        switch percentage {
        case 80...: return Color(UIColor.systemGreen)
        case 50..<80: return Color(UIColor.systemYellow)
        case 20..<50: return Color(UIColor.systemOrange)
        default: return Color(UIColor.systemRed)
        }
    }

    /// Temperature-based color mapping (Fahrenheit)
    static func forTemperature(_ tempF: Int) -> Color {
        switch tempF {
        case ..<20: return Color(UIColor.systemBlue)
        case 20..<32: return Color(UIColor.systemCyan)
        case 32..<40: return Color(UIColor.systemGreen)
        default: return Color(UIColor.systemOrange)
        }
    }

    /// Wind speed color mapping (mph)
    static func forWindSpeed(_ mph: Int) -> Color {
        switch mph {
        case ..<10: return Color(UIColor.systemGreen)
        case 10..<20: return Color(UIColor.systemYellow)
        case 20..<30: return Color(UIColor.systemOrange)
        default: return Color(UIColor.systemRed)
        }
    }
}

// MARK: - Color Extensions for Model Enums

import Foundation

extension Color {
    /// Confidence level color (used in ArrivalTime and ParkingPrediction)
    static func forConfidenceLevel(_ confidence: String) -> Color {
        switch confidence.lowercased() {
        case "high": return Color(UIColor.systemGreen)
        case "medium": return Color(UIColor.systemYellow)
        case "low": return Color(UIColor.systemGray)
        default: return Color(UIColor.systemGray)
        }
    }

    /// Parking difficulty color
    static func forParkingDifficulty(_ difficulty: String) -> Color {
        switch difficulty.lowercased() {
        case "easy": return Color(UIColor.systemGreen)
        case "moderate": return Color(UIColor.systemYellow)
        case "challenging": return Color(UIColor.systemOrange)
        case "very-difficult", "verydifficult": return Color(UIColor.systemRed)
        default: return Color(UIColor.systemGray)
        }
    }
}
