//
//  ChartDetailView.swift
//  PowderTracker
//
//  Interactive fullscreen chart detail view with customization options
//  Presents when user taps on a chart for deeper exploration
//

import SwiftUI
import Charts

/// Chart data point for visualization
struct ChartDataPoint: Identifiable {
    let id: Int
    let dayOfWeek: String
    let value: Double
    let snowfall: Int
    let high: Int
    let low: Int
    let windSpeed: Int
    let windGust: Int
    let precipProbability: Int
}

/// Immersive chart detail view with advanced customization and analysis
struct ChartDetailView: View {
    let mountain: Mountain
    let forecast: [ForecastDay]
    @Binding var isPresented: Bool

    // Customization state
    @State private var selectedChartType: ChartType = .area
    @State private var selectedDataMetric: DataMetric = .snowfall
    @State private var selectedTimeRange: TimeRange = .sevenDays
    @State private var showTrendLine: Bool = true
    @State private var showAnnotations: Bool = true
    @State private var selectedDayIndex: Int? = nil
    @State private var showInsights: Bool = true

    // Animation states
    @State private var chartAppeared: Bool = false
    @State private var controlsAppeared: Bool = false
    @State private var insightsAppeared: Bool = false

    // Thresholds
    private let powderDayThreshold = 6
    private let epicPowderThreshold = 12

    enum ChartType: String, CaseIterable {
        case area = "Area"
        case line = "Line"
        case bar = "Bar"

        var icon: String {
            switch self {
            case .area: return "chart.xyaxis.line"
            case .line: return "chart.line.uptrend.xyaxis"
            case .bar: return "chart.bar.fill"
            }
        }
    }

    enum DataMetric: String, CaseIterable {
        case snowfall = "Snowfall"
        case temperature = "Temperature"
        case wind = "Wind"
        case precipitation = "Precip %"

        var icon: String {
            switch self {
            case .snowfall: return "snowflake"
            case .temperature: return "thermometer.medium"
            case .wind: return "wind"
            case .precipitation: return "cloud.rain"
            }
        }

        var unit: String {
            switch self {
            case .snowfall: return "\""
            case .temperature: return "°F"
            case .wind: return "mph"
            case .precipitation: return "%"
            }
        }

        var color: Color {
            switch self {
            case .snowfall: return .blue
            case .temperature: return .orange
            case .wind: return .teal
            case .precipitation: return .indigo
            }
        }
    }

    enum TimeRange: String, CaseIterable {
        case threeDays = "3D"
        case sevenDays = "7D"
        case fourteenDays = "14D"

        var days: Int {
            switch self {
            case .threeDays: return 3
            case .sevenDays: return 7
            case .fourteenDays: return 14
            }
        }
    }

    // MARK: - Computed Properties

    private var filteredForecast: [ForecastDay] {
        Array(forecast.prefix(selectedTimeRange.days))
    }

    private var chartData: [ChartDataPoint] {
        filteredForecast.enumerated().map { index, day in
            ChartDataPoint(
                id: index,
                dayOfWeek: day.dayOfWeek,
                value: getValue(for: day),
                snowfall: day.snowfall,
                high: day.high,
                low: day.low,
                windSpeed: day.wind.speed,
                windGust: day.wind.gust,
                precipProbability: day.precipProbability
            )
        }
    }

    private func getValue(for day: ForecastDay) -> Double {
        switch selectedDataMetric {
        case .snowfall: return Double(day.snowfall)
        case .temperature: return Double(day.high)
        case .wind: return Double(day.wind.speed)
        case .precipitation: return Double(day.precipProbability)
        }
    }

    private var totalSnowfall: Int {
        filteredForecast.reduce(0) { $0 + $1.snowfall }
    }

    private var powderDays: Int {
        filteredForecast.filter { $0.snowfall >= powderDayThreshold }.count
    }

    private var epicDays: Int {
        filteredForecast.filter { $0.snowfall >= epicPowderThreshold }.count
    }

    private var avgTemperature: Int {
        guard !filteredForecast.isEmpty else { return 0 }
        let total = filteredForecast.reduce(0) { $0 + $1.high }
        return total / filteredForecast.count
    }

    private var insights: [Insight] {
        var results: [Insight] = []

        // Best powder day
        if let bestDay = filteredForecast.max(by: { $0.snowfall < $1.snowfall }), bestDay.snowfall >= powderDayThreshold {
            results.append(Insight(
                icon: "star.fill",
                title: "Best Day",
                description: "\(bestDay.dayOfWeek) with \(bestDay.snowfall)\" expected",
                color: .yellow
            ))
        }

        // Storm incoming
        if let firstBigDay = filteredForecast.first(where: { $0.snowfall >= 8 }) {
            results.append(Insight(
                icon: "cloud.snow.fill",
                title: "Storm Alert",
                description: "\(firstBigDay.snowfall)\" coming \(firstBigDay.dayOfWeek)",
                color: .blue
            ))
        }

        // Wind advisory
        if let windyDay = filteredForecast.first(where: { $0.wind.gust >= 30 }) {
            results.append(Insight(
                icon: "wind",
                title: "Wind Advisory",
                description: "Gusts to \(windyDay.wind.gust)mph on \(windyDay.dayOfWeek)",
                color: .teal
            ))
        }

        // Powder streak
        let consecutivePowderDays = countConsecutivePowderDays()
        if consecutivePowderDays >= 2 {
            results.append(Insight(
                icon: "flame.fill",
                title: "Powder Streak",
                description: "\(consecutivePowderDays) consecutive powder days!",
                color: .orange
            ))
        }

        return results
    }

    private func countConsecutivePowderDays() -> Int {
        var maxStreak = 0
        var currentStreak = 0
        for day in filteredForecast {
            if day.snowfall >= powderDayThreshold {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }

    struct Insight: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let color: Color
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero chart section
                    heroChartSection
                        .padding(.horizontal)
                        .padding(.top)

                    // Quick stats
                    quickStatsBar
                        .padding(.top, 16)

                    // Chart type selector
                    chartTypeSelector
                        .padding(.top, 20)
                        .opacity(controlsAppeared ? 1 : 0)
                        .offset(y: controlsAppeared ? 0 : 20)

                    // Data metric selector
                    dataMetricSelector
                        .padding(.top, 16)
                        .opacity(controlsAppeared ? 1 : 0)
                        .offset(y: controlsAppeared ? 0 : 20)

                    // Time range selector
                    timeRangeSelector
                        .padding(.top, 16)
                        .padding(.horizontal)
                        .opacity(controlsAppeared ? 1 : 0)
                        .offset(y: controlsAppeared ? 0 : 20)

                    // Display options
                    displayOptionsSection
                        .padding(.top, 20)
                        .padding(.horizontal)
                        .opacity(controlsAppeared ? 1 : 0)

                    // AI Insights
                    if showInsights && !insights.isEmpty {
                        insightsSection
                            .padding(.top, 24)
                            .opacity(insightsAppeared ? 1 : 0)
                            .offset(y: insightsAppeared ? 0 : 30)
                    }

                    // Day-by-day breakdown
                    dayByDaySection
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(mountain.shortName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: { resetToDefaults() }) {
                            Label("Reset Settings", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                chartAppeared = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    controlsAppeared = true
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    insightsAppeared = true
                }
            }
        }
    }

    // MARK: - Hero Chart Section

    private var heroChartSection: some View {
        VStack(spacing: 0) {
            ZStack {
                // Background gradient
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                selectedDataMetric.color.opacity(0.15),
                                selectedDataMetric.color.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // Chart
                mainChart
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
            }
            .frame(height: 280)
            .scaleEffect(chartAppeared ? 1 : 0.95)
            .opacity(chartAppeared ? 1 : 0)
        }
    }

    @ViewBuilder
    private var mainChart: some View {
        Chart(chartData) { item in
            switch selectedChartType {
            case .area:
                AreaMark(
                    x: .value("Day", item.dayOfWeek),
                    y: .value(selectedDataMetric.rawValue, item.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [selectedDataMetric.color.opacity(0.6), selectedDataMetric.color.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                if showTrendLine {
                    LineMark(
                        x: .value("Day", item.dayOfWeek),
                        y: .value(selectedDataMetric.rawValue, item.value)
                    )
                    .foregroundStyle(selectedDataMetric.color)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                }

            case .line:
                LineMark(
                    x: .value("Day", item.dayOfWeek),
                    y: .value(selectedDataMetric.rawValue, item.value)
                )
                .foregroundStyle(selectedDataMetric.color)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Day", item.dayOfWeek),
                    y: .value(selectedDataMetric.rawValue, item.value)
                )
                .foregroundStyle(selectedDataMetric.color)
                .symbolSize(selectedDayIndex == item.id ? 150 : 80)

            case .bar:
                BarMark(
                    x: .value("Day", item.dayOfWeek),
                    y: .value(selectedDataMetric.rawValue, item.value)
                )
                .foregroundStyle(
                    item.snowfall >= epicPowderThreshold ? Color.purple :
                    item.snowfall >= powderDayThreshold ? Color.blue :
                    selectedDataMetric.color.opacity(0.7)
                )
                .cornerRadius(6)
            }

            // Powder day annotations
            if showAnnotations && selectedDataMetric == .snowfall && item.snowfall >= powderDayThreshold {
                PointMark(
                    x: .value("Day", item.dayOfWeek),
                    y: .value(selectedDataMetric.rawValue, item.value)
                )
                .annotation(position: .top, spacing: 4) {
                    Text(item.snowfall >= epicPowderThreshold ? "🔥" : "❄️")
                        .font(.caption)
                }
                .foregroundStyle(.clear)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisValueLabel()
                    .font(.caption)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.2))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x
                                if let day: String = proxy.value(atX: x) {
                                    if let index = chartData.firstIndex(where: { $0.dayOfWeek == day }) {
                                        if selectedDayIndex != index {
                                            selectedDayIndex = index
                                            let generator = UISelectionFeedbackGenerator()
                                            generator.selectionChanged()
                                        }
                                    }
                                }
                            }
                    )
            }
        }
        .animation(.spring(response: 0.3), value: selectedChartType)
        .animation(.spring(response: 0.3), value: selectedDataMetric)
        .animation(.spring(response: 0.3), value: selectedDayIndex)
    }

    // MARK: - Quick Stats Bar

    private var quickStatsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickStatPill(icon: "snowflake", value: "\(totalSnowfall)\"", label: "Total Snow", color: .blue)
                QuickStatPill(icon: "star.fill", value: "\(powderDays)", label: "Powder Days", color: .yellow)
                if epicDays > 0 {
                    QuickStatPill(icon: "flame.fill", value: "\(epicDays)", label: "Epic Days", color: .orange)
                }
                QuickStatPill(icon: "thermometer.medium", value: "\(avgTemperature)°", label: "Avg High", color: .red)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Chart Type Selector

    private var chartTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chart Style")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ChartType.allCases, id: \.self) { type in
                        ChartTypeButton(type: type, isSelected: selectedChartType == type) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedChartType = type
                            }
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Data Metric Selector

    private var dataMetricSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Data")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(DataMetric.allCases, id: \.self) { metric in
                        DataMetricButton(metric: metric, isSelected: selectedDataMetric == metric) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDataMetric = metric
                                selectedDayIndex = nil
                            }
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Range")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTimeRange = range
                            selectedDayIndex = nil
                        }
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                            .foregroundStyle(selectedTimeRange == range ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background {
                                if selectedTimeRange == range {
                                    Capsule()
                                        .fill(Color.accentColor)
                                }
                            }
                    }
                }
            }
            .background(Capsule().fill(Color(UIColor.tertiarySystemFill)))
        }
    }

    // MARK: - Display Options

    private var displayOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Display Options")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                Toggle(isOn: $showTrendLine) {
                    Label("Trend Line", systemImage: "chart.line.uptrend.xyaxis")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider().padding(.leading, 50)

                Toggle(isOn: $showAnnotations) {
                    Label("Powder Day Markers", systemImage: "snowflake")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)

                Divider().padding(.leading, 50)

                Toggle(isOn: $showInsights) {
                    Label("AI Insights", systemImage: "sparkles")
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Insights Section

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)
                Text("Insights")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(insights) { insight in
                        InsightCard(insight: insight)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Day by Day Section

    private var dayByDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Day by Day")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: 8) {
                ForEach(Array(filteredForecast.enumerated()), id: \.element.id) { index, day in
                    DayDetailRow(
                        day: day,
                        isSelected: selectedDayIndex == index,
                        powderThreshold: powderDayThreshold,
                        epicThreshold: epicPowderThreshold
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDayIndex = selectedDayIndex == index ? nil : index
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func resetToDefaults() {
        withAnimation(.spring(response: 0.4)) {
            selectedChartType = .area
            selectedDataMetric = .snowfall
            selectedTimeRange = .sevenDays
            showTrendLine = true
            showAnnotations = true
            showInsights = true
            selectedDayIndex = nil
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

// MARK: - Supporting Views

struct QuickStatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(Capsule())
    }
}

struct ChartTypeButton: View {
    let type: ChartDetailView.ChartType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(type.rawValue)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

struct DataMetricButton: View {
    let metric: ChartDetailView.DataMetric
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: metric.icon)
                    .font(.caption)
                Text(metric.rawValue)
                    .font(.subheadline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? metric.color : Color(UIColor.tertiarySystemFill))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct InsightCard: View {
    let insight: ChartDetailView.Insight

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: insight.icon)
                    .foregroundStyle(insight.color)
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Text(insight.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(width: 160)
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DayDetailRow: View {
    let day: ForecastDay
    let isSelected: Bool
    let powderThreshold: Int
    let epicThreshold: Int

    private var isPowderDay: Bool { day.snowfall >= powderThreshold }
    private var isEpicDay: Bool { day.snowfall >= epicThreshold }

    var body: some View {
        HStack(spacing: 12) {
            // Day indicator
            VStack(spacing: 2) {
                Text(day.dayOfWeek)
                    .font(.caption)
                    .fontWeight(.medium)
                if isPowderDay {
                    Text(isEpicDay ? "🔥" : "❄️")
                        .font(.caption)
                }
            }
            .frame(width: 40)

            // Snow bar
            GeometryReader { geometry in
                let maxWidth = geometry.size.width
                let barWidth = day.snowfall > 0 ? max(4, CGFloat(day.snowfall) / 15.0 * maxWidth) : 0

                HStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            isEpicDay ? LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing) :
                            isPowderDay ? LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: barWidth, height: 28)

                    Spacer()
                }
            }
            .frame(height: 28)

            // Value
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(day.snowfall)\"")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(day.high)°/\(day.low)°")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 2)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ChartDetailView(
        mountain: Mountain.mock,
        forecast: ForecastDay.mockWeek,
        isPresented: .constant(true)
    )
}
