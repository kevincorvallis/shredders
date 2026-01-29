//
//  InteractiveBarChart.swift
//  PowderTracker
//
//  Generic interactive bar chart with tap-to-select, annotations, and reference lines
//

import SwiftUI
import Charts

/// A generic interactive bar chart component
/// Supports tap-to-select, haptic feedback, reference lines, and powder day annotations
struct InteractiveBarChart<Data: Identifiable>: View {
    let data: [Data]
    let xValue: KeyPath<Data, Date>
    let yValue: KeyPath<Data, Int>

    var dataType: ChartDataType
    var referenceValue: Double?
    var referenceLabel: String
    var annotations: AnnotationSet?
    var chartHeight: CGFloat
    var barWidth: CGFloat
    var showXAxis: Bool
    var showYAxis: Bool
    var onSelect: ((Data) -> Void)?

    @State private var selectedDate: Date?
    @State private var selectedData: Data?
    @Environment(\.colorScheme) private var colorScheme

    init(
        data: [Data],
        xValue: KeyPath<Data, Date>,
        yValue: KeyPath<Data, Int>,
        dataType: ChartDataType = .snowfall,
        referenceValue: Double? = nil,
        referenceLabel: String = "Avg",
        annotations: AnnotationSet? = nil,
        chartHeight: CGFloat = .chartHeightStandard,
        barWidth: CGFloat = 20,
        showXAxis: Bool = true,
        showYAxis: Bool = true,
        onSelect: ((Data) -> Void)? = nil
    ) {
        self.data = data
        self.xValue = xValue
        self.yValue = yValue
        self.dataType = dataType
        self.referenceValue = referenceValue
        self.referenceLabel = referenceLabel
        self.annotations = annotations
        self.chartHeight = chartHeight
        self.barWidth = barWidth
        self.showXAxis = showXAxis
        self.showYAxis = showYAxis
        self.onSelect = onSelect
    }

    var body: some View {
        if data.isEmpty {
            ChartEmptyState(
                icon: "chart.bar.xaxis",
                title: "No Data",
                message: "Check back after some snowfall"
            )
            .frame(height: chartHeight)
        } else {
            chart
                .frame(height: chartHeight)
                .frame(minWidth: 100)
        }
    }

    private var chart: some View {
        Chart {
            // Data bars
            ForEach(data) { item in
                let date = item[keyPath: xValue]
                let value = item[keyPath: yValue]
                let isPowderDay = annotations?.isPowderDay(date) ?? false
                let isEpicDay = annotations?.isEpicPowderDay(date) ?? false
                let isSelected = selectedDate != nil && Calendar.current.isDate(date, inSameDayAs: selectedDate!)

                BarMark(
                    x: .value("Date", date),
                    y: .value("Value", value),
                    width: .fixed(barWidth)
                )
                .foregroundStyle(barColor(isPowderDay: isPowderDay, isEpicDay: isEpicDay, isSelected: isSelected))
                .cornerRadius(.cornerRadiusTiny)
                .annotation(position: .top, spacing: 4) {
                    if isPowderDay {
                        PowderDayBadge(snowfall: annotations?.snowfallForPowderDay(date) ?? value, compact: true)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }

            // Reference line
            if let refValue = referenceValue {
                RuleMark(y: .value("Reference", refValue))
                    .foregroundStyle(Color.secondary.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .center) {
                        Text(referenceLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)
                    }
            }

            // Selection indicator
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxis(showXAxis ? .automatic : .hidden)
        .chartYAxis(showYAxis ? .automatic : .hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(DateXAxisFormat.dayOfWeek(date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let intValue = value.as(Int.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        Text(SnowYAxisFormat.formatInches(intValue))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            if let selectedDate = selectedDate,
               let selectedItem = findItem(for: selectedDate),
               let xPosition = proxy.position(forX: selectedDate) {
                tooltipView(for: selectedItem, at: xPosition, in: proxy)
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if newValue != nil && oldValue != newValue {
                HapticFeedback.selection.trigger()
                if let item = findItem(for: newValue!) {
                    onSelect?(item)
                }
            }
        }
    }

    // MARK: - Helpers

    private func barColor(isPowderDay: Bool, isEpicDay: Bool, isSelected: Bool) -> some ShapeStyle {
        if isEpicDay {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color.cyan, Color.blue],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        } else if isPowderDay {
            return AnyShapeStyle(Color.chartPrimary(for: dataType).opacity(0.9))
        } else if isSelected {
            return AnyShapeStyle(Color.chartPrimary(for: dataType))
        } else {
            return AnyShapeStyle(Color.chartPrimary(for: dataType).opacity(0.6))
        }
    }

    private func findItem(for date: Date) -> Data? {
        data.first { item in
            Calendar.current.isDate(item[keyPath: xValue], inSameDayAs: date)
        }
    }

    @ViewBuilder
    private func tooltipView(for item: Data, at xPosition: CGFloat, in proxy: ChartProxy) -> some View {
        let value = item[keyPath: yValue]
        let date = item[keyPath: xValue]
        let isPowderDay = annotations?.isPowderDay(date) ?? false

        VStack(alignment: .leading, spacing: 4) {
            Text(DateXAxisFormat.monthDay(date))
                .font(.caption.bold())
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                if isPowderDay {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
                Text("\(value)\"")
                    .font(.headline)
                    .foregroundStyle(Color.chartPrimary(for: dataType))
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        .position(
            x: min(max(xPosition, 50), proxy.plotSize.width - 50),
            y: 30
        )
        .animation(.chartTooltip, value: xPosition)
    }
}

// MARK: - Convenience Initializers

extension InteractiveBarChart where Data == HistoryDataPoint {
    /// Convenience initializer for HistoryDataPoint data
    init(
        history: [HistoryDataPoint],
        showSnowfall: Bool = true,
        referenceValue: Double? = nil,
        annotations: AnnotationSet? = nil,
        onSelect: ((HistoryDataPoint) -> Void)? = nil
    ) {
        // Create a stable wrapper that uses the date as the key
        let wrappedData = history.compactMap { point -> HistoryDataPoint? in
            guard point.formattedDate != nil else { return nil }
            return point
        }

        self.init(
            data: wrappedData,
            xValue: \.formattedDate!,
            yValue: showSnowfall ? \.snowfall : \.snowDepth,
            dataType: showSnowfall ? .snowfall : .snowDepth,
            referenceValue: referenceValue,
            referenceLabel: "Avg",
            annotations: annotations,
            onSelect: onSelect
        )
    }
}

// MARK: - Preview

#Preview("Interactive Bar Chart") {
    ScrollView {
        VStack(spacing: 20) {
            // Basic chart
            ChartContainer(title: "Daily Snowfall", subtitle: "Last 7 days") {
                InteractiveBarChart(
                    history: Array(HistoryDataPoint.mockHistory(days: 7)),
                    showSnowfall: true
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }

            // With reference line
            ChartContainer(title: "With Average Line") {
                InteractiveBarChart(
                    history: Array(HistoryDataPoint.mockHistory(days: 14)),
                    showSnowfall: true,
                    referenceValue: 4
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }

            // With annotations
            let history = HistoryDataPoint.mockHistory(days: 14)
            let annotations = AnnotationDetector.detectAllAnnotations(from: history)
            ChartContainer(title: "With Powder Day Annotations") {
                InteractiveBarChart(
                    history: history,
                    showSnowfall: true,
                    annotations: annotations
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
