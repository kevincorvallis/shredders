//
//  ChartTooltip.swift
//  PowderTracker
//
//  Reusable tooltip component for charts with glassmorphic background and configurable content
//

import SwiftUI

/// Style configuration for chart tooltips
struct ChartTooltipStyle {
    let backgroundColor: Material
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let padding: EdgeInsets

    static let `default` = ChartTooltipStyle(
        backgroundColor: .ultraThinMaterial,
        cornerRadius: 10,
        shadowRadius: 8,
        shadowOpacity: 0.15,
        padding: EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
    )

    static let compact = ChartTooltipStyle(
        backgroundColor: .ultraThinMaterial,
        cornerRadius: 8,
        shadowRadius: 4,
        shadowOpacity: 0.1,
        padding: EdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
    )

    static let prominent = ChartTooltipStyle(
        backgroundColor: .regularMaterial,
        cornerRadius: 12,
        shadowRadius: 12,
        shadowOpacity: 0.2,
        padding: EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
    )
}

/// A reusable tooltip component for charts
struct ChartTooltip<Content: View>: View {
    let style: ChartTooltipStyle
    @ViewBuilder let content: () -> Content

    @State private var isVisible = false

    init(
        style: ChartTooltipStyle = .default,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.content = content
    }

    var body: some View {
        content()
            .padding(style.padding)
            .background(style.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
            .shadow(color: .black.opacity(style.shadowOpacity), radius: style.shadowRadius, x: 0, y: 4)
            .scaleEffect(isVisible ? 1.0 : 0.9)
            .opacity(isVisible ? 1.0 : 0)
            .onAppear {
                withAnimation(.chartTooltip) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Preset Tooltip Layouts

/// Tooltip for displaying a single value with label
struct SingleValueTooltip: View {
    let label: String
    let value: String
    let valueColor: Color
    let icon: String?

    init(
        label: String,
        value: String,
        valueColor: Color = .primary,
        icon: String? = nil
    ) {
        self.label = label
        self.value = value
        self.valueColor = valueColor
        self.icon = icon
    }

    var body: some View {
        ChartTooltip {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(valueColor)
                    }

                    Text(value)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(valueColor)
                }
            }
        }
    }
}

/// Tooltip for displaying date and value
struct DateValueTooltip: View {
    let date: Date
    let value: Int
    let unit: String
    let dataType: ChartDataType
    let isPowderDay: Bool

    init(
        date: Date,
        value: Int,
        unit: String = "\"",
        dataType: ChartDataType = .snowfall,
        isPowderDay: Bool = false
    ) {
        self.date = date
        self.value = value
        self.unit = unit
        self.dataType = dataType
        self.isPowderDay = isPowderDay
    }

    var body: some View {
        ChartTooltip {
            VStack(alignment: .leading, spacing: 6) {
                // Date header
                Text(formatDate(date))
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                // Value with optional powder day indicator
                HStack(spacing: 6) {
                    if isPowderDay {
                        Image(systemName: "snowflake")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                    }

                    Text("\(value)\(unit)")
                        .font(.title3.bold())
                        .foregroundStyle(Color.chartPrimary(for: dataType))
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
}

/// Tooltip for displaying multiple values
struct MultiValueTooltip: View {
    let title: String
    let values: [(label: String, value: String, color: Color)]

    var body: some View {
        ChartTooltip(style: .prominent) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(item.color)
                            .frame(width: 6, height: 6)

                        Text(item.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text(item.value)
                            .font(.caption.bold())
                            .foregroundStyle(item.color)
                    }
                }
            }
            .frame(minWidth: 120)
        }
    }
}

/// Tooltip for snow forecast data
struct ForecastTooltip: View {
    let date: Date
    let snowfall: Int
    let highTemp: Int
    let lowTemp: Int
    let conditions: String

    var body: some View {
        ChartTooltip(style: .prominent) {
            VStack(alignment: .leading, spacing: 8) {
                // Date header
                Text(formatDate(date))
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)

                // Main stats
                HStack(spacing: 16) {
                    // Snowfall
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .font(.caption2)
                                .foregroundStyle(.cyan)
                            Text("\(snowfall)\"")
                                .font(.headline.bold())
                                .foregroundStyle(.cyan)
                        }
                        Text("Snow")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Temperature
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Image(systemName: "thermometer.medium")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                            Text("\(highTemp)°/\(lowTemp)°")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                        }
                        Text("Hi/Lo")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Conditions
                if !conditions.isEmpty {
                    Text(conditions)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

/// Tooltip for historical comparison
struct ComparisonTooltip: View {
    let date: Date
    let currentValue: Int
    let comparisonValue: Int
    let comparisonLabel: String
    let unit: String

    private var difference: Int { currentValue - comparisonValue }
    private var isAbove: Bool { difference >= 0 }

    var body: some View {
        ChartTooltip(style: .prominent) {
            VStack(alignment: .leading, spacing: 8) {
                // Date header
                Text(formatDate(date))
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                // Current value
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.chartPrimary(for: .snowDepth))
                        .frame(width: 6, height: 6)

                    Text("Current")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(currentValue)\(unit)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.chartPrimary(for: .snowDepth))
                }

                // Comparison value
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.secondary)
                                .frame(width: 2, height: 2)
                        }
                    }
                    .frame(width: 6)

                    Text(comparisonLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(comparisonValue)\(unit)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Difference
                HStack(spacing: 4) {
                    Image(systemName: isAbove ? "arrow.up" : "arrow.down")
                        .font(.caption2.bold())
                        .foregroundStyle(isAbove ? .green : .orange)

                    Text("\(abs(difference))\(unit) \(isAbove ? "above" : "below")")
                        .font(.caption.bold())
                        .foregroundStyle(isAbove ? .green : .orange)
                }
            }
            .frame(minWidth: 130)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Tooltip Positioning Helper

/// Helper for positioning tooltips within chart bounds
struct TooltipPositioner {
    let plotSize: CGSize
    let tooltipWidth: CGFloat
    let tooltipHeight: CGFloat
    let padding: CGFloat

    init(
        plotSize: CGSize,
        tooltipWidth: CGFloat = 140,
        tooltipHeight: CGFloat = 80,
        padding: CGFloat = 16
    ) {
        self.plotSize = plotSize
        self.tooltipWidth = tooltipWidth
        self.tooltipHeight = tooltipHeight
        self.padding = padding
    }

    /// Calculate X position keeping tooltip within bounds
    func xPosition(for dataX: CGFloat) -> CGFloat {
        let halfWidth = tooltipWidth / 2
        let minX = halfWidth + padding
        let maxX = plotSize.width - halfWidth - padding
        return min(max(dataX, minX), maxX)
    }

    /// Calculate Y position keeping tooltip within bounds
    func yPosition(above dataY: CGFloat) -> CGFloat {
        let preferredY = dataY - tooltipHeight - padding
        let minY = tooltipHeight / 2 + padding
        return max(preferredY, minY)
    }
}

// MARK: - Previews

#Preview("Tooltip Styles") {
    VStack(spacing: 20) {
        SingleValueTooltip(
            label: "Fresh Snow",
            value: "8\"",
            valueColor: .cyan,
            icon: "snowflake"
        )

        DateValueTooltip(
            date: Date(),
            value: 12,
            dataType: .snowfall,
            isPowderDay: true
        )

        MultiValueTooltip(
            title: "Jan 15",
            values: [
                ("Crystal", "8\"", .blue),
                ("Stevens", "6\"", .green),
                ("Baker", "10\"", .purple)
            ]
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Forecast Tooltip") {
    ForecastTooltip(
        date: Date(),
        snowfall: 8,
        highTemp: 28,
        lowTemp: 18,
        conditions: "Heavy snow expected throughout the day"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Comparison Tooltip") {
    ComparisonTooltip(
        date: Date(),
        currentValue: 145,
        comparisonValue: 120,
        comparisonLabel: "Historical",
        unit: "\""
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
