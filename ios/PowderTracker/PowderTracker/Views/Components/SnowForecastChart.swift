import SwiftUI
import Charts

/// Wrapper for chart detail presentation to avoid blank sheet issue
struct ChartDetailItem: Identifiable {
    let id: String
    let mountain: Mountain
    let forecast: [ForecastDay]
}

/// 7-day snow forecast chart showing all favorite mountains overlaid
/// Uses Swift Charts with multi-line visualization
/// Includes powder day highlighting and interactive tooltips
struct SnowForecastChart: View {
    let favorites: [(mountain: Mountain, forecast: [ForecastDay])]
    var showHeader: Bool = false
    var chartHeight: CGFloat = .chartHeightStandard
    var isLoading: Bool = false
    var error: String? = nil
    var onRetry: (() -> Void)? = nil

    // Powder day threshold
    private let powderDayThreshold = 6
    private let epicPowderThreshold = 12

    // Range toggle state
    @State private var selectedRange: ForecastRange = .sevenDays
    @State private var selectedDataPoint: (mountain: Mountain, day: ForecastDay)? = nil
    @State private var showingHourlySheet: Bool = false
    @State private var selectedDate: Date? = nil

    // Chart detail view state - use a wrapper struct for sheet(item:)
    @State private var chartDetailItem: ChartDetailItem? = nil

    // Interactive legend state
    @State private var hiddenMountains: Set<String> = []

    // Interaction hint tracking
    @AppStorage("hasSeenForecastChartHint") private var hasSeenHint = false
    @State private var showInteractionHint = false
    @State private var hasInteracted = false

    // Track previous date for haptic feedback on date change
    @State private var previousSelectedDate: Date? = nil

    // Chart drawing animation state
    @State private var chartDrawingProgress: CGFloat = 0

    // MARK: - Cached Forecast Metrics (single-pass computation)

    /// All summary metrics computed in a single pass over the data.
    /// Recomputed only when inputs change (via .onChange), not on every render.
    @State private var cachedMetrics = ForecastMetrics()

    private struct ForecastMetrics {
        var powderDays: [(date: Date, maxSnowfall: Int)] = []
        var bestPowderDay: Date? = nil
        var snowEffectIntensity: Double = 0.3
        var totalSnowfall: Int = 0
        var next3DaysSnowfall: Int = 0
        var days4to7Snowfall: Int = 0
        var bestDayInfo: (date: Date, snowfall: Int, mountainName: String, mountainShortName: String)? = nil
        var winningMountainId: String? = nil
        var winningMountainName: String? = nil
        var winningMountainShortName: String? = nil
        var winningMountainTotal: Int = 0
    }

    private var visibleFavorites: [(mountain: Mountain, forecast: [ForecastDay])] {
        favorites.filter { !hiddenMountains.contains($0.mountain.id) }
    }

    // Convenience accessors that read from the cache
    private var powderDays: [(date: Date, maxSnowfall: Int)] { cachedMetrics.powderDays }
    private var bestPowderDay: Date? { cachedMetrics.bestPowderDay }
    private var snowEffectIntensity: Double { cachedMetrics.snowEffectIntensity }
    private var totalSnowfall: Int { cachedMetrics.totalSnowfall }
    private var next3DaysSnowfall: Int { cachedMetrics.next3DaysSnowfall }
    private var days4to7Snowfall: Int { cachedMetrics.days4to7Snowfall }
    private var bestDayInfo: (date: Date, snowfall: Int, mountainName: String, mountainShortName: String)? { cachedMetrics.bestDayInfo }
    private var winningMountain: (id: String, shortName: String, total: Int)? {
        guard let id = cachedMetrics.winningMountainId,
              let name = cachedMetrics.winningMountainShortName else { return nil }
        return (id, name, cachedMetrics.winningMountainTotal)
    }

    /// Recompute all metrics in a single pass
    private func recomputeMetrics() -> ForecastMetrics {
        var metrics = ForecastMetrics()
        let visible = visibleFavorites
        let calendar = Calendar.current
        let days = selectedRange.days

        var powderDayMap: [Date: Int] = [:]
        var maxTotalSnowfall = 0
        var maxNext3Days = 0
        var maxDays4to7 = 0
        var bestDay: (date: Date, snowfall: Int, mountainName: String, mountainShortName: String)?
        var winnerId: String?
        var winnerName: String?
        var winnerShortName: String?
        var winnerTotal = 0

        for favorite in visible {
            let forecastDays = Array(favorite.forecast.prefix(days))
            var totalForMountain = 0
            var first3Total = 0
            var days4to7Total = 0

            for (index, day) in forecastDays.enumerated() {
                let chartDate = parseDate(day.date) ?? calendar.date(byAdding: .day, value: index, to: Date())!
                let normalizedDate = calendar.startOfDay(for: chartDate)

                totalForMountain += day.snowfall

                if index < 3 {
                    first3Total += day.snowfall
                } else if index < 7 {
                    days4to7Total += day.snowfall
                }

                if day.snowfall >= powderDayThreshold {
                    powderDayMap[normalizedDate] = max(powderDayMap[normalizedDate] ?? 0, day.snowfall)
                }

                if day.snowfall > (bestDay?.snowfall ?? 0) {
                    bestDay = (chartDate, day.snowfall, favorite.mountain.name, favorite.mountain.shortName)
                }
            }

            maxTotalSnowfall = max(maxTotalSnowfall, totalForMountain)
            maxNext3Days = max(maxNext3Days, first3Total)
            if days >= 7 {
                maxDays4to7 = max(maxDays4to7, days4to7Total)
            }

            if totalForMountain > winnerTotal {
                winnerTotal = totalForMountain
                winnerId = favorite.mountain.id
                winnerName = favorite.mountain.name
                winnerShortName = favorite.mountain.shortName
            }
        }

        let sortedPowderDays = powderDayMap.map { ($0.key, $0.value) }.sorted { $0.0 < $1.0 }

        metrics.powderDays = sortedPowderDays
        metrics.bestPowderDay = sortedPowderDays.max(by: { $0.1 < $1.1 })?.0
        metrics.totalSnowfall = maxTotalSnowfall
        metrics.next3DaysSnowfall = maxNext3Days
        metrics.days4to7Snowfall = maxDays4to7
        metrics.bestDayInfo = bestDay
        metrics.winningMountainId = winnerId
        metrics.winningMountainName = winnerName
        metrics.winningMountainShortName = winnerShortName
        metrics.winningMountainTotal = winnerTotal

        // Snow effect intensity
        if let maxSnow = sortedPowderDays.max(by: { $0.1 < $1.1 })?.1 {
            let normalized = Double(min(maxSnow, 12) - powderDayThreshold) / Double(epicPowderThreshold - powderDayThreshold)
            metrics.snowEffectIntensity = 0.3 + (max(0, normalized) * 0.5)
        }

        return metrics
    }

    /// Accessibility label summarizing chart data for VoiceOver
    private var chartAccessibilityLabel: String {
        let rangeText = selectedRange == .threeDays ? "3-day" : selectedRange == .sevenDays ? "7-day" : "15-day"
        let mountainNames = visibleFavorites.map { $0.mountain.shortName }.joined(separator: ", ")
        let m = cachedMetrics

        var label = "\(rangeText) snow forecast for \(mountainNames)."

        if m.totalSnowfall > 0 {
            label += " Total expected: \(m.totalSnowfall) inches."
        }

        if let shortName = m.winningMountainShortName, m.winningMountainTotal > 0 {
            label += " \(shortName) leading with \(m.winningMountainTotal) inches."
        }

        if m.powderDays.count > 0 {
            label += " \(m.powderDays.count) powder day\(m.powderDays.count == 1 ? "" : "s") expected."
        }

        if let best = m.bestDayInfo {
            label += " Best day is \(formatShortDate(best.date)) with \(best.snowfall) inches at \(best.mountainShortName)."
        }

        if selectedRange == .sevenDays {
            label += " Next 3 days: \(m.next3DaysSnowfall) inches. Days 4-7: \(m.days4to7Snowfall) inches."
        }

        return label
    }

    enum ForecastRange: String, CaseIterable {
        case threeDays = "3D"
        case sevenDays = "7D"
        case fifteenDays = "15D"

        var days: Int {
            switch self {
            case .threeDays: return 3
            case .sevenDays: return 7
            case .fifteenDays: return 15
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with range toggle
            headerWithToggle

            if isLoading {
                chartSkeleton
                    .transition(.opacity)
            } else if let error = error {
                errorState(message: error)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if favorites.isEmpty {
                emptyState
                    .transition(.opacity)
            } else {
                VStack(spacing: CGFloat.spacingS) {
                    // Summary header with key metrics (always show)
                    summaryHeader

                    // Period breakdown (Next 3 Days vs Days 4-7)
                    if (selectedRange == .sevenDays || selectedRange == .fifteenDays) && totalSnowfall > 0 {
                        periodBreakdown
                    }

                    ZStack(alignment: .bottom) {
                        chart
                            .accessibilityLabel(chartAccessibilityLabel)
                            .accessibilityHint("Swipe horizontally to explore forecast data. Double tap to expand chart with customization options.")

                        // Subtle snow particle effect for powder days
                        if !powderDays.isEmpty {
                            SnowParticleEffect(
                                particleCount: min(powderDays.count * 4, 16),
                                intensity: snowEffectIntensity
                            )
                            .opacity(chartDrawingProgress)
                        }

                        // Interaction hint overlay
                        if showInteractionHint {
                            ChartInteractionHint(isVisible: $showInteractionHint) {
                                hasSeenHint = true
                            }
                            .padding(.bottom, CGFloat.spacingL)
                            .transition(AnyTransition.opacity.combined(with: AnyTransition.move(edge: .bottom)))
                        }
                    }

                    // Interactive legend
                    interactiveLegend

                    // Compact daily bars (OpenSnow style)
                    if totalSnowfall > 0 {
                        dailySnowfallBars
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: error != nil)
        .onAppear {
            // Compute initial metrics
            cachedMetrics = recomputeMetrics()

            // Animate chart lines drawing in
            if chartDrawingProgress == 0 {
                withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                    chartDrawingProgress = 1
                }
            }

            // Show hint for first-time users
            if !hasSeenHint && !hasInteracted && !favorites.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showInteractionHint = true
                    }
                }
            }
        }
        .onChange(of: hiddenMountains) { _, _ in
            cachedMetrics = recomputeMetrics()
        }
        .sheet(isPresented: $showingHourlySheet) {
            if let selected = selectedDataPoint {
                HourlyBreakdownSheet(
                    mountain: selected.mountain,
                    day: selected.day,
                    isPresented: $showingHourlySheet
                )
            }
        }
        .sheet(item: $chartDetailItem) { item in
            ChartDetailView(
                mountain: item.mountain,
                forecast: item.forecast,
                isPresented: Binding(
                    get: { chartDetailItem != nil },
                    set: { if !$0 { chartDetailItem = nil } }
                )
            )
        }
        .onChange(of: selectedRange) { _, _ in
            // Reset legend state and animate chart redraw when range changes
            chartDrawingProgress = 0
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hiddenMountains.removeAll()
                selectedDate = nil
            }
            // Recompute after hiddenMountains is cleared
            cachedMetrics = recomputeMetrics()
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                chartDrawingProgress = 1
            }
        }
    }

    // MARK: - Header with Range Toggle

    private var headerWithToggle: some View {
        HStack {
            if showHeader {
                Text("Snow Forecast")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()

            // Range toggle picker
            Picker("Range", selection: $selectedRange) {
                ForEach(ForecastRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 140)

            // Expand button to open chart detail view
            if let firstFavorite = visibleFavorites.first {
                Button {
                    chartDetailItem = ChartDetailItem(
                        id: firstFavorite.mountain.id,
                        mountain: firstFavorite.mountain,
                        forecast: firstFavorite.forecast
                    )
                    HapticFeedback.light.trigger()
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 32, height: 32)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Expand chart")
                .accessibilityHint("Opens detailed chart view with customization options")
            }
        }
    }

    // MARK: - Interactive Legend

    private var interactiveLegend: some View {
        HStack(spacing: CGFloat.spacingM) {
            ForEach(favorites, id: \.mountain.id) { favorite in
                legendButton(for: favorite.mountain)
            }

            Spacer()

            if !hiddenMountains.isEmpty {
                showAllButton
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func legendButton(for mountain: Mountain) -> some View {
        let isHidden = hiddenMountains.contains(mountain.id)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                toggleMountain(mountain.id)
            }
            HapticFeedback.selection.trigger()
        } label: {
            legendButtonLabel(for: mountain, isHidden: isHidden)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    isolateMountain(mountain.id)
                    HapticFeedback.light.trigger()
                }
        )
        .accessibilityLabel("\(mountain.name), \(isHidden ? "hidden" : "visible")")
        .accessibilityHint("Tap to toggle visibility. Long press to show only this mountain.")
    }

    @ViewBuilder
    private func legendButtonLabel(for mountain: Mountain, isHidden: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isHidden ? Color(.systemGray3) : mountainColor(for: mountain))
                .frame(width: 8, height: 8)

            Text(mountain.shortName)
                .font(.caption)
                .foregroundColor(isHidden ? .secondary : .primary)

            if !isHidden {
                Image(systemName: "checkmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHidden ? Color.clear : mountainColor(for: mountain).opacity(0.1))
        )
    }

    private var showAllButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hiddenMountains.removeAll()
            }
            HapticFeedback.light.trigger()
        } label: {
            Text("Show All")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
    }

    private func toggleMountain(_ id: String) {
        if hiddenMountains.contains(id) {
            hiddenMountains.remove(id)
        } else {
            // Don't allow hiding all mountains
            if hiddenMountains.count < favorites.count - 1 {
                hiddenMountains.insert(id)
            }
        }
    }

    private func isolateMountain(_ id: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            hiddenMountains = Set(favorites.map { $0.mountain.id }.filter { $0 != id })
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: CGFloat.spacingM) {
            if totalSnowfall > 0 {
                // Total expected snow
                summaryBadge(
                    icon: "snowflake",
                    value: "\(totalSnowfall)\"",
                    label: "Total",
                    color: .blue
                )

                // Best day
                if let best = bestDayInfo {
                    summaryBadge(
                        icon: "crown.fill",
                        value: "\(best.snowfall)\"",
                        label: "Best: \(formatShortDate(best.date))",
                        color: .yellow
                    )
                }

                // Powder days count
                if !powderDays.isEmpty {
                    summaryBadge(
                        icon: "star.fill",
                        value: "\(powderDays.count)",
                        label: powderDays.count == 1 ? "Pow Day" : "Pow Days",
                        color: .cyan
                    )
                }
            } else {
                // No snow expected - show helpful message
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Text("No snow in forecast")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))

                    Text("Check back later for updates")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.08))
                )
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func summaryBadge(icon: String, value: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                Text(label)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.12))
        )
    }

    // MARK: - Period Breakdown

    private var periodBreakdown: some View {
        HStack(spacing: CGFloat.spacingS) {
            if selectedRange == .sevenDays || selectedRange == .fifteenDays {
                // Next 3 days
                periodCard(
                    title: "Next 3 Days",
                    snowfall: next3DaysSnowfall,
                    color: .blue
                )

                if selectedRange == .sevenDays {
                    // Days 4-7
                    periodCard(
                        title: "Days 4-7",
                        snowfall: days4to7Snowfall,
                        color: .purple
                    )
                }
            }

            // Winning mountain
            if let winner = winningMountain, winner.total > 0 {
                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text(winner.shortName)
                        .font(.caption.bold())
                        .foregroundColor(.primary)

                    Text("\(winner.total)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.12))
                )
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func periodCard(title: String, snowfall: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)

                Text("\(snowfall)\"")
                    .font(.caption.bold())
                    .foregroundColor(color)
            }

            if snowfall >= powderDayThreshold {
                Image(systemName: "snowflake")
                    .font(.system(size: 10))
                    .foregroundStyle(color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    // MARK: - Daily Snowfall Bars (OpenSnow style)

    private var dailySnowfallBars: some View {
        // Get the best mountain's forecast for the bar display
        guard let bestMountain = winningMountain else {
            return AnyView(EmptyView())
        }

        let forecast = favorites.first(where: { $0.mountain.id == bestMountain.id })?.forecast ?? []
        let daysToShow = Array(forecast.prefix(selectedRange.days))
        let maxSnow = daysToShow.map { $0.snowfall }.max() ?? 1

        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                // Label
                HStack {
                    Text("\(bestMountain.shortName) Daily")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Bars
                HStack(spacing: 3) {
                    ForEach(Array(daysToShow.enumerated()), id: \.offset) { index, day in
                        VStack(spacing: 2) {
                            // Bar
                            let barHeight = maxSnow > 0 ? CGFloat(day.snowfall) / CGFloat(maxSnow) * 24 : 0
                            let isPowderDay = day.snowfall >= powderDayThreshold

                            RoundedRectangle(cornerRadius: 2)
                                .fill(
                                    isPowderDay ?
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .bottom, endPoint: .top) :
                                        LinearGradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.6)], startPoint: .bottom, endPoint: .top)
                                )
                                .frame(height: max(barHeight, day.snowfall > 0 ? 4 : 2))
                                .frame(maxWidth: .infinity)

                            // Day label
                            Text(day.dayOfWeek.prefix(1))
                                .font(.system(size: 8))
                                .foregroundColor(.secondary)

                            // Amount (only show if > 0)
                            if day.snowfall > 0 {
                                Text("\(day.snowfall)")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(isPowderDay ? .blue : .secondary)
                            } else {
                                Text("-")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary.opacity(0.5))
                            }
                        }
                    }
                }
                .frame(height: 50)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.04))
            )
        )
    }

    // MARK: - Powder Day Summary

    private var powderDaySummary: some View {
        let summaryText = "\(powderDays.count) powder day\(powderDays.count == 1 ? "" : "s") this \(selectedRange == .threeDays ? "period" : "week")"
        let bestDayText: String? = {
            if let bestDay = bestPowderDay, let maxSnow = powderDays.first(where: { $0.date == bestDay })?.maxSnowfall {
                return "Best day is \(formatShortDate(bestDay)) with \(maxSnow) inches"
            }
            return nil
        }()

        return HStack(spacing: CGFloat.spacingS) {
            Image(systemName: "snowflake.circle.fill")
                .foregroundStyle(.cyan)

            Text(summaryText)
                .font(.caption)
                .foregroundColor(.secondary)

            if let bestDay = bestPowderDay, let maxSnow = powderDays.first(where: { $0.date == bestDay })?.maxSnowfall {
                Text("•")
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                Image(systemName: "crown.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
                    .accessibilityHidden(true)
                Text("Best: \(formatShortDate(bestDay)) (\(maxSnow)\")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryText + (bestDayText.map { ". \($0)" } ?? ""))
    }

    private func formatShortDate(_ date: Date) -> String {
        Self.shortDateFormatter.string(from: date)
    }

    // MARK: - Chart Skeleton (Loading State)

    private var chartSkeleton: some View {
        VStack(spacing: .spacingS) {
            // Shimmer chart area
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(Color(.systemGray5))
                .frame(height: chartHeight)
                .overlay {
                    // Animated placeholder lines
                    GeometryReader { geo in
                        Path { path in
                            let width = geo.size.width
                            let height = geo.size.height
                            path.move(to: CGPoint(x: 20, y: height * 0.7))
                            path.addCurve(
                                to: CGPoint(x: width - 20, y: height * 0.4),
                                control1: CGPoint(x: width * 0.3, y: height * 0.3),
                                control2: CGPoint(x: width * 0.7, y: height * 0.6)
                            )
                        }
                        .stroke(Color(.systemGray4), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    }
                }
                .shimmering()

            // Skeleton legend
            HStack(spacing: .spacingM) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(width: 60, height: 20)
                }
                Spacer()
            }
            .shimmering()
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Powder day background highlights
            ForEach(powderDays, id: \.date) { powderDay in
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: powderDay.date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

                RectangleMark(
                    xStart: .value("Start", startOfDay),
                    xEnd: .value("End", endOfDay)
                )
                .foregroundStyle(
                    powderDay.maxSnowfall >= epicPowderThreshold
                        ? Color.cyan.opacity(0.18)
                        : Color.blue.opacity(0.12)
                )
            }

            ForEach(visibleFavorites, id: \.mountain.id) { favorite in
                // Get forecast based on selected range
                let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))

                ForEach(Array(forecastDays.enumerated()), id: \.offset) { index, day in
                    // Convert date string to Date, fallback to index-based date
                    let chartDate = parseDate(day.date) ?? Calendar.current.date(byAdding: .day, value: index, to: Date())!
                    let isPowderDay = day.snowfall >= powderDayThreshold

                    // Bar mark for daily snowfall - more intuitive than lines
                    BarMark(
                        x: .value("Day", chartDate),
                        y: .value("Snow", day.snowfall)
                    )
                    .foregroundStyle(
                        isPowderDay
                            ? AnyShapeStyle(LinearGradient(
                                colors: [
                                    mountainColor(for: favorite.mountain),
                                    Color.cyan.opacity(0.7)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            : AnyShapeStyle(mountainColor(for: favorite.mountain).opacity(0.7))
                    )
                    .position(by: .value("Mountain", favorite.mountain.shortName))
                    .cornerRadius(4)

                    // Value label on top of bar for significant snowfall
                    if day.snowfall > 0 {
                        PointMark(
                            x: .value("Day", chartDate),
                            y: .value("Snow", day.snowfall)
                        )
                        .foregroundStyle(.clear)
                        .annotation(position: .top, spacing: isPowderDay ? 2 : 4) {
                            if isPowderDay {
                                // Show powder badge for 6"+ days
                                AnimatedPowderDayBadge(snowfall: day.snowfall, isEpic: day.snowfall >= epicPowderThreshold)
                            } else if day.snowfall >= 2 {
                                // Show value label for 2-5" days
                                Text("\(day.snowfall)\"")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Highlighted point for selected date
                    if let selectedDate = selectedDate,
                       let parsedDate = parseDate(day.date),
                       Calendar.current.isDate(parsedDate, inSameDayAs: selectedDate) {
                        RuleMark(
                            x: .value("Day", chartDate)
                        )
                        .foregroundStyle(Color.white.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                    }
                }
            }
        }
        .frame(height: chartHeight)
        .frame(minWidth: 100) // Prevent 0x0 CAMetalLayer error
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    ZStack {
                        // Base gradient
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.03),
                                Color.cyan.opacity(0.02),
                                Color(.systemBackground)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )

                        // Subtle grid pattern
                        Color(.systemGray6).opacity(0.3)
                            .blendMode(.overlay)
                    }
                )
                .cornerRadius(CGFloat.cornerRadiusCard)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color(.systemGray5))
                    AxisTick()
                    AxisValueLabel {
                        Text(dayLabel(for: date))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                // Try Double first (in case data comes as Double), then Int
                let snowfall: Int? = value.as(Int.self) ?? value.as(Double.self).map { Int($0) }
                if let snowfall = snowfall, snowfall > 0 {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                        .foregroundStyle(Color(.systemGray6))
                    AxisValueLabel {
                        Text("\(snowfall)\"")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.blue)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
            }
        }
        .chartLegend(.hidden) // Using interactive legend instead
        .chartXSelection(value: $selectedDate)
        .opacity(chartDrawingProgress)
        .scaleEffect(x: 1, y: chartDrawingProgress, anchor: .bottom)
        .chartOverlay { proxy in
            GeometryReader { geo in
                // Invisible interaction area to detect touches
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !hasInteracted {
                                    hasInteracted = true
                                    dismissHint()
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double-tap to open chart detail view
                        if let firstFavorite = visibleFavorites.first {
                            chartDetailItem = ChartDetailItem(
                                id: firstFavorite.mountain.id,
                                mountain: firstFavorite.mountain,
                                forecast: firstFavorite.forecast
                            )
                            HapticFeedback.medium.trigger()
                        }
                    }

                // Scrub line when date is selected
                if let selectedDate = selectedDate,
                   let xPosition = proxy.position(forX: selectedDate) {
                    ChartScrubLine(
                        xPosition: xPosition,
                        height: geo.size.height,
                        showGradientFade: true
                    )
                    .allowsHitTesting(false)
                }

                // Tooltip when a date is selected
                if let selectedDate = selectedDate,
                   let xPosition = proxy.position(forX: selectedDate) {
                    let snowfallData = getSnowfallForDate(selectedDate)
                    if !snowfallData.isEmpty {
                        chartTooltip(
                            date: selectedDate,
                            data: snowfallData,
                            xPosition: xPosition,
                            plotWidth: proxy.plotSize.width
                        )
                    }
                }
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // Track previous date for haptic comparison
            if let newDate = newValue {
                // Check if we crossed to a new day
                let calendar = Calendar.current
                let crossedToNewDay = previousSelectedDate.map { prev in
                    !calendar.isDate(prev, inSameDayAs: newDate)
                } ?? true

                if crossedToNewDay {
                    HapticFeedback.selection.trigger()
                }

                previousSelectedDate = newDate
            }

            // Dismiss hint on first interaction
            if newValue != nil && !hasInteracted {
                hasInteracted = true
                dismissHint()
            }
        }
    }

    /// Tooltip view for displaying snowfall data
    private func chartTooltip(
        date: Date,
        data: [(mountain: Mountain, snowfall: Int, conditions: String?)],
        xPosition: CGFloat,
        plotWidth: CGFloat
    ) -> some View {
        let hasPowderDay = data.contains { $0.snowfall >= powderDayThreshold }
        let isBestDay = bestPowderDay.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false

        return VStack(alignment: .leading, spacing: 6) {
            // Date header with powder day indicator
            HStack(spacing: 4) {
                Text(formatSelectedDate(date))
                    .font(.caption.bold())
                    .foregroundColor(.primary)

                if isBestDay {
                    Image(systemName: "crown.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                } else if hasPowderDay {
                    Image(systemName: "snowflake")
                        .font(.caption2)
                        .foregroundStyle(.cyan)
                }
            }

            // Conditions summary (from first visible mountain)
            if let conditions = data.first?.conditions, !conditions.isEmpty {
                Text(conditions)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }

            Divider()
                .padding(.vertical, 2)

            // Mountain snowfall data
            ForEach(data, id: \.mountain.id) { item in
                HStack(spacing: 4) {
                    Circle()
                        .fill(mountainColor(for: item.mountain))
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )

                    Text(item.mountain.shortName)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(item.snowfall)\"")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(item.snowfall >= powderDayThreshold ? .cyan : .primary)

                    if item.snowfall >= powderDayThreshold {
                        Text("POW")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.cyan))
                    }
                }
            }

            // Tap hint
            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption2)
                Text("Tap for hourly details")
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
        }
        .padding(12)
        .frame(minWidth: 140)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        .position(x: min(max(xPosition, 85), plotWidth - 85), y: 60)
        .animation(.chartTooltip, value: xPosition)
        .onTapGesture {
            openHourlyBreakdown(for: date)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forecast for \(formatSelectedDate(date)). \(data.map { "\($0.mountain.shortName): \($0.snowfall) inches" }.joined(separator: ". "))")
        .accessibilityHint("Double tap to view hourly breakdown")
    }

    /// Open hourly breakdown sheet for the selected date
    private func openHourlyBreakdown(for date: Date) {
        let calendar = Calendar.current
        // Find the first mountain with matching forecast day
        for favorite in favorites {
            let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))
            if let day = forecastDays.first(where: { parseDate($0.date).map { calendar.isDate($0, inSameDayAs: date) } ?? false }) {
                selectedDataPoint = (mountain: favorite.mountain, day: day)
                showingHourlySheet = true
                HapticFeedback.selection.trigger()
                break
            }
        }
    }

    /// Dismiss the interaction hint
    private func dismissHint() {
        withAnimation(.easeOut(duration: 0.3)) {
            showInteractionHint = false
        }
        hasSeenHint = true
    }

    /// Get snowfall data for all mountains on the selected date
    private func getSnowfallForDate(_ date: Date) -> [(mountain: Mountain, snowfall: Int, conditions: String?)] {
        let calendar = Calendar.current
        return visibleFavorites.compactMap { favorite in
            let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))
            if let day = forecastDays.first(where: { parseDate($0.date).map { calendar.isDate($0, inSameDayAs: date) } ?? false }) {
                return (mountain: favorite.mountain, snowfall: day.snowfall, conditions: day.conditions)
            }
            return nil
        }
    }

    /// Format the selected date for display
    private func formatSelectedDate(_ date: Date) -> String {
        Self.selectedDateFormatter.string(from: date)
    }

    // MARK: - Cached Formatters (Performance Optimization)

    /// Cached date formatter to avoid expensive instantiation in loops
    private static let dateParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private static let selectedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    /// Parse date string (YYYY-MM-DD format) to Date
    private func parseDate(_ dateString: String) -> Date? {
        Self.dateParser.date(from: dateString)
    }

    private var emptyState: some View {
        VStack(spacing: CGFloat.spacingM) {
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient(
                    colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                ))

            VStack(spacing: CGFloat.spacingXS) {
                Text("No Forecast Data")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Add mountains to your favorites to see their snow forecasts here")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Optional: Add a visual hint
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                Text("Tap the star on any mountain")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, CGFloat.spacingXS)
        }
        .frame(height: chartHeight)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No forecast data. Add mountains to your favorites to see their snow forecasts.")
    }

    /// Error state with retry option
    private func errorState(message: String) -> some View {
        VStack(spacing: CGFloat.spacingM) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)

            VStack(spacing: CGFloat.spacingXS) {
                Text("Unable to Load Forecast")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let onRetry = onRetry {
                Button(action: onRetry) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, CGFloat.spacingM)
                    .padding(.vertical, CGFloat.spacingS)
                    .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(.plain)
                .padding(.top, CGFloat.spacingXS)
            }
        }
        .frame(height: chartHeight)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error loading forecast. \(message)")
        .accessibilityHint(onRetry != nil ? "Double tap to retry" : "")
    }

    // MARK: - Helpers

    /// Get color for a mountain (use mountain's color if available, otherwise generate from name)
    private func mountainColor(for mountain: Mountain) -> Color {
        if let color = Color(hex: mountain.color) {
            return color
        }

        // Fallback colors if hex color not available
        let colors: [Color] = [.blue, .purple, .green, .orange, .red, .cyan, .indigo, .mint]
        let hash = abs(mountain.id.hashValue)
        return colors[hash % colors.count]
    }

    /// Format date to day label (Mon, Tue, Wed, etc.)
    private func dayLabel(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        return Self.shortDateFormatter.string(from: date)
    }
}

// MARK: - Hourly Breakdown Sheet

struct HourlyBreakdownSheet: View {
    let mountain: Mountain
    let day: ForecastDay
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingL) {
                    // Day summary header
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text(day.dayOfWeek)
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(day.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Summary stats
                    HStack(spacing: .spacingL) {
                        statCard(
                            icon: "snowflake",
                            value: "\(day.snowfall)\"",
                            label: "Expected Snow"
                        )

                        statCard(
                            icon: "thermometer.medium",
                            value: "\(day.high)°/\(day.low)°",
                            label: "High/Low"
                        )

                        statCard(
                            icon: "wind",
                            value: "\(day.wind.speed)mph",
                            label: "Wind"
                        )
                    }
                    .padding(.horizontal)

                    // Conditions
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Conditions")
                            .font(.headline)

                        HStack(spacing: .spacingS) {
                            Text(day.iconEmoji)
                                .font(.title)

                            Text(day.conditions)
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                    .padding(.horizontal)

                    // Precipitation probability
                    VStack(alignment: .leading, spacing: .spacingS) {
                        Text("Precipitation")
                            .font(.headline)

                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("\(day.precipProbability)% chance of \(day.precipType)")
                                .font(.subheadline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(.cornerRadiusCard)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationTitle(mountain.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func statCard(icon: String, value: String, label: String) -> some View {
        VStack(spacing: .spacingXS) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Snow Particle Effect

/// A subtle snow particle animation overlay for powder day emphasis
struct SnowParticleEffect: View {
    let particleCount: Int
    let intensity: Double

    @State private var particles: [ChartSnowParticle] = []

    init(particleCount: Int = 12, intensity: Double = 0.5) {
        self.particleCount = particleCount
        self.intensity = min(1.0, max(0.0, intensity))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    snowflakeView(particle: particle, containerSize: geometry.size)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func initializeParticles(in size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        particles = (0..<particleCount).map { index in
            ChartSnowParticle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -20...size.height),
                size: CGFloat.random(in: 3...6),
                opacity: Double.random(in: 0.3...0.7) * intensity,
                speed: Double.random(in: 15...30),
                wobbleAmount: CGFloat.random(in: 5...15),
                wobbleSpeed: Double.random(in: 1...3),
                delay: Double.random(in: 0...2)
            )
        }
    }

    @ViewBuilder
    private func snowflakeView(particle: ChartSnowParticle, containerSize: CGSize) -> some View {
        ChartSnowflakeAnimatedView(particle: particle, containerSize: containerSize)
    }
}

private struct ChartSnowParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double
    let wobbleAmount: CGFloat
    let wobbleSpeed: Double
    let delay: Double
}

private struct ChartSnowflakeAnimatedView: View {
    let particle: ChartSnowParticle
    let containerSize: CGSize

    @State private var yOffset: CGFloat = 0
    @State private var wobbleOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: particle.size, weight: .ultraLight))
            .foregroundStyle(.white.opacity(particle.opacity))
            .shadow(color: .cyan.opacity(0.3), radius: 2)
            .position(x: particle.x + wobbleOffset, y: particle.y + yOffset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                let fallDuration = (Double(containerSize.height) + 40) / particle.speed
                withAnimation(.linear(duration: fallDuration).delay(particle.delay).repeatForever(autoreverses: false)) {
                    yOffset = containerSize.height + 20 - particle.y
                }
                withAnimation(.easeInOut(duration: particle.wobbleSpeed).delay(particle.delay).repeatForever(autoreverses: true)) {
                    wobbleOffset = particle.wobbleAmount
                }
                withAnimation(.linear(duration: 8).delay(particle.delay).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

// MARK: - Preview

#Preview("Default") {
    ScrollView {
        VStack(spacing: 20) {
            SnowForecastChart(
                favorites: [],
                showHeader: true
            )
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Loading State") {
    ScrollView {
        VStack(spacing: 20) {
            SnowForecastChart(
                favorites: [],
                showHeader: true,
                isLoading: true
            )
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
