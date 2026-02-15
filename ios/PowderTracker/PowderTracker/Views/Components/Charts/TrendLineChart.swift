//
//  TrendLineChart.swift
//  PowderTracker
//
//  Line + Area chart with smooth interpolation, gradient fill, and multiple series support
//

import SwiftUI
import Charts

/// Chart display mode
enum ChartDisplayMode: String, CaseIterable {
    case daily = "Daily"
    case cumulative = "Cumulative"
    case depth = "Depth"

    var icon: String {
        switch self {
        case .daily: return "chart.bar"
        case .cumulative: return "chart.line.uptrend.xyaxis"
        case .depth: return "chart.xyaxis.line"
        }
    }
}

/// A trend line chart with area fill, supporting single or multiple series
struct TrendLineChart<Data: Identifiable>: View {
    let data: [Data]
    let xValue: KeyPath<Data, Date>
    let yValue: KeyPath<Data, Double>

    var dataType: ChartDataType
    var displayMode: ChartDisplayMode
    var annotations: AnnotationSet?
    var referenceValue: Double?
    var referenceLabel: String
    var chartHeight: CGFloat
    var lineWidth: CGFloat
    var showArea: Bool
    var showDots: Bool
    var showXAxis: Bool
    var showYAxis: Bool
    var onSelect: ((Data) -> Void)?

    @State private var selectedDate: Date?
    @Environment(\.colorScheme) private var colorScheme

    init(
        data: [Data],
        xValue: KeyPath<Data, Date>,
        yValue: KeyPath<Data, Double>,
        dataType: ChartDataType = .snowDepth,
        displayMode: ChartDisplayMode = .daily,
        annotations: AnnotationSet? = nil,
        referenceValue: Double? = nil,
        referenceLabel: String = "Avg",
        chartHeight: CGFloat = .chartHeightStandard,
        lineWidth: CGFloat = .chartLineWidthMedium,
        showArea: Bool = true,
        showDots: Bool = false,
        showXAxis: Bool = true,
        showYAxis: Bool = true,
        onSelect: ((Data) -> Void)? = nil
    ) {
        self.data = data
        self.xValue = xValue
        self.yValue = yValue
        self.dataType = dataType
        self.displayMode = displayMode
        self.annotations = annotations
        self.referenceValue = referenceValue
        self.referenceLabel = referenceLabel
        self.chartHeight = chartHeight
        self.lineWidth = lineWidth
        self.showArea = showArea
        self.showDots = showDots
        self.showXAxis = showXAxis
        self.showYAxis = showYAxis
        self.onSelect = onSelect
    }

    var body: some View {
        if data.isEmpty {
            ChartEmptyState(
                icon: "chart.line.uptrend.xyaxis",
                title: "No Data",
                message: "Trend data will appear here"
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
            ForEach(processedData) { item in
                let date = item.date
                let value = item.value
                let isPowderDay = annotations?.isPowderDay(date) ?? false

                // Area fill
                if showArea {
                    AreaMark(
                        x: .value("Date", date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(areaGradient(isPowderDay: isPowderDay))
                    .interpolationMethod(.catmullRom)
                }

                // Line
                LineMark(
                    x: .value("Date", date),
                    y: .value("Value", value)
                )
                .foregroundStyle(Color.chartPrimary(for: dataType))
                .lineStyle(StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Dots at data points
                if showDots {
                    PointMark(
                        x: .value("Date", date),
                        y: .value("Value", value)
                    )
                    .foregroundStyle(isPowderDay ? Color.cyan : Color.chartPrimary(for: dataType))
                    .symbolSize(isPowderDay ? 60 : 30)
                }
            }

            // Reference line
            if let refValue = referenceValue {
                RuleMark(y: .value("Reference", refValue))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .center) {
                        Text(referenceLabel)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
                    }
            }

            // Selection line
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxis(showXAxis ? .automatic : .hidden)
        .chartYAxis(showYAxis ? .automatic : .hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: strideCount)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        Text(DateXAxisFormat.shortDate(date))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                if let doubleValue = value.as(Double.self) {
                    AxisGridLine()
                    AxisValueLabel {
                        Text(SnowYAxisFormat.formatInches(Int(doubleValue)))
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
                if let item = findOriginalItem(for: newValue!) {
                    onSelect?(item)
                }
            }
        }
    }

    // MARK: - Data Processing

    private struct ProcessedDataPoint: Identifiable {
        let id: String
        let date: Date
        let value: Double
    }

    private var processedData: [ProcessedDataPoint] {
        switch displayMode {
        case .daily, .depth:
            return data.compactMap { item -> ProcessedDataPoint? in
                let date = item[keyPath: xValue]
                return ProcessedDataPoint(
                    id: "\(date.timeIntervalSince1970)",
                    date: date,
                    value: item[keyPath: yValue]
                )
            }

        case .cumulative:
            var cumulative: Double = 0
            let sorted = data.sorted { $0[keyPath: xValue] < $1[keyPath: xValue] }
            return sorted.compactMap { item -> ProcessedDataPoint? in
                let date = item[keyPath: xValue]
                cumulative += item[keyPath: yValue]
                return ProcessedDataPoint(
                    id: "\(date.timeIntervalSince1970)",
                    date: date,
                    value: cumulative
                )
            }
        }
    }

    private var strideCount: Int {
        let count = data.count
        if count <= 7 { return 1 }
        if count <= 14 { return 2 }
        if count <= 30 { return 5 }
        return 7
    }

    // MARK: - Helpers

    private func areaGradient(isPowderDay: Bool) -> some ShapeStyle {
        if isPowderDay {
            return AnyShapeStyle(LinearGradient.powderDayHighlight)
        }
        return AnyShapeStyle(LinearGradient.chartGradient(for: dataType))
    }

    private func findItem(for date: Date) -> ProcessedDataPoint? {
        processedData.first { item in
            Calendar.current.isDate(item.date, inSameDayAs: date)
        }
    }

    private func findOriginalItem(for date: Date) -> Data? {
        data.first { item in
            Calendar.current.isDate(item[keyPath: xValue], inSameDayAs: date)
        }
    }

    @ViewBuilder
    private func tooltipView(for item: ProcessedDataPoint, at xPosition: CGFloat, in proxy: ChartProxy) -> some View {
        let isPowderDay = annotations?.isPowderDay(item.date) ?? false

        VStack(alignment: .leading, spacing: 4) {
            Text(DateXAxisFormat.monthDay(item.date))
                .font(.caption.bold())
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                if isPowderDay {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
                Text("\(item.value)\"")
                    .font(.headline)
                    .foregroundStyle(Color.chartPrimary(for: dataType))

                if displayMode == .cumulative {
                    Text("total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
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

extension TrendLineChart where Data == HistoryDataPoint {
    /// Convenience initializer for snow depth trend
    init(
        history: [HistoryDataPoint],
        displayMode: ChartDisplayMode = .depth,
        annotations: AnnotationSet? = nil,
        referenceValue: Double? = nil,
        onSelect: ((HistoryDataPoint) -> Void)? = nil
    ) {
        let wrappedData = history.compactMap { point -> HistoryDataPoint? in
            guard point.formattedDate != nil else { return nil }
            return point
        }

        let yPath: KeyPath<HistoryDataPoint, Double> = displayMode == .depth ? \.snowDepth : \.snowfall

        self.init(
            data: wrappedData,
            xValue: \.formattedDate!,
            yValue: yPath,
            dataType: displayMode == .depth ? .snowDepth : .snowfall,
            displayMode: displayMode,
            annotations: annotations,
            referenceValue: referenceValue,
            onSelect: onSelect
        )
    }
}

// MARK: - Mode Switcher

/// Control for switching between chart display modes
struct ChartModeSwitcher: View {
    @Binding var mode: ChartDisplayMode

    var body: some View {
        Picker("Mode", selection: $mode) {
            ForEach(ChartDisplayMode.allCases, id: \.self) { chartMode in
                Label(chartMode.rawValue, systemImage: chartMode.icon)
                    .tag(chartMode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: mode) { _, _ in
            HapticFeedback.selection.trigger()
        }
    }
}

// MARK: - Preview

#Preview("Trend Line Chart") {
    ScrollView {
        VStack(spacing: 20) {
            // Snow depth trend
            ChartContainer(title: "Snow Depth", subtitle: "30 day trend") {
                TrendLineChart(
                    history: HistoryDataPoint.mockHistory(days: 30),
                    displayMode: .depth
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }

            // Cumulative snowfall
            ChartContainer(title: "Cumulative Snowfall", subtitle: "Season total") {
                TrendLineChart(
                    history: HistoryDataPoint.mockHistory(days: 30),
                    displayMode: .cumulative
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }

            // With reference line
            ChartContainer(title: "With Historical Average") {
                TrendLineChart(
                    history: HistoryDataPoint.mockHistory(days: 30),
                    displayMode: .depth,
                    referenceValue: 120
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Mode Switcher") {
    struct PreviewWrapper: View {
        @State private var mode: ChartDisplayMode = .daily

        var body: some View {
            VStack(spacing: 20) {
                ChartModeSwitcher(mode: $mode)
                    .padding(.horizontal)

                Text("Selected: \(mode.rawValue)")
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
