import SwiftUI
import Charts

/// Decoupled history chart view that accepts data as props
/// Parent view owns the ViewModel and passes data down
struct HistoryChartView: View {
    // Data props - no ViewModel ownership
    let history: [HistoryDataPoint]
    let summary: HistorySummary?
    let isLoading: Bool
    let error: String?

    // Configuration
    var selectedDays: Int = 30
    var onPeriodChange: ((Int) async -> Void)?
    var onDataPointSelect: ((HistoryDataPoint) -> Void)?

    // Local state
    @State private var displayMode: ChartDisplayMode = .depth

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                if isLoading && history.isEmpty {
                    HistoryChartSkeleton()
                } else if let error = error {
                    errorView(error)
                } else {
                    // Period Picker
                    periodPicker

                    // Summary Stats
                    if let summary = summary {
                        summarySection(summary)
                    }

                    // Mode switcher
                    if !history.isEmpty {
                        modeSelector
                    }

                    // Chart
                    if !history.isEmpty {
                        chartSection
                    }

                    // Powder day summary
                    if !history.isEmpty {
                        powderDaySummary
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Error View

    private func errorView(_ error: String) -> some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("Error loading data")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingXL)
    }

    // MARK: - Period Picker

    private var periodPicker: some View {
        Picker("Period", selection: Binding(
            get: { selectedDays },
            set: { days in
                Task {
                    await onPeriodChange?(days)
                }
            }
        )) {
            Text("7 Days").tag(7)
            Text("30 Days").tag(30)
            Text("60 Days").tag(60)
            Text("90 Days").tag(90)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedDays) { _, _ in
            HapticFeedback.selection.trigger()
        }
    }

    // MARK: - Summary Section

    private func summarySection(_ summary: HistorySummary) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: .spacingL) {
            HistoryStatCard(
                title: "Current",
                value: "\(summary.currentDepth)\"",
                subtitle: "depth",
                icon: "ruler",
                color: Color.chartPrimary(for: .snowDepth)
            )

            HistoryStatCard(
                title: "Peak",
                value: "\(summary.maxDepth)\"",
                subtitle: "max depth",
                icon: "arrow.up.to.line",
                color: .green
            )

            HistoryStatCard(
                title: "Total",
                value: "\(summary.totalSnowfall)\"",
                subtitle: "snowfall",
                icon: "snowflake",
                color: .cyan
            )
        }
    }

    // MARK: - Mode Selector

    private var modeSelector: some View {
        Picker("Display", selection: $displayMode) {
            ForEach([ChartDisplayMode.depth, .daily, .cumulative], id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: displayMode) { _, _ in
            HapticFeedback.selection.trigger()
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Chart title based on mode
            HStack {
                Text(chartTitle)
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Annotations legend
                if displayMode != .cumulative {
                    HStack(spacing: .spacingXS) {
                        Image(systemName: "snowflake")
                            .font(.caption2)
                            .foregroundStyle(.cyan)
                        Text("Powder Day")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // The chart
            chartView
        }
        .padding(.spacingL)
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .shadow(color: Color(.label).opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var chartTitle: String {
        switch displayMode {
        case .depth:
            return "Snow Depth Trend"
        case .daily:
            return "Daily Snowfall"
        case .cumulative:
            return "Cumulative Snowfall"
        }
    }

    @ViewBuilder
    private var chartView: some View {
        let annotations = AnnotationDetector.detectAllAnnotations(from: history)

        switch displayMode {
        case .depth:
            TrendLineChart(
                history: history,
                displayMode: .depth,
                annotations: annotations,
                onSelect: onDataPointSelect
            )

        case .daily:
            InteractiveBarChart(
                history: history,
                showSnowfall: true,
                annotations: annotations,
                onSelect: onDataPointSelect
            )

        case .cumulative:
            TrendLineChart(
                history: history,
                displayMode: .cumulative,
                annotations: annotations,
                onSelect: onDataPointSelect
            )
        }
    }

    // MARK: - Powder Day Summary

    private var powderDaySummary: some View {
        let annotations = AnnotationDetector.detectAllAnnotations(from: history)
        let powderDays = annotations.powderDays
        let epicDays = powderDays.filter { $0.snowfall >= 12 }

        guard !powderDays.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: .spacingM) {
                Text("Powder Days")
                    .font(.headline)
                    .fontWeight(.semibold)

                HStack(spacing: .spacingL) {
                    // Total powder days
                    VStack(spacing: .spacingXS) {
                        HStack(spacing: 4) {
                            Image(systemName: "snowflake")
                                .foregroundStyle(.cyan)
                            Text("\(powderDays.count)")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                        }
                        Text("Powder Days")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !epicDays.isEmpty {
                        Divider()
                            .frame(height: 40)

                        // Epic powder days
                        VStack(spacing: .spacingXS) {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text("\(epicDays.count)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.primary)
                            }
                            Text("Epic Days (12\"+)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()

                    // Best day
                    if let bestDay = annotations.bestDay {
                        VStack(alignment: .trailing, spacing: .spacingXS) {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .foregroundStyle(.orange)
                                Text("\(bestDay.value)\"")
                                    .font(.title2.bold())
                                    .foregroundStyle(.orange)
                            }
                            Text("Best Day")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(.spacingL)
            .background(Color(.systemBackground))
            .cornerRadius(.cornerRadiusCard)
        )
    }
}

// MARK: - Enhanced Stat Card

struct HistoryStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color.opacity(0.8))

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .contentTransition(.numericText())

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Legacy StatCard (for backwards compatibility)

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        HistoryStatCard(
            title: title,
            value: value,
            subtitle: subtitle,
            icon: "chart.bar",
            color: .blue
        )
    }
}

// MARK: - Container View with ViewModel

/// Wrapper that owns the ViewModel and passes data to HistoryChartView
struct HistoryChartContainer: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        HistoryChartView(
            history: viewModel.history,
            summary: viewModel.summary,
            isLoading: viewModel.isLoading,
            error: viewModel.error,
            selectedDays: viewModel.selectedDays,
            onPeriodChange: { days in
                await viewModel.changePeriod(to: days)
            }
        )
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.history.isEmpty {
                await viewModel.loadHistory()
            }
        }
    }
}

// MARK: - Skeleton

struct HistoryChartSkeleton: View {
    var body: some View {
        VStack(spacing: .spacingL) {
            // Period picker skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .frame(height: 32)

            // Summary cards skeleton
            HStack(spacing: .spacingM) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: .cornerRadiusCard)
                        .fill(Color(.systemGray5))
                        .frame(height: 80)
                }
            }

            // Chart skeleton
            ChartSkeleton(height: .chartHeightStandard)
        }
        .shimmering(active: true)
    }
}

// MARK: - Preview

#Preview("History Chart View") {
    NavigationStack {
        HistoryChartView(
            history: HistoryDataPoint.mockHistory(days: 30),
            summary: HistorySummary(
                currentDepth: 145,
                maxDepth: 162,
                minDepth: 98,
                totalSnowfall: 87,
                avgDailySnowfall: "2.9"
            ),
            isLoading: false,
            error: nil
        )
        .navigationTitle("History")
    }
}

#Preview("Loading State") {
    NavigationStack {
        HistoryChartView(
            history: [],
            summary: nil,
            isLoading: true,
            error: nil
        )
        .navigationTitle("History")
    }
}

#Preview("Error State") {
    NavigationStack {
        HistoryChartView(
            history: [],
            summary: nil,
            isLoading: false,
            error: "Failed to load history data. Please check your connection."
        )
        .navigationTitle("History")
    }
}

#Preview("Container") {
    NavigationStack {
        HistoryChartContainer()
    }
}
