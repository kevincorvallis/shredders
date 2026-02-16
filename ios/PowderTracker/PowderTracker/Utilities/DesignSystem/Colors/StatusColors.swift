//
//  StatusColors.swift
//  PowderTracker
//
//  Color helpers for status, conditions, and model enums
//

import SwiftUI
import UIKit
import Foundation

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

    /// Snow depth quality color mapping (inches)
    /// Green = excellent (100"+), Blue = good (60-100"), Yellow = fair (30-60"), Orange = thin (<30")
    static func forSnowDepth(_ inches: Int) -> Color {
        switch inches {
        case 100...: return Color(UIColor.systemGreen)
        case 60..<100: return Color(UIColor.systemBlue)
        case 30..<60: return Color(UIColor.systemYellow)
        default: return Color(UIColor.systemOrange)
        }
    }

    /// Snow depth quality label
    static func snowDepthQuality(_ inches: Int) -> String {
        switch inches {
        case 100...: return "Excellent"
        case 60..<100: return "Good"
        case 30..<60: return "Fair"
        default: return "Thin"
        }
    }
}

// MARK: - Color Extensions for Model Enums

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
