import SwiftUI
import Charts

/// Enhanced snow depth chart with trend visualization, tap-to-select, and powder day annotations
struct SnowDepthChart: View {
    let history: [HistoryDataPoint]
    var title: String = "Snow Depth"
    var showPowderDayAnnotations: Bool = true
    var referenceValue: Double? = nil
    var chartHeight: CGFloat = .chartHeightStandard
    var onSelect: ((HistoryDataPoint) -> Void)? = nil

    @State private var displayMode: ChartDisplayMode = .depth
    @State private var selectedDate: Date?

    // Computed annotations
    private var annotations: AnnotationSet? {
        showPowderDayAnnotations ? AnnotationDetector.detectAllAnnotations(from: history) : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Header with mode toggle
            headerView

            if history.isEmpty {
                emptyState
            } else {
                chartContent
            }
        }
        .padding(.spacingL)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                if let period = periodText {
                    Text(period)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Mode toggle (compact)
            Picker("Mode", selection: $displayMode) {
                ForEach([ChartDisplayMode.depth, .cumulative], id: \.self) { mode in
                    Image(systemName: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .onChange(of: displayMode) { _, _ in
                HapticFeedback.selection.trigger()
            }
        }
    }

    private var periodText: String? {
        guard history.count > 1 else { return nil }
        return "\(history.count) days"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ChartEmptyState(
            icon: "chart.xyaxis.line",
            title: "No Data Available",
            message: "Snow depth data will appear here"
        )
        .frame(height: chartHeight)
    }

    // MARK: - Chart Content

    private var chartContent: some View {
        Group {
            switch displayMode {
            case .depth, .daily:
                trendLineChart

            case .cumulative:
                cumulativeChart
            }
        }
        .frame(height: chartHeight)
        .frame(minWidth: 100)
    }

    private var trendLineChart: some View {
        Chart {
            ForEach(validHistory) { point in
                let date = point.formattedDate!
                let isPowderDay = annotations?.isPowderDay(date) ?? false

                // Area fill
                AreaMark(
                    x: .value("Date", date),
                    y: .value("Depth", point.snowDepth)
                )
                .foregroundStyle(
                    isPowderDay
                        ? AnyShapeStyle(LinearGradient.powderDayHighlight)
                        : AnyShapeStyle(LinearGradient.chartGradient(for: .snowDepth))
                )
                .interpolationMethod(.catmullRom)

                // Line
                LineMark(
                    x: .value("Date", date),
                    y: .value("Depth", point.snowDepth)
                )
                .foregroundStyle(Color.chartPrimary(for: .snowDepth))
                .lineStyle(StrokeStyle(lineWidth: .chartLineWidthMedium, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)

                // Powder day markers
                if isPowderDay {
                    PointMark(
                        x: .value("Date", date),
                        y: .value("Depth", point.snowDepth)
                    )
                    .foregroundStyle(Color.cyan)
                    .symbolSize(40)
                    .annotation(position: .top, spacing: 4) {
                        if point.snowfall >= 6 {
                            PowderDayBadge(snowfall: point.snowfall, compact: true)
                        }
                    }
                }
            }

            // Reference line
            if let refValue = referenceValue {
                RuleMark(y: .value("Reference", refValue))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                    .annotation(position: .trailing, alignment: .center) {
                        Text("Avg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
            }

            // Selection line
            if let selectedDate = selectedDate {
                RuleMark(x: .value("Selected", selectedDate))
                    .foregroundStyle(Color.primary.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let depth = value.as(Int.self) {
                        Text(SnowYAxisFormat.formatInches(depth))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
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
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            if let selectedDate = selectedDate,
               let point = findPoint(for: selectedDate),
               let xPosition = proxy.position(forX: selectedDate) {
                tooltipView(for: point, at: xPosition, in: proxy)
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            if newValue != nil && oldValue != newValue {
                HapticFeedback.selection.trigger()
                if let point = findPoint(for: newValue!) {
                    onSelect?(point)
                }
            }
        }
    }

    private var cumulativeChart: some View {
        let cumulativeData = computeCumulativeData()

        return Chart(cumulativeData, id: \.date) { item in
            // Area fill
            AreaMark(
                x: .value("Date", item.date),
                y: .value("Cumulative", item.cumulative)
            )
            .foregroundStyle(LinearGradient.chartGradient(for: .cumulative))
            .interpolationMethod(.catmullRom)

            // Line
            LineMark(
                x: .value("Date", item.date),
                y: .value("Cumulative", item.cumulative)
            )
            .foregroundStyle(Color.chartPrimary(for: .cumulative))
            .lineStyle(StrokeStyle(lineWidth: .chartLineWidthMedium, lineCap: .round, lineJoin: .round))
            .interpolationMethod(.catmullRom)

            // Milestone markers
            if let annotations = annotations {
                ForEach(annotations.milestones) { milestone in
                    if Calendar.current.isDate(item.date, inSameDayAs: milestone.date) {
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Cumulative", item.cumulative)
                        )
                        .foregroundStyle(Color.indigo)
                        .symbolSize(60)
                        .annotation(position: .top, spacing: 4) {
                            milestone.annotationView()
                        }
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let total = value.as(Int.self) {
                        Text(SnowYAxisFormat.formatInches(total))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
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
        .chartXSelection(value: $selectedDate)
    }

    // MARK: - Helpers

    private var validHistory: [HistoryDataPoint] {
        history.filter { $0.formattedDate != nil }
    }

    private var strideCount: Int {
        let count = history.count
        if count <= 7 { return 1 }
        if count <= 14 { return 2 }
        if count <= 30 { return 5 }
        return 7
    }

    private func findPoint(for date: Date) -> HistoryDataPoint? {
        validHistory.first { point in
            guard let pointDate = point.formattedDate else { return false }
            return Calendar.current.isDate(pointDate, inSameDayAs: date)
        }
    }

    private struct CumulativeDataPoint {
        let date: Date
        let cumulative: Int
    }

    private func computeCumulativeData() -> [CumulativeDataPoint] {
        var cumulative = 0
        let sorted = validHistory.sorted { ($0.formattedDate ?? .distantPast) < ($1.formattedDate ?? .distantPast) }

        return sorted.compactMap { point -> CumulativeDataPoint? in
            guard let date = point.formattedDate else { return nil }
            cumulative += point.snowfall
            return CumulativeDataPoint(date: date, cumulative: cumulative)
        }
    }

    @ViewBuilder
    private func tooltipView(for point: HistoryDataPoint, at xPosition: CGFloat, in proxy: ChartProxy) -> some View {
        let isPowderDay = annotations?.isPowderDay(point.formattedDate ?? Date()) ?? false

        VStack(alignment: .leading, spacing: 6) {
            if let date = point.formattedDate {
                Text(DateXAxisFormat.monthDay(date))
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }

            // Snow depth
            HStack(spacing: 6) {
                if isPowderDay {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
                Text("\(point.snowDepth)\"")
                    .font(.headline.bold())
                    .foregroundStyle(Color.chartPrimary(for: .snowDepth))

                Text("depth")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Fresh snow if any
            if point.snowfall > 0 {
                HStack(spacing: 4) {
                    Text("+\(point.snowfall)\"")
                        .font(.caption.bold())
                        .foregroundStyle(.cyan)
                    Text("fresh")
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
            x: min(max(xPosition, 60), proxy.plotSize.width - 60),
            y: 40
        )
        .animation(.chartTooltip, value: xPosition)
    }
}

// MARK: - Preview

#Preview("Snow Depth Chart") {
    ScrollView {
        VStack(spacing: 20) {
            SnowDepthChart(history: HistoryDataPoint.mockHistory(days: 30))

            SnowDepthChart(
                history: HistoryDataPoint.mockHistory(days: 14),
                title: "14-Day Trend",
                referenceValue: 120
            )

            SnowDepthChart(history: [])
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
