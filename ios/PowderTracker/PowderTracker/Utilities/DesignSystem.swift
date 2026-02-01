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

    /// Adaptive shadow that adjusts for dark mode
    /// - Parameters:
    ///   - colorScheme: The current color scheme
    ///   - radius: Base shadow radius (default: 8)
    ///   - y: Vertical offset (default: 4)
    func adaptiveShadow(colorScheme: ColorScheme, radius: CGFloat = 8, y: CGFloat = 4) -> some View {
        self.shadow(
            color: colorScheme == .dark
                ? Color.black.opacity(0.4)
                : Color.black.opacity(0.1),
            radius: colorScheme == .dark ? radius * 1.5 : radius,
            x: 0,
            y: y
        )
    }

    /// Subtle glow effect for highlighted elements
    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius)
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

    /// Bouncy spring for playful interactions (cards, buttons)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0.25)

    /// Snappy spring for quick state changes (toggles, selections)
    static let snappy = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Smooth spring for elegant transitions (modals, sheets)
    static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.85)

    /// Quick interactive response for immediate feedback
    static let interactive = Animation.interactiveSpring(response: 0.15, dampingFraction: 0.86)
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

// MARK: - Material Background Styles

extension View {
    /// Glass morphism background with blur effect
    func glassBackground(cornerRadius: CGFloat = .cornerRadiusCard) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Thick glass background for prominent cards
    func thickGlassBackground(cornerRadius: CGFloat = .cornerRadiusHero) -> some View {
        self
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    /// Subtle glass card with shadow
    func glassCard(padding: CGFloat = .spacingM, cornerRadius: CGFloat = .cornerRadiusCard) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Dynamic Type Support

extension View {
    /// Limits dynamic type size to prevent layout breaks
    /// Caps at accessibility2 for most UI elements
    func limitDynamicType() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Stricter limit for compact UI elements
    /// Caps at accessibility1
    func limitDynamicTypeCompact() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// Strictest limit for very constrained spaces
    /// Caps at xxxLarge
    func limitDynamicTypeStrict() -> some View {
        self.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

// MARK: - SF Symbols Enhancements

extension Image {
    /// Creates a hierarchical symbol with specified color
    func hierarchicalSymbol(_ color: Color = .blue) -> some View {
        self
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
    }

    /// Creates a palette symbol with primary and secondary colors
    func paletteSymbol(primary: Color, secondary: Color) -> some View {
        self
            .symbolRenderingMode(.palette)
            .foregroundStyle(primary, secondary)
    }

    /// Creates a multicolor symbol (uses system colors)
    func multicolorSymbol() -> some View {
        self.symbolRenderingMode(.multicolor)
    }
}

// MARK: - Accessibility Helpers

extension View {
    /// Combines children and provides a comprehensive accessibility label
    func accessibleCard(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
    }

    /// Makes a button more accessible with label and hint
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
}

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

// MARK: - Glassmorphic Button Style

/// A button style with glassmorphic appearance for primary actions
struct GlassmorphicButtonStyle: ButtonStyle {
    var isProminent: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(isProminent ? .white : .primary)
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background {
                if isProminent {
                    LinearGradient.powderBlue
                } else {
                    Color.clear
                }
            }
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(configuration.isPressed ? 0.05 : 0.1), radius: configuration.isPressed ? 4 : 8, x: 0, y: configuration.isPressed ? 2 : 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

/// Secondary glassmorphic button style (less prominent)
struct GlassmorphicSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.primary)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusMicro))
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusMicro)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.snappy, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == GlassmorphicButtonStyle {
    /// Primary glassmorphic button style
    static var glassmorphic: GlassmorphicButtonStyle { GlassmorphicButtonStyle() }

    /// Non-prominent glassmorphic button style
    static var glassmorphicSubtle: GlassmorphicButtonStyle { GlassmorphicButtonStyle(isProminent: false) }
}

extension ButtonStyle where Self == GlassmorphicSecondaryButtonStyle {
    /// Secondary glassmorphic button style for less prominent actions
    static var glassmorphicSecondary: GlassmorphicSecondaryButtonStyle { GlassmorphicSecondaryButtonStyle() }
}

// MARK: - Navigation Haptic Modifier

extension View {
    /// Adds light haptic feedback when tapped - use for navigation actions
    func navigationHaptic() -> some View {
        self.simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    HapticFeedback.light.trigger()
                }
        )
    }

    /// Wraps view with sensory feedback for iOS 17+ navigation
    @ViewBuilder
    func withNavigationFeedback() -> some View {
        if #available(iOS 17.0, *) {
            self.sensoryFeedback(.impact(flexibility: .soft), trigger: true)
        } else {
            self.navigationHaptic()
        }
    }
}

/// Button style that triggers light haptic on press - ideal for navigation buttons
struct NavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                if newValue {
                    HapticFeedback.light.trigger()
                }
            }
    }
}

extension ButtonStyle where Self == NavigationButtonStyle {
    /// Button style with light haptic feedback for navigation
    static var navigation: NavigationButtonStyle { NavigationButtonStyle() }
}

// MARK: - Gradient Status Pills

extension View {
    /// Status pill with gradient background based on score
    func gradientStatusPill(score: Double, padding: CGFloat = .spacingS) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.5)
            .background(
                LinearGradient.forScore(score)
                    .opacity(0.9)
            )
            .clipShape(Capsule())
    }

    /// Status pill with custom gradient
    func gradientPill(_ gradient: LinearGradient, padding: CGFloat = .spacingS) -> some View {
        self
            .padding(.horizontal, padding)
            .padding(.vertical, padding * 0.5)
            .background(gradient)
            .clipShape(Capsule())
    }
}

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

// MARK: - Animated Number Transitions

extension View {
    /// Applies numeric text transition for animated number changes
    func animatedNumber() -> some View {
        self.contentTransition(.numericText())
    }

    /// Animated metric value with numeric transition
    func animatedMetricValue(size: Font.TextStyle = .subheadline) -> some View {
        self
            .font(.system(size, design: .rounded))
            .fontWeight(.semibold)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}

// MARK: - Loading Placeholder

extension View {
    /// Applies redacted placeholder effect for loading states
    /// Use this for simple loading placeholders instead of custom skeleton views
    func loadingPlaceholder(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
    }

    /// Applies shimmer effect to redacted placeholder
    func shimmerPlaceholder(_ isLoading: Bool) -> some View {
        self
            .redacted(reason: isLoading ? .placeholder : [])
            .shimmering(active: isLoading)
    }
}

// MARK: - Powder Day Alert Animation

/// Animated shimmer effect for powder day alerts
struct PowderDayShimmer: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.4),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 200
                }
            }
    }
}

extension View {
    /// Applies animated shimmer effect for powder day alerts
    func powderDayShimmer() -> some View {
        modifier(PowderDayShimmer())
    }
}

// MARK: - Powder Alert Badge

/// A badge component for powder day alerts with animated gradient
struct PowderAlertBadge: View {
    @State private var animateGradient = false
    let text: String

    init(_ text: String = "POWDER DAY") {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingXS)
            .background {
                LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.7, blue: 1.0),
                        Color(red: 0.5, green: 0.8, blue: 1.0),
                        Color(red: 0.3, green: 0.7, blue: 1.0)
                    ],
                    startPoint: animateGradient ? .leading : .trailing,
                    endPoint: animateGradient ? .trailing : .leading
                )
            }
            .clipShape(Capsule())
            .shadow(color: Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.5), radius: 4, x: 0, y: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
    }
}

// MARK: - Modern Sheet Presentation

extension View {
    /// Applies modern sheet presentation styling with glass background and rounded corners
    /// Use this on content inside a .sheet() modifier
    func modernSheetStyle() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(20)
    }

    /// Applies modern sheet presentation with background interaction enabled
    /// Allows user to interact with content behind the sheet
    func modernSheetStyleInteractive() -> some View {
        self
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(20)
            .presentationBackgroundInteraction(.enabled(upThrough: .medium))
    }

    /// Applies modern sheet with custom detents
    func modernSheet(detents: Set<PresentationDetent> = [.medium, .large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(20)
    }
}

// MARK: - iOS 18+ Navigation Transitions

extension View {
    /// Applies zoom navigation transition on iOS 18+
    /// Falls back to default navigation on earlier versions
    @ViewBuilder
    func zoomNavigationTransition<ID: Hashable>(
        sourceID: ID,
        in namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }

    /// Marks view as matched transition source for iOS 18+ zoom transitions
    @ViewBuilder
    func matchedTransitionSourceIfAvailable<ID: Hashable>(
        id: ID,
        in namespace: Namespace.ID
    ) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}

// MARK: - Animated Weather Symbols

/// Animated snowflake icon with falling effect
struct AnimatedSnowflakeIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 24
    var color: Color = .blue

    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundStyle(color)
            .symbolEffect(.variableColor.iterative, options: .repeating, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Animated wind icon with blowing effect
struct AnimatedWindIcon: View {
    @State private var isAnimating = false
    @State private var offset: CGFloat = 0
    var size: CGFloat = 24
    var color: Color = .gray

    var body: some View {
        if #available(iOS 18.0, *) {
            Image(systemName: "wind")
                .font(.system(size: size))
                .foregroundStyle(color)
                .symbolEffect(.wiggle, options: .repeating.speed(0.5), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
        } else {
            // Fallback for iOS 17
            Image(systemName: "wind")
                .font(.system(size: size))
                .foregroundStyle(color)
                .offset(x: offset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        offset = 3
                    }
                }
        }
    }
}

/// Animated sun icon with glow effect
struct AnimatedSunIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 24
    var color: Color = .yellow

    var body: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: size))
            .foregroundStyle(color)
            .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Animated cloud icon with drifting effect
struct AnimatedCloudIcon: View {
    @State private var offset: CGFloat = 0
    var size: CGFloat = 24
    var color: Color = .gray

    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: size))
            .foregroundStyle(color)
            .offset(x: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    offset = 5
                }
            }
    }
}

/// Animated snow cloud icon combining snow and cloud effects
struct AnimatedSnowCloudIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 24
    var color: Color = .blue

    var body: some View {
        Image(systemName: "cloud.snow.fill")
            .font(.system(size: size))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .symbolEffect(.variableColor.iterative, options: .repeating, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Weather icon that selects appropriate animated icon based on conditions
struct AnimatedWeatherIcon: View {
    let condition: String
    var size: CGFloat = 24

    var body: some View {
        switch condition.lowercased() {
        case let c where c.contains("snow"):
            AnimatedSnowCloudIcon(size: size)
        case let c where c.contains("wind"):
            AnimatedWindIcon(size: size)
        case let c where c.contains("sun") || c.contains("clear"):
            AnimatedSunIcon(size: size)
        case let c where c.contains("cloud") || c.contains("overcast"):
            AnimatedCloudIcon(size: size)
        default:
            Image(systemName: "cloud.fill")
                .font(.system(size: size))
                .foregroundStyle(.secondary)
        }
    }
}

/// Animated refresh icon that rotates while loading
struct AnimatedRefreshIcon: View {
    let isLoading: Bool
    var size: CGFloat = 20
    var color: Color = .accentColor

    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isLoading) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rotation = 0
                    }
                }
            }
            .onAppear {
                if isLoading {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

/// Refresh button with rotating animation while loading
struct RefreshButton: View {
    let isLoading: Bool
    let action: () -> Void
    var size: CGFloat = 20

    var body: some View {
        Button(action: action) {
            AnimatedRefreshIcon(isLoading: isLoading, size: size)
        }
        .disabled(isLoading)
    }
}

// MARK: - Action Completion Animations

/// Checkmark animation for successful action completion
struct ActionCompletedCheckmark: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title)
            .foregroundStyle(.green)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    isAnimating = true
                }
            }
    }
}

/// Toast notification for action completion
struct ActionToast: View {
    let message: String
    let icon: String
    var color: Color = .green

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isVisible = true
            }
        }
    }
}

/// View modifier to show action completion animation
struct ActionCompletionModifier: ViewModifier {
    @Binding var showCompletion: Bool
    let message: String
    let icon: String
    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showCompletion {
                    ActionToast(message: message, icon: icon)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showCompletion = false
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.3), value: showCompletion)
    }
}

extension View {
    /// Shows a completion toast when action completes
    func actionCompletion(
        isPresented: Binding<Bool>,
        message: String,
        icon: String = "checkmark.circle.fill",
        duration: Double = 2.0
    ) -> some View {
        modifier(ActionCompletionModifier(
            showCompletion: isPresented,
            message: message,
            icon: icon,
            duration: duration
        ))
    }
}

// MARK: - Shareable Cards

/// Instagram Story-optimized share card for mountain conditions
struct ShareableConditionsCard: View {
    let mountainName: String
    let snowfall24h: Int
    let snowDepth: Int
    let powderScore: Int
    let date: Date

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient.powderBlue
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // App branding
                HStack {
                    Image(systemName: "snowflake")
                        .font(.title2)
                    Text("PowderTracker")
                        .font(.title2.bold())
                }
                .foregroundColor(.white.opacity(0.9))

                Spacer()

                // Mountain name
                Text(mountainName)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Conditions
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(snowfall24h)\"")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Fresh Snow")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 4) {
                        Text("\(snowDepth)\"")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Base Depth")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                // Powder score badge
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 80, height: 80)

                    VStack(spacing: 2) {
                        Text("\(powderScore)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("SCORE")
                            .font(.caption2.bold())
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Date
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(40)
        }
        .frame(width: 390, height: 844) // iPhone 14 Pro dimensions for Stories
    }

    /// Renders the card as a UIImage for sharing
    @MainActor
    func renderAsImage() -> UIImage? {
        let renderer = ImageRenderer(content: self)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }
}

// MARK: - Accessibility-Aware Animations

extension View {
    /// Applies animation only when Reduce Motion is not enabled
    @ViewBuilder
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(animation, value: value)
        }
    }

    /// Spring animation that respects Reduce Motion
    @ViewBuilder
    func accessibleSpring<V: Equatable>(response: Double = 0.4, dampingFraction: Double = 0.7, value: V) -> some View {
        if UIAccessibility.isReduceMotionEnabled {
            self
        } else {
            self.animation(.spring(response: response, dampingFraction: dampingFraction), value: value)
        }
    }
}

/// Environment value for checking reduce motion preference
struct AccessibleAnimationModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Mini Sparkline

/// Compact sparkline chart for showing trends
struct MiniSparkline: View {
    let data: [Double]
    var color: Color = .blue
    var lineWidth: CGFloat = 2
    var showDots: Bool = false

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue > 0 ? maxValue - minValue : 1

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minValue) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // Optional dots at data points
                if showDots {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minValue) / range))

                        Circle()
                            .fill(color)
                            .frame(width: lineWidth * 2, height: lineWidth * 2)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

/// Sparkline with trend indicator
struct SparklineWithTrend: View {
    let data: [Double]
    let label: String
    var color: Color = .blue

    private var trend: TrendDirection {
        guard data.count >= 2 else { return .stable }
        let recent = data.suffix(3).reduce(0, +) / Double(min(3, data.count))
        let older = data.prefix(3).reduce(0, +) / Double(min(3, data.count))
        if recent > older * 1.1 { return .up }
        if recent < older * 0.9 { return .down }
        return .stable
    }

    enum TrendDirection {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .secondary
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: trend.icon)
                    .font(.caption2)
                    .foregroundColor(trend.color)
            }

            MiniSparkline(data: data, color: color, lineWidth: 1.5)
                .frame(height: 20)
        }
    }
}

/// Score history sparkline specifically for powder scores
struct PowderScoreSparkline: View {
    let scores: [Double] // Last 7 days of scores

    var body: some View {
        SparklineWithTrend(
            data: scores,
            label: "7-day trend",
            color: .forPowderScore(scores.last ?? 5)
        )
    }
}

// MARK: - Sticky Section Headers

/// A sticky section header that pins to the top of the scroll view
struct StickySectionHeader<Content: View>: View {
    let title: String
    let count: Int?
    let isSticky: Bool
    let content: () -> Content

    @Environment(\.colorScheme) private var colorScheme

    init(
        title: String,
        count: Int? = nil,
        isSticky: Bool = false,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.title = title
        self.count = count
        self.isSticky = isSticky
        self.content = content
    }

    var body: some View {
        HStack(spacing: .spacingM) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            if let count = count {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.blue))
            }

            Spacer()

            content()
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .background {
            if isSticky {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            } else {
                Rectangle()
                    .fill(Color(.systemGroupedBackground))
            }
        }
        .animation(.easeOut(duration: 0.2), value: isSticky)
    }
}

/// A region header specifically for mountain lists
struct RegionSectionHeader: View {
    let region: String
    let mountainCount: Int
    let isSticky: Bool

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacingM) {
            // Region icon
            Image(systemName: regionIcon)
                .font(.subheadline)
                .foregroundColor(regionColor)
                .frame(width: 24, height: 24)
                .background(Circle().fill(regionColor.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(region)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("\(mountainCount) resort\(mountainCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Collapse indicator when sticky
            if isSticky {
                Image(systemName: "chevron.up")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingM)
        .background {
            Group {
                if isSticky {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.1), radius: 4, y: 2)
                        .blur(radius: 0)
                } else {
                    Rectangle()
                        .fill(Color(.systemGroupedBackground))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSticky)
    }

    private var regionIcon: String {
        switch region.lowercased() {
        case let r where r.contains("washington"):
            return "cloud.rain"
        case let r where r.contains("oregon"):
            return "tree"
        case let r where r.contains("california"):
            return "sun.max"
        case let r where r.contains("colorado"):
            return "snowflake"
        case let r where r.contains("utah"):
            return "sparkles"
        case let r where r.contains("idaho"):
            return "mountain.2"
        case let r where r.contains("montana"):
            return "wind"
        case let r where r.contains("canada"), let r where r.contains("british columbia"):
            return "maple.leaf"
        default:
            return "mountain.2"
        }
    }

    private var regionColor: Color {
        switch region.lowercased() {
        case let r where r.contains("washington"):
            return .blue
        case let r where r.contains("oregon"):
            return .green
        case let r where r.contains("california"):
            return .orange
        case let r where r.contains("colorado"):
            return .purple
        case let r where r.contains("utah"):
            return .cyan
        case let r where r.contains("idaho"):
            return .indigo
        case let r where r.contains("montana"):
            return .teal
        case let r where r.contains("canada"), let r where r.contains("british columbia"):
            return .red
        default:
            return .blue
        }
    }
}

/// Preference key to track sticky header state
struct StickyHeaderPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: [String: CGFloat] = [:]

    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue()) { $1 }
    }
}

/// A grouped list with sticky section headers
struct GroupedListWithStickyHeaders<T: Identifiable, Header: View, Content: View>: View {
    let groups: [(key: String, items: [T])]
    let headerBuilder: (String, Int, Bool) -> Header
    let contentBuilder: (T) -> Content

    @State private var stickyHeaders: Set<String> = []

    init(
        groups: [(key: String, items: [T])],
        @ViewBuilder header: @escaping (String, Int, Bool) -> Header,
        @ViewBuilder content: @escaping (T) -> Content
    ) {
        self.groups = groups
        self.headerBuilder = header
        self.contentBuilder = content
    }

    var body: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(groups, id: \.key) { group in
                Section {
                    ForEach(group.items) { item in
                        contentBuilder(item)
                    }
                } header: {
                    headerBuilder(group.key, group.items.count, stickyHeaders.contains(group.key))
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: StickyHeaderPreferenceKey.self,
                                        value: [group.key: geo.frame(in: .global).minY]
                                    )
                            }
                        )
                }
            }
        }
        .onPreferenceChange(StickyHeaderPreferenceKey.self) { values in
            // Headers are "sticky" when they're at the top of the view
            let newSticky = Set(values.filter { $0.value <= 100 }.keys)
            if newSticky != stickyHeaders {
                withAnimation(.easeOut(duration: 0.15)) {
                    stickyHeaders = newSticky
                }
            }
        }
    }
}

// MARK: - Custom Refresh Indicator

/// A custom pull-to-refresh indicator with animated icon
struct AnimatedRefreshIndicator: View {
    let isRefreshing: Bool
    let progress: CGFloat

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 2)

            // Progress arc
            Circle()
                .trim(from: 0, to: isRefreshing ? 1 : progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .rotationEffect(.degrees(isRefreshing ? rotation : 0))

            // Snow icon
            Image(systemName: "snowflake")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(isRefreshing ? -rotation : 0))
        }
        .frame(width: 32, height: 32)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                rotation = 0
            }
        }
    }
}

/// Pull-to-refresh container with custom indicator
struct PullToRefreshView<Content: View>: View {
    let onRefresh: () async -> Void
    @ViewBuilder let content: () -> Content

    @State private var isRefreshing = false
    @State private var pullProgress: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let offset = geo.frame(in: .global).minY
                    let progress = min(max(offset / 80, 0), 1)

                    Color.clear
                        .preference(key: RefreshProgressKey.self, value: progress)
                        .onChange(of: offset) { _, newValue in
                            if newValue > 80 && !isRefreshing {
                                triggerRefresh()
                            }
                        }
                }
                .frame(height: 0)

                // Refresh indicator
                if pullProgress > 0 || isRefreshing {
                    AnimatedRefreshIndicator(isRefreshing: isRefreshing, progress: pullProgress)
                        .padding(.vertical, .spacingM)
                        .transition(.opacity.combined(with: .scale))
                }

                content()
            }
        }
        .onPreferenceChange(RefreshProgressKey.self) { value in
            pullProgress = value
        }
    }

    private func triggerRefresh() {
        guard !isRefreshing else { return }

        HapticFeedback.medium.trigger()
        isRefreshing = true

        Task {
            await onRefresh()
            await MainActor.run {
                withAnimation {
                    isRefreshing = false
                }
            }
        }
    }
}

private struct RefreshProgressKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Scroll Velocity Tracking

/// Tracks scroll offset for velocity calculations
struct ScrollOffsetTracker: View {
    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: ScrollVelocityPreferenceKey.self,
                    value: geo.frame(in: .named("scroll")).minY
                )
        }
        .frame(height: 0)
    }
}

/// Preference key for scroll velocity tracking
struct ScrollVelocityPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Observable class to track scroll velocity over time
@MainActor
@Observable
final class ScrollVelocityTracker {
    private var lastOffset: CGFloat = 0
    private var lastUpdateTime: Date = Date()
    private(set) var velocity: CGFloat = 0
    private(set) var blurAmount: CGFloat = 0

    /// Maximum blur radius when scrolling fast
    var maxBlurRadius: CGFloat = 6
    /// Velocity threshold to start applying blur (points per second)
    var blurThreshold: CGFloat = 1500
    /// Velocity at which maximum blur is applied
    var maxVelocityForBlur: CGFloat = 4000

    func updateOffset(_ offset: CGFloat) {
        let now = Date()
        let timeDelta = now.timeIntervalSince(lastUpdateTime)

        guard timeDelta > 0.001 else { return } // Avoid division by zero

        let offsetDelta = abs(offset - lastOffset)
        let newVelocity = offsetDelta / CGFloat(timeDelta)

        // Smooth the velocity using exponential moving average
        velocity = velocity * 0.7 + newVelocity * 0.3

        // Calculate blur based on velocity
        if velocity > blurThreshold {
            let normalizedVelocity = min((velocity - blurThreshold) / (maxVelocityForBlur - blurThreshold), 1)
            blurAmount = normalizedVelocity * maxBlurRadius
        } else {
            blurAmount = 0
        }

        lastOffset = offset
        lastUpdateTime = now
    }

    func resetVelocity() {
        velocity = 0
        blurAmount = 0
    }
}

/// View modifier that applies velocity-based blur during fast scrolling
struct VelocityBlurModifier: ViewModifier {
    let velocity: CGFloat
    let threshold: CGFloat
    let maxBlur: CGFloat

    private var blurAmount: CGFloat {
        guard velocity > threshold else { return 0 }
        let normalizedVelocity = min((velocity - threshold) / (4000 - threshold), 1)
        return normalizedVelocity * maxBlur
    }

    func body(content: Content) -> some View {
        content
            .blur(radius: blurAmount)
            .animation(.easeOut(duration: 0.15), value: blurAmount)
    }
}

extension View {
    /// Applies blur effect based on scroll velocity
    /// - Parameters:
    ///   - velocity: Current scroll velocity (points per second)
    ///   - threshold: Velocity threshold to start blur (default: 1500)
    ///   - maxBlur: Maximum blur radius (default: 6)
    func velocityBlur(velocity: CGFloat, threshold: CGFloat = 1500, maxBlur: CGFloat = 6) -> some View {
        modifier(VelocityBlurModifier(velocity: velocity, threshold: threshold, maxBlur: maxBlur))
    }
}

/// A scroll view that tracks velocity and applies blur during fast scrolling
struct VelocityBlurScrollView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    @State private var velocityTracker = ScrollVelocityTracker()
    @State private var lastOffset: CGFloat = 0
    @State private var scrollStopTimer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ScrollOffsetTracker()

                content()
                    .blur(radius: velocityTracker.blurAmount)
                    .animation(.easeOut(duration: 0.15), value: velocityTracker.blurAmount)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollVelocityPreferenceKey.self) { offset in
            velocityTracker.updateOffset(offset)
            lastOffset = offset

            // Cancel existing timer
            scrollStopTimer?.invalidate()

            // Start new timer to detect scroll stop
            scrollStopTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.3)) {
                        velocityTracker.resetVelocity()
                    }
                }
            }
        }
        .modifier(ScrollPhaseChangeModifier(onIdle: {
            withAnimation(.easeOut(duration: 0.3)) {
                velocityTracker.resetVelocity()
            }
        }))
    }
}

/// Modifier to handle scroll phase changes on iOS 18+
struct ScrollPhaseChangeModifier: ViewModifier {
    let onIdle: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content
                .onScrollPhaseChange { _, newPhase in
                    if case .idle = newPhase {
                        onIdle()
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Share Analytics Tracking

/// Tracks share events for engagement analytics
@MainActor
final class ShareAnalyticsTracker {
    static let shared = ShareAnalyticsTracker()

    private let defaults = UserDefaults.standard
    private let shareCountKey = "share_analytics_count"
    private let shareHistoryKey = "share_analytics_history"

    private init() {}

    /// Total number of shares
    var totalShares: Int {
        defaults.integer(forKey: shareCountKey)
    }

    /// Track a share event
    /// - Parameters:
    ///   - type: Type of content shared (mountain, conditions, event, etc.)
    ///   - itemId: ID of the shared item
    ///   - platform: Optional platform identifier (messages, instagram, etc.)
    func trackShare(type: ShareType, itemId: String, platform: String? = nil) {
        // Increment total count
        let newCount = totalShares + 1
        defaults.set(newCount, forKey: shareCountKey)

        // Add to history
        var history = shareHistory
        let event = ShareEvent(
            id: UUID().uuidString,
            type: type,
            itemId: itemId,
            platform: platform,
            timestamp: Date()
        )
        history.append(event)

        // Keep only last 100 events
        if history.count > 100 {
            history = Array(history.suffix(100))
        }

        if let encoded = try? JSONEncoder().encode(history) {
            defaults.set(encoded, forKey: shareHistoryKey)
        }

        // Notify achievement service
        AchievementService.shared.trackShare()
    }

    /// Get share history
    var shareHistory: [ShareEvent] {
        guard let data = defaults.data(forKey: shareHistoryKey),
              let history = try? JSONDecoder().decode([ShareEvent].self, from: data) else {
            return []
        }
        return history
    }

    /// Get shares by type
    func shareCount(for type: ShareType) -> Int {
        shareHistory.filter { $0.type == type }.count
    }

    /// Get shares in last N days
    func sharesInLastDays(_ days: Int) -> Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return shareHistory.filter { $0.timestamp > cutoff }.count
    }

    enum ShareType: String, Codable {
        case mountain
        case conditions
        case forecast
        case event
        case achievement
        case general
    }

    struct ShareEvent: Codable, Identifiable {
        let id: String
        let type: ShareType
        let itemId: String
        let platform: String?
        let timestamp: Date
    }
}

/// View modifier to track shares
struct ShareTrackingModifier: ViewModifier {
    let type: ShareAnalyticsTracker.ShareType
    let itemId: String

    func body(content: Content) -> some View {
        content.onAppear {
            // Track when share sheet is presented
            ShareAnalyticsTracker.shared.trackShare(type: type, itemId: itemId)
        }
    }
}

extension View {
    /// Track this view being shared
    func trackShare(type: ShareAnalyticsTracker.ShareType, itemId: String) -> some View {
        modifier(ShareTrackingModifier(type: type, itemId: itemId))
    }
}

// MARK: - View Performance Optimizations

extension View {
    /// Prevents unnecessary animations when a value hasn't actually changed
    /// Useful for views with animations that shouldn't re-trigger on parent redraws
    func animateOnlyWhenChanged<Value: Equatable>(_ value: Value, animation: Animation? = .default) -> some View {
        self.animation(animation, value: value)
    }

    /// Conditionally draws based on a visibility flag
    /// More efficient than using if statements in view body
    @ViewBuilder
    func drawIf(_ condition: Bool) -> some View {
        if condition {
            self
        }
    }

    /// Adds a drawing group for views with complex layering
    /// Use for views with many overlapping layers to improve render performance
    func optimizedDrawing() -> some View {
        self.drawingGroup()
    }
}

/// Helper struct for building efficient lists
struct EfficientList<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Identifiable {
    let data: Data
    @ViewBuilder let content: (Data.Element) -> Content

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(data) { item in
                content(item)
            }
        }
    }
}

/// A wrapper that delays view rendering until on-screen
/// Useful for expensive views in long lists
struct LazyRenderView<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var shouldRender = false

    var body: some View {
        Group {
            if shouldRender {
                content()
            } else {
                Color.clear
            }
        }
        .onAppear {
            if !shouldRender {
                shouldRender = true
            }
        }
    }
}

/// View modifier for reducing animation calculations
struct ReduceAnimationComplexityModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .transaction { transaction in
                if reduceMotion {
                    transaction.animation = nil
                }
            }
    }
}

extension View {
    /// Automatically disables animations when Reduce Motion is enabled
    func respectsReduceMotion() -> some View {
        modifier(ReduceAnimationComplexityModifier())
    }

    /// Wraps in a lazy render view for deferred loading
    func lazyRender() -> some View {
        LazyRenderView { self }
    }
}

/// Performance monitoring helper for debug builds
#if DEBUG
struct PerformanceMonitor: View {
    let label: String
    @State private var renderCount = 0

    var body: some View {
        Color.clear
            .onAppear {
                renderCount += 1
                print("[\(label)] Render count: \(renderCount)")
            }
    }
}

extension View {
    /// Adds a performance monitor overlay in debug builds
    func monitorPerformance(_ label: String) -> some View {
        self.background(PerformanceMonitor(label: label))
    }
}
#endif

// MARK: - iPad Adaptive Layout Components

/// Container that constrains content width on iPad for better readability
/// On iPhone, content uses full width. On iPad, content is centered with max-width.
struct AdaptiveContentView<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maxWidth: CGFloat
    let alignment: HorizontalAlignment
    @ViewBuilder let content: () -> Content

    init(
        maxWidth: CGFloat = .maxContentWidthRegular,
        alignment: HorizontalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxWidth = maxWidth
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        if horizontalSizeClass == .regular {
            HStack {
                if alignment == .center || alignment == .trailing {
                    Spacer(minLength: 0)
                }
                content()
                    .frame(maxWidth: maxWidth)
                if alignment == .center || alignment == .leading {
                    Spacer(minLength: 0)
                }
            }
        } else {
            content()
        }
    }
}

/// Adaptive grid that shows more columns on iPad
/// iPhone: 1-2 columns, iPad: 2-4 columns depending on available width
struct AdaptiveGrid<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let minColumnWidth: CGFloat
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(
        minColumnWidth: CGFloat = .gridColumnIdealWidth,
        spacing: CGFloat = .spacingL,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minColumnWidth = minColumnWidth
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: minColumnWidth), spacing: spacing)],
            spacing: spacing
        ) {
            content()
        }
    }
}

/// View modifier that constrains card width on iPad to prevent stretched appearance
struct CardMaxWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maxWidth: CGFloat

    init(maxWidth: CGFloat = .maxContentWidthCompact) {
        self.maxWidth = maxWidth
    }

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
        } else {
            content
        }
    }
}

extension View {
    /// Constrains view width on iPad to prevent stretched appearance
    func cardMaxWidth(_ maxWidth: CGFloat = .maxContentWidthCompact) -> some View {
        modifier(CardMaxWidthModifier(maxWidth: maxWidth))
    }

    /// Wraps content in an adaptive container that centers and constrains width on iPad
    func adaptiveContent(maxWidth: CGFloat = .maxContentWidthRegular) -> some View {
        AdaptiveContentView(maxWidth: maxWidth) { self }
    }
}

/// Navigation section enum for iPad sidebar
enum NavigationSection: String, CaseIterable, Identifiable {
    case today
    case mountains
    case events
    case map
    case profile

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Today"
        case .mountains: return "Mountains"
        case .events: return "Events"
        case .map: return "Map"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .mountains: return "mountain.2.fill"
        case .events: return "calendar"
        case .map: return "map.fill"
        case .profile: return "person.fill"
        }
    }
}
