//
//  SpacingTokens.swift
//  PowderTracker
//
//  Spacing, opacity, icon sizes, and corner radius tokens
//

import SwiftUI

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

    // MARK: - iPad Layout Constants
    /// Maximum content widths to prevent stretched layouts on iPad
    static let maxContentWidthCompact: CGFloat = 500   // Single column content (forms, cards)
    static let maxContentWidthRegular: CGFloat = 700   // Wider content (detail views)
    static let maxContentWidthFull: CGFloat = 1000     // Full-width dashboards

    /// Sidebar dimensions for iPad NavigationSplitView
    static let sidebarMinWidth: CGFloat = 280
    static let sidebarMaxWidth: CGFloat = 400

    /// Adaptive grid column sizing
    static let gridColumnMinWidth: CGFloat = 160       // Minimum card width in grid
    static let gridColumnIdealWidth: CGFloat = 200     // Ideal card width
    static let gridColumnMaxWidth: CGFloat = 300       // Maximum card width
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
    static let cornerRadiusTiny: CGFloat = 4     // Progress bars, tiny indicators
    static let cornerRadiusMicro: CGFloat = 6    // Small pills and badges
    static let cornerRadiusButton: CGFloat = 8   // Buttons and action items
    static let cornerRadiusSmall: CGFloat = 10   // Compact cards, input fields
    static let cornerRadiusCard: CGFloat = 12    // Standard cards (DEFAULT)
    static let cornerRadiusHero: CGFloat = 16    // Hero/featured cards
    static let cornerRadiusBubble: CGFloat = 18  // Chat bubbles
    static let cornerRadiusPill: CGFloat = 20    // Pills, large rounded elements

    /// Concentric Corner Radius Calculation
    /// For nested elements: childRadius = parentRadius - padding
    static func concentricRadius(parent: CGFloat, padding: CGFloat) -> CGFloat {
        Swift.max(0, parent - padding)
    }
}
