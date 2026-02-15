//
//  ComparisonChart.swift
//  PowderTracker
//
//  Chart for comparing current vs historical, year-over-year, or multiple mountains
//

import SwiftUI
import Charts

/// Types of comparisons supported
enum ComparisonType {
    case currentVsHistorical    // This season vs historical average
    case yearOverYear           // This year vs last year
    case multiMountain          // Multiple mountains overlaid
}

/// Data series for comparison charts
struct ComparisonSeries: Identifiable {
    let id: String
    let name: String
    let color: Color
    let data: [ComparisonDataPoint]
    let isReference: Bool

    init(
        id: String = UUID().uuidString,
        name: String,
        color: Color,
        data: [ComparisonDataPoint],
        isReference: Bool = false
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.data = data
        self.isReference = isReference
    }
}

/// Data point for comparison charts
struct ComparisonDataPoint: Identifiable {
    let id: String
    let date: Date
    let value: Double

    init(date: Date, value: Double) {
        self.id = "\(date.timeIntervalSince1970)"
        self.date = date
        self.value = value
    }
}

/// A comparison chart supporting multiple series overlay
struct ComparisonChart: View {
    let series: [ComparisonSeries]
    let comparisonType: ComparisonType

    var chartHeight: CGFloat
    var showLegend: Bool
    var showArea: Bool
    var showXAxis: Bool
    var showYAxis: Bool
    var onSelect: ((ComparisonSeries, ComparisonDataPoint) -> Void)?

    @State private var selectedDate: Date?
    @Environment(\.colorScheme) private var colorScheme

    init(
        series: [ComparisonSeries],
        comparisonType: ComparisonType = .currentVsHistorical,
        chartHeight: CGFloat = .chartHeightStandard,
        showLegend: Bool = true,
        showArea: Bool = false,
        showXAxis: Bool = true,
        showYAxis: Bool = true,
        onSelect: ((ComparisonSeries, ComparisonDataPoint) -> Void)? = nil
    ) {
        self.series = series
        self.comparisonType = comparisonType
        self.chartHeight = chartHeight
        self.showLegend = showLegend
        self.showArea = showArea
        self.showXAxis = showXAxis
        self.showYAxis = showYAxis
        self.onSelect = onSelect
    }

    var body: some View {
        VStack(spacing: .spacingM) {
            chart
                .frame(height: chartHeight)
                .frame(minWidth: 100)

            if showLegend {
                legendView
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series) { seriesData in
                ForEach(seriesData.data) { point in
                    // Area fill (only for non-reference series)
                    if showArea && !seriesData.isReference {
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(seriesData.color.opacity(0.15))
                        .interpolationMethod(.catmullRom)
                    }

                    // Line
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Value", point.value)
                    )
                    .foregroundStyle(seriesData.color)
                    .lineStyle(StrokeStyle(
                        lineWidth: seriesData.isReference ? .chartLineWidthThin : .chartLineWidthMedium,
                        dash: seriesData.isReference ? [5, 3] : []
                    ))
                    .interpolationMethod(.catmullRom)
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
               let xPosition = proxy.position(forX: selectedDate) {
                tooltipView(for: selectedDate, at: xPosition, in: proxy)
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if newValue != nil && oldValue != newValue {
                HapticFeedback.selection.trigger()
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: .spacingL) {
            ForEach(series) { seriesData in
                HStack(spacing: .spacingXS) {
                    if seriesData.isReference {
                        // Dashed line for reference
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { _ in
                                Rectangle()
                                    .fill(seriesData.color)
                                    .frame(width: 4, height: 2)
                            }
                        }
                        .frame(width: 16)
                    } else {
                        Circle()
                            .fill(seriesData.color)
                            .frame(width: 8, height: 8)
                    }

                    Text(seriesData.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var strideCount: Int {
        let maxCount = series.map { $0.data.count }.max() ?? 7
        if maxCount <= 7 { return 1 }
        if maxCount <= 14 { return 2 }
        if maxCount <= 30 { return 5 }
        return 7
    }

    @ViewBuilder
    private func tooltipView(for date: Date, at xPosition: CGFloat, in proxy: ChartProxy) -> some View {
        let dataForDate = series.compactMap { seriesData -> (series: ComparisonSeries, point: ComparisonDataPoint)? in
            guard let point = seriesData.data.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) else {
                return nil
            }
            return (series: seriesData, point: point)
        }

        if !dataForDate.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(DateXAxisFormat.monthDay(date))
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                ForEach(dataForDate, id: \.series.id) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.series.color)
                            .frame(width: 6, height: 6)

                        Text(item.series.name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(item.point.value)\"")
                            .font(.caption.bold())
                            .foregroundStyle(item.series.color)
                    }
                }

                // Show difference if comparing two series
                if dataForDate.count == 2 {
                    let diff = dataForDate[0].point.value - dataForDate[1].point.value
                    let isPositive = diff >= 0

                    Divider()

                    HStack {
                        Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .foregroundStyle(isPositive ? .green : .red)

                        Text("\(abs(diff))\" \(isPositive ? "above" : "below")")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .frame(minWidth: 140)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .position(
                x: min(max(xPosition, 80), proxy.plotSize.width - 80),
                y: 50
            )
            .animation(.chartTooltip, value: xPosition)
        }
    }
}

// MARK: - Convenience Factory Methods

extension ComparisonChart {
    /// Create a current vs historical average comparison
    static func currentVsHistorical(
        current: [HistoryDataPoint],
        historicalAverage: [HistoryDataPoint],
        metric: KeyPath<HistoryDataPoint, Double> = \.snowDepth
    ) -> ComparisonChart {
        let currentSeries = ComparisonSeries(
            name: "This Season",
            color: Color.chartPrimary(for: .snowDepth),
            data: current.compactMap { point in
                guard let date = point.formattedDate else { return nil }
                return ComparisonDataPoint(date: date, value: point[keyPath: metric])
            }
        )

        let historicalSeries = ComparisonSeries(
            name: "Historical Avg",
            color: .secondary,
            data: historicalAverage.compactMap { point in
                guard let date = point.formattedDate else { return nil }
                return ComparisonDataPoint(date: date, value: point[keyPath: metric])
            },
            isReference: true
        )

        return ComparisonChart(
            series: [currentSeries, historicalSeries],
            comparisonType: .currentVsHistorical,
            showArea: true
        )
    }

    /// Create a year-over-year comparison
    static func yearOverYear(
        thisYear: [HistoryDataPoint],
        lastYear: [HistoryDataPoint],
        metric: KeyPath<HistoryDataPoint, Double> = \.snowDepth
    ) -> ComparisonChart {
        let calendar = Calendar.current

        let thisYearSeries = ComparisonSeries(
            name: "This Year",
            color: Color.chartPrimary(for: .snowDepth),
            data: thisYear.compactMap { point in
                guard let date = point.formattedDate else { return nil }
                return ComparisonDataPoint(date: date, value: point[keyPath: metric])
            }
        )

        // Shift last year's dates to align with this year for comparison
        let lastYearSeries = ComparisonSeries(
            name: "Last Year",
            color: .orange,
            data: lastYear.compactMap { point in
                guard let date = point.formattedDate else { return nil }
                // Shift date forward by 1 year
                let shiftedDate = calendar.date(byAdding: .year, value: 1, to: date) ?? date
                return ComparisonDataPoint(date: shiftedDate, value: point[keyPath: metric])
            },
            isReference: true
        )

        return ComparisonChart(
            series: [thisYearSeries, lastYearSeries],
            comparisonType: .yearOverYear
        )
    }
}

// MARK: - Percentage of Normal Badge

/// Badge showing percentage of normal snowfall
struct PercentOfNormalBadge: View {
    let currentValue: Int
    let normalValue: Int

    private var percentage: Int {
        guard normalValue > 0 else { return 0 }
        return Int(Double(currentValue) / Double(normalValue) * 100)
    }

    private var isAboveNormal: Bool { percentage >= 100 }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isAboveNormal ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
                .foregroundStyle(isAboveNormal ? .green : .orange)

            Text("\(percentage)%")
                .font(.caption.bold())
                .foregroundStyle(isAboveNormal ? .green : .orange)

            Text("of normal")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Comparison Chart") {
    ScrollView {
        VStack(spacing: 20) {
            // Current vs Historical
            ChartContainer(title: "Current vs Historical", subtitle: "Snow depth comparison") {
                ComparisonChart.currentVsHistorical(
                    current: HistoryDataPoint.mockHistory(days: 30),
                    historicalAverage: HistoryDataPoint.mockHistory(days: 30)
                )
            } headerAccessory: {
                AnyView(PercentOfNormalBadge(currentValue: 145, normalValue: 120))
            }

            // Year over Year
            ChartContainer(title: "Year over Year") {
                ComparisonChart.yearOverYear(
                    thisYear: HistoryDataPoint.mockHistory(days: 30),
                    lastYear: HistoryDataPoint.mockHistory(days: 30)
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }

            // Custom multi-series
            ChartContainer(title: "Multi-Mountain Comparison") {
                ComparisonChart(
                    series: [
                        ComparisonSeries(
                            name: "Crystal",
                            color: .blue,
                            data: (0..<14).map { i in
                                ComparisonDataPoint(
                                    date: Calendar.current.date(byAdding: .day, value: -13 + i, to: Date())!,
                                    value: Double.random(in: 100...160)
                                )
                            }
                        ),
                        ComparisonSeries(
                            name: "Stevens",
                            color: .green,
                            data: (0..<14).map { i in
                                ComparisonDataPoint(
                                    date: Calendar.current.date(byAdding: .day, value: -13 + i, to: Date())!,
                                    value: Double.random(in: 80...140)
                                )
                            }
                        ),
                        ComparisonSeries(
                            name: "Baker",
                            color: .purple,
                            data: (0..<14).map { i in
                                ComparisonDataPoint(
                                    date: Calendar.current.date(byAdding: .day, value: -13 + i, to: Date())!,
                                    value: Double.random(in: 120...180)
                                )
                            }
                        )
                    ],
                    comparisonType: .multiMountain
                )
            } headerAccessory: {
                AnyView(EmptyView())
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
