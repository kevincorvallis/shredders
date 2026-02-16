//
//  ChartTokens.swift
//  PowderTracker
//
//  Chart sizing tokens, data types, and chart color/gradient extensions
//

import SwiftUI
import UIKit

// MARK: - Chart Tokens

extension CGFloat {
    /// Chart Heights - consistent sizing for different contexts
    static let chartHeightCompact: CGFloat = 120    // Sparklines, inline charts
    static let chartHeightStandard: CGFloat = 180   // Cards, sections
    static let chartHeightHero: CGFloat = 240       // Full-screen charts

    /// Chart Line Widths - consistent stroke widths
    static let chartLineWidthThin: CGFloat = 1.5    // Secondary lines, grids
    static let chartLineWidthMedium: CGFloat = 2.5  // Primary lines (default)
    static let chartLineWidthBold: CGFloat = 3.5    // Emphasized lines

    /// Chart Axis & Labels
    static let chartAxisLabelSpacing: CGFloat = 4   // Space between axis and labels
    static let chartAnnotationSize: CGFloat = 20    // Size of annotation icons

    /// Chart Selection
    static let chartSelectionIndicatorSize: CGFloat = 10  // Selection dot size
}

/// Data types for chart coloring
enum ChartDataType {
    case snowfall      // Fresh snow amounts
    case snowDepth     // Total snow depth
    case temperature   // Temperature readings
    case wind          // Wind speed
    case cumulative    // Cumulative/running totals
    case comparison    // Historical comparison
}

extension Color {
    /// Primary color for chart data types
    static func chartPrimary(for dataType: ChartDataType) -> Color {
        switch dataType {
        case .snowfall:
            return Color(UIColor.systemCyan)
        case .snowDepth:
            return Color(UIColor.systemBlue)
        case .temperature:
            return Color(UIColor.systemOrange)
        case .wind:
            return Color(UIColor.systemGray)
        case .cumulative:
            return Color(UIColor.systemIndigo)
        case .comparison:
            return Color(UIColor.systemPurple)
        }
    }

    /// Secondary color for chart data types (lighter/faded)
    static func chartSecondary(for dataType: ChartDataType) -> Color {
        chartPrimary(for: dataType).opacity(0.3)
    }
}

extension LinearGradient {
    /// Gradient fill for chart areas
    static func chartGradient(for dataType: ChartDataType) -> LinearGradient {
        let primaryColor = Color.chartPrimary(for: dataType)
        return LinearGradient(
            colors: [
                primaryColor.opacity(0.4),
                primaryColor.opacity(0.1),
                primaryColor.opacity(0.02)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Gradient for powder day highlights
    static let powderDayHighlight = LinearGradient(
        colors: [
            Color.cyan.opacity(0.6),
            Color.blue.opacity(0.4),
            Color.cyan.opacity(0.1)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}
