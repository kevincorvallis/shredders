//
//  ChartStyles.swift
//  PowderTracker
//
//  Reusable chart styling modifiers and view modifiers
//

import SwiftUI
import Charts

// MARK: - Chart Axis Style

/// Modifier for consistent chart axis styling
struct ChartAxisStyleModifier: ViewModifier {
    let showGrid: Bool
    let labelColor: Color
    let gridColor: Color

    init(
        showGrid: Bool = true,
        labelColor: Color = .secondary,
        gridColor: Color = Color(.systemGray5)
    ) {
        self.showGrid = showGrid
        self.labelColor = labelColor
        self.gridColor = gridColor
    }

    func body(content: Content) -> some View {
        content
    }
}

extension View {
    /// Applies consistent chart axis styling
    func chartAxisStyle(
        showGrid: Bool = true,
        labelColor: Color = .secondary,
        gridColor: Color = Color(.systemGray5)
    ) -> some View {
        modifier(ChartAxisStyleModifier(
            showGrid: showGrid,
            labelColor: labelColor,
            gridColor: gridColor
        ))
    }
}

// MARK: - Chart Selection Style

/// Style configuration for chart selection behavior
struct ChartSelectionConfig {
    let indicatorColor: Color
    let indicatorSize: CGFloat
    let showLine: Bool
    let hapticFeedback: HapticFeedback

    static let `default` = ChartSelectionConfig(
        indicatorColor: .blue,
        indicatorSize: .chartSelectionIndicatorSize,
        showLine: true,
        hapticFeedback: .selection
    )

    static let subtle = ChartSelectionConfig(
        indicatorColor: .secondary,
        indicatorSize: 8,
        showLine: false,
        hapticFeedback: .light
    )
}

// MARK: - Chart Selection Indicator

/// Visual indicator for selected data point
struct ChartSelectionIndicator: View {
    let config: ChartSelectionConfig
    let isSelected: Bool

    var body: some View {
        Circle()
            .fill(config.indicatorColor)
            .frame(width: config.indicatorSize, height: config.indicatorSize)
            .shadow(color: config.indicatorColor.opacity(0.4), radius: 4, x: 0, y: 2)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.bouncy, value: isSelected)
    }
}

// MARK: - Chart Animation Presets

/// Animation presets for chart elements
extension Animation {
    /// Entry animation for chart elements appearing
    static let chartEntry = Animation.spring(response: 0.5, dampingFraction: 0.7)

    /// Update animation for data changes
    static let chartUpdate = Animation.easeInOut(duration: 0.3)

    /// Selection animation
    static let chartSelection = Animation.spring(response: 0.25, dampingFraction: 0.8)

    /// Tooltip appearance animation
    static let chartTooltip = Animation.spring(response: 0.3, dampingFraction: 0.75)
}

// MARK: - Chart Container Style

/// Standard chart container with consistent styling
struct ChartContainer<Content: View>: View {
    let title: String?
    let subtitle: String?
    let height: CGFloat
    let showBackground: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let headerAccessory: () -> AnyView

    init(
        title: String? = nil,
        subtitle: String? = nil,
        height: CGFloat = .chartHeightStandard,
        showBackground: Bool = true,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder headerAccessory: @escaping () -> AnyView = { AnyView(EmptyView()) }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.height = height
        self.showBackground = showBackground
        self.content = content
        self.headerAccessory = headerAccessory
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Header
            if title != nil || subtitle != nil {
                HStack {
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        if let title = title {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    headerAccessory()
                }
            }

            // Chart content
            content()
                .frame(height: height)
                .frame(minWidth: 100) // Prevent 0x0 CAMetalLayer error
        }
        .padding(.spacingL)
        .background {
            if showBackground {
                Color(.systemBackground)
                    .cornerRadius(.cornerRadiusHero)
                    .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Chart Loading Skeleton

/// Skeleton loading view for charts
struct ChartSkeleton: View {
    let height: CGFloat

    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Title skeleton
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 120, height: 20)

            // Chart area skeleton
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .fill(Color(.systemGray6))
                    .frame(height: height)

                // Animated shimmer bars
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                            .frame(width: 30, height: CGFloat.random(in: 40...height - 40))
                            .offset(y: CGFloat.random(in: -10...10))
                    }
                }
                .shimmering(active: true)
            }
        }
        .padding(.spacingL)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

// MARK: - Chart Empty State

/// Empty state view for charts with no data
struct ChartEmptyState: View {
    let icon: String
    let title: String
    let message: String?
    let actionLabel: String?
    let action: (() -> Void)?

    init(
        icon: String = "chart.line.uptrend.xyaxis",
        title: String = "No Data Available",
        message: String? = nil,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            VStack(spacing: .spacingXS) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let message = message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let actionLabel = actionLabel, let action = action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingXL)
    }
}

// MARK: - Reference Line

/// A reference line for charts (e.g., average, historical value)
struct ChartReferenceLine: View {
    let value: Double
    let label: String
    let color: Color
    let style: LineStyle

    enum LineStyle {
        case solid
        case dashed
        case dotted

        var strokeStyle: StrokeStyle {
            switch self {
            case .solid:
                return StrokeStyle(lineWidth: 1)
            case .dashed:
                return StrokeStyle(lineWidth: 1, dash: [5, 3])
            case .dotted:
                return StrokeStyle(lineWidth: 1, dash: [2, 2])
            }
        }
    }

    init(
        value: Double,
        label: String = "",
        color: Color = .secondary,
        style: LineStyle = .dashed
    ) {
        self.value = value
        self.label = label
        self.color = color
        self.style = style
    }

    var body: some View {
        // This is a marker - actual rendering handled by Swift Charts RuleMark
        EmptyView()
    }
}

// MARK: - Chart Y-Axis Formatter

/// Formats y-axis values for snow measurements
struct SnowYAxisFormat {
    static func formatInches(_ value: Int) -> String {
        "\(value)\""
    }

    static func formatFeet(_ value: Int) -> String {
        let feet = value / 12
        let inches = value % 12
        if inches == 0 {
            return "\(feet)'"
        }
        return "\(feet)'\(inches)\""
    }
}

// MARK: - Chart X-Axis Formatter

/// Formats x-axis date values
struct DateXAxisFormat {
    static func dayOfWeek(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }

    static func monthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Shimmer Effect Extension

/// Shimmer animation for loading states
struct ShimmerModifier: ViewModifier {
    let active: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if active {
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0),
                                Color.white.opacity(0.3),
                                Color.white.opacity(0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: phase * geo.size.width * 2 - geo.size.width)
                    }
                    .mask(content)
                }
            }
            .onAppear {
                if active {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    /// Applies shimmer effect for loading states
    func shimmering(active: Bool = true) -> some View {
        modifier(ShimmerModifier(active: active))
    }
}
