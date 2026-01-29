import SwiftUI
import Charts

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

    // Chart detail view state
    @State private var showingChartDetail: Bool = false
    @State private var selectedMountainForDetail: Mountain? = nil

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

    // Computed properties for powder day analysis
    private var powderDays: [(date: Date, maxSnowfall: Int)] {
        var dayMap: [Date: Int] = [:]
        let calendar = Calendar.current

        for favorite in visibleFavorites {
            let forecastDays = Array(favorite.forecast.prefix(selectedRange.days))
            for (index, day) in forecastDays.enumerated() {
                let chartDate = parseDate(day.date) ?? calendar.date(byAdding: .day, value: index, to: Date())!
                let normalizedDate = calendar.startOfDay(for: chartDate)
                if day.snowfall >= powderDayThreshold {
                    dayMap[normalizedDate] = max(dayMap[normalizedDate] ?? 0, day.snowfall)
                }
            }
        }
        return dayMap.map { ($0.key, $0.value) }.sorted { $0.date < $1.date }
    }

    private var bestPowderDay: Date? {
        powderDays.max(by: { $0.maxSnowfall < $1.maxSnowfall })?.date
    }

    /// Snow effect intensity based on max snowfall (0.0 to 1.0)
    private var snowEffectIntensity: Double {
        guard let maxSnow = powderDays.max(by: { $0.maxSnowfall < $1.maxSnowfall })?.maxSnowfall else {
            return 0.3
        }
        // Scale from 0.3 (6") to 0.8 (12"+)
        let normalized = Double(min(maxSnow, 12) - powderDayThreshold) / Double(epicPowderThreshold - powderDayThreshold)
        return 0.3 + (normalized * 0.5)
    }

    private var visibleFavorites: [(mountain: Mountain, forecast: [ForecastDay])] {
        favorites.filter { !hiddenMountains.contains($0.mountain.id) }
    }

    /// Accessibility label summarizing chart data for VoiceOver
    private var chartAccessibilityLabel: String {
        let rangeText = selectedRange == .threeDays ? "3-day" : selectedRange == .sevenDays ? "7-day" : "15-day"
        let mountainNames = visibleFavorites.map { $0.mountain.shortName }.joined(separator: ", ")
        let powderDayCount = powderDays.count

        var label = "\(rangeText) snow forecast for \(mountainNames)."

        if powderDayCount > 0 {
            label += " \(powderDayCount) powder day\(powderDayCount == 1 ? "" : "s") expected."
        }

        if let bestDay = bestPowderDay, let maxSnow = powderDays.first(where: { $0.date == bestDay })?.maxSnowfall {
            label += " Best day is \(formatShortDate(bestDay)) with \(maxSnow) inches."
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

                    // Powder day summary
                    if !powderDays.isEmpty {
                        powderDaySummary
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: error != nil)
        .onAppear {
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
        .sheet(isPresented: $showingHourlySheet) {
            if let selected = selectedDataPoint {
                HourlyBreakdownSheet(
                    mountain: selected.mountain,
                    day: selected.day,
                    isPresented: $showingHourlySheet
                )
            }
        }
        .sheet(isPresented: $showingChartDetail) {
            if let mountain = selectedMountainForDetail,
               let forecast = favorites.first(where: { $0.mountain.id == mountain.id })?.forecast {
                ChartDetailView(
                    mountain: mountain,
                    forecast: forecast,
                    isPresented: $showingChartDetail
                )
            }
        }
        .onChange(of: selectedRange) { _, _ in
            // Reset legend state and animate chart redraw when range changes
            chartDrawingProgress = 0
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                hiddenMountains.removeAll()
                selectedDate = nil
            }
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
            if let firstMountain = visibleFavorites.first?.mountain {
                Button {
                    selectedMountainForDetail = firstMountain
                    showingChartDetail = true
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
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

                    // Line mark for trend
                    LineMark(
                        x: .value("Day", chartDate),
                        y: .value("Snow", day.snowfall)
                    )
                    .foregroundStyle(by: .value("Mountain", favorite.mountain.shortName))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: .chartLineWidthMedium))

                    // Area fill below line - enhanced for powder days
                    AreaMark(
                        x: .value("Day", chartDate),
                        y: .value("Snow", day.snowfall)
                    )
                    .foregroundStyle(
                        isPowderDay
                            ? AnyShapeStyle(LinearGradient(
                                colors: [
                                    mountainColor(for: favorite.mountain).opacity(0.5),
                                    Color.cyan.opacity(0.25),
                                    mountainColor(for: favorite.mountain).opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    mountainColor(for: favorite.mountain).opacity(0.35),
                                    mountainColor(for: favorite.mountain).opacity(0.08)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ))
                    )
                    .interpolationMethod(.catmullRom)

                    // Powder day markers
                    if isPowderDay {
                        PointMark(
                            x: .value("Day", chartDate),
                            y: .value("Snow", day.snowfall)
                        )
                        .foregroundStyle(mountainColor(for: favorite.mountain))
                        .symbolSize(60)
                        .annotation(position: .top, spacing: 4) {
                            AnimatedPowderDayBadge(snowfall: day.snowfall, isEpic: day.snowfall >= epicPowderThreshold)
                        }
                    }

                    // Highlighted point for selected date
                    if let selectedDate = selectedDate,
                       let parsedDate = parseDate(day.date),
                       Calendar.current.isDate(parsedDate, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Day", chartDate),
                            y: .value("Snow", day.snowfall)
                        )
                        .foregroundStyle(mountainColor(for: favorite.mountain))
                        .symbolSize(100) // Larger size for selected point
                        .symbol {
                            Circle()
                                .fill(mountainColor(for: favorite.mountain))
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(color: mountainColor(for: favorite.mountain).opacity(0.5), radius: 4)
                        }
                    }
                }
            }
        }
        .frame(height: chartHeight)
        .frame(minWidth: 100) // Prevent 0x0 CAMetalLayer error
        .chartPlotStyle { plotArea in
            plotArea
                .background(
                    LinearGradient(
                        colors: [
                            Color(.systemBackground).opacity(0.98),
                            Color.blue.opacity(0.05),
                            Color(.systemBackground).opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(CGFloat.cornerRadiusCard)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text(dayLabel(for: date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                // Try Double first (in case data comes as Double), then Int
                let snowfall: Int? = value.as(Int.self) ?? value.as(Double.self).map { Int($0) }
                if let snowfall = snowfall {
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        Text("\(snowfall)\"")
                            .font(.caption2)
                            .foregroundColor(.secondary)
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
                        if let firstMountain = visibleFavorites.first?.mountain {
                            selectedMountainForDetail = firstMountain
                            showingChartDetail = true
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
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    /// Parse date string (YYYY-MM-DD format) to Date
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
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
        let isToday = calendar.isDateInToday(date)

        if isToday {
            return "Today"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Mon, Tue, Wed
        return formatter.string(from: date)
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
