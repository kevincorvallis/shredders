import SwiftUI

/// Unified mountain detail view with collapsible header and sticky tab bar
/// Replaces LocationView and TabbedLocationView with a modern, scrollable interface
struct MountainDetailView: View {
    let mountain: Mountain
    @StateObject private var viewModel: LocationViewModel
    @Environment(\.dismiss) private var dismiss

    // State
    @State private var selectedTab: DetailTab = .overview
    @State private var headerCollapsed = false
    @State private var alertsDismissed = false

    // Sticky header constants
    private let headerFullHeight: CGFloat = 160
    private let headerCollapsedHeight: CGFloat = 50
    private let tabBarHeight: CGFloat = 50

    init(mountain: Mountain) {
        self.mountain = mountain
        _viewModel = StateObject(wrappedValue: LocationViewModel(mountain: mountain))
    }

    enum DetailTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case forecast = "Forecast"
        case conditions = "Conditions"
        case travel = "Travel"
        case lifts = "Lifts"
        case social = "Social"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .overview: return "gauge.with.dots.needle.bottom.50percent"
            case .forecast: return "calendar"
            case .conditions: return "cloud.snow.fill"
            case .travel: return "car.fill"
            case .lifts: return "cablecar.fill"
            case .social: return "person.3.fill"
            }
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacer for header
                        Color.clear
                            .frame(height: headerFullHeight + tabBarHeight)

                        // Alert banner if needed
                        if let data = viewModel.locationData, !data.alerts.isEmpty && !alertsDismissed {
                            AlertBannerView(
                                alerts: data.alerts,
                                isDismissed: $alertsDismissed
                            )
                            .padding(.horizontal, .spacingL)
                            .padding(.top, .spacingM)
                        }

                        // Tab content
                        tabContent
                            .padding(.horizontal, .spacingL)
                            .padding(.top, .spacingM)
                            .padding(.bottom, .spacingXL)
                    }
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeometry.frame(in: .named("scroll")).minY
                                )
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                    withAnimation(.easeOut(duration: 0.2)) {
                        headerCollapsed = offset < -100
                    }
                }

                // Fixed header + tab bar
                VStack(spacing: 0) {
                    // Collapsible header
                    CollapsibleHeaderView(
                        mountain: mountain,
                        webcam: viewModel.locationData?.mountain.webcams.first,
                        isCollapsed: headerCollapsed,
                        fullHeight: headerFullHeight,
                        collapsedHeight: headerCollapsedHeight
                    )

                    // Sticky tab bar
                    StickyTabBar(
                        selectedTab: $selectedTab,
                        tabs: DetailTab.allCases
                    )
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if headerCollapsed {
                    Text(mountain.shortName)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .task {
            await viewModel.fetchData()
        }
        .refreshable {
            await viewModel.fetchData()
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        if viewModel.isLoading {
            loadingState
        } else if let error = viewModel.error {
            ErrorView(message: error) {
                Task { await viewModel.fetchData() }
            }
        } else {
            switch selectedTab {
            case .overview:
                overviewTab
            case .forecast:
                forecastTab
            case .conditions:
                conditionsTab
            case .travel:
                travelTab
            case .lifts:
                liftsTab
            case .social:
                socialTab
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: .spacingL) {
            ProgressView()
            Text("Loading conditions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, .spacingXXL)
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        LazyVStack(spacing: .spacingL) {
            // At a glance stats
            AtAGlanceCard(viewModel: viewModel, onNavigateToLifts: { selectedTab = .lifts })

            // Lift line predictor
            if viewModel.locationData != nil {
                LiftLinePredictorCard(viewModel: viewModel)
            }

            // Quick forecast preview
            if let forecast = viewModel.locationData?.forecast.prefix(3), !forecast.isEmpty {
                quickForecastPreview(Array(forecast))
            }

            // Webcams preview
            if viewModel.hasWebcams {
                webcamPreview
            }
        }
    }

    private func quickForecastPreview(_ forecast: [ForecastDay]) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text("3-Day Forecast")
                    .font(.headline)
                Spacer()
                Button("See All") { selectedTab = .forecast }
                    .font(.subheadline)
            }

            HStack(spacing: .spacingM) {
                ForEach(forecast) { day in
                    VStack(spacing: .spacingXS) {
                        Text(day.dayOfWeek)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(day.iconEmoji)
                            .font(.title2)

                        if day.snowfall > 0 {
                            Text("\(day.snowfall)\"")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        } else {
                            Text("—")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Text("\(day.high)°")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacingM)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusCard)
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private var webcamPreview: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                Text("Webcams")
                    .font(.headline)
                Spacer()
            }

            WebcamsSection(viewModel: viewModel)
        }
    }

    // MARK: - Forecast Tab

    private var forecastTab: some View {
        LazyVStack(spacing: .spacingL) {
            if let forecast = viewModel.locationData?.forecast {
                // 7-day chart
                SnowForecastChart(
                    favorites: [(mountain, forecast)],
                    showHeader: true
                )
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)

                // Day-by-day breakdown
                ForEach(forecast.prefix(7)) { day in
                    ForecastDayRow(day: day)
                }
            }
        }
    }

    // MARK: - Conditions Tab

    private var conditionsTab: some View {
        LazyVStack(spacing: .spacingL) {
            SnowDepthSection(viewModel: viewModel, onNavigateToHistory: {})
            WeatherConditionsSection(viewModel: viewModel, onNavigateToForecast: { selectedTab = .forecast })
        }
    }

    // MARK: - Travel Tab

    private var travelTab: some View {
        LazyVStack(spacing: .spacingL) {
            if viewModel.hasRoadData {
                RoadConditionsSection(viewModel: viewModel, onNavigateToTravel: {})
            } else {
                emptyStateCard(
                    icon: "car.fill",
                    title: "No Road Data",
                    message: "Road conditions not available for this mountain"
                )
            }

            // Trip advice if available
            if let tripAdvice = viewModel.locationData?.tripAdvice {
                tripAdviceCard(tripAdvice)
            }
        }
    }

    private func tripAdviceCard(_ tripAdvice: TripAdviceResponse) -> some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            Text("Trip Advice")
                .font(.headline)

            Text(tripAdvice.headline)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: .spacingL) {
                riskPill(label: "Crowds", level: tripAdvice.crowd)
                riskPill(label: "Traffic", level: tripAdvice.trafficRisk)
                riskPill(label: "Roads", level: tripAdvice.roadRisk)
            }

            if !tripAdvice.notes.isEmpty {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    ForEach(tripAdvice.notes, id: \.self) { note in
                        HStack(alignment: .top, spacing: .spacingS) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                            Text(note)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func riskPill(label: String, level: RiskLevel) -> some View {
        VStack(spacing: .spacingXS) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(level.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(riskColor(level))
                .padding(.horizontal, .spacingS)
                .padding(.vertical, .spacingXS)
                .background(riskColor(level).opacity(0.15))
                .cornerRadius(.cornerRadiusMicro)
        }
    }

    private func riskColor(_ level: RiskLevel) -> Color {
        switch level {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }

    // MARK: - Lifts Tab

    private var liftsTab: some View {
        LazyVStack(spacing: .spacingL) {
            if let liftData = viewModel.liftData, !liftData.features.isEmpty {
                LiftStatusSection(viewModel: viewModel)
            } else if let liftStatus = viewModel.locationData?.conditions.liftStatus {
                liftStatusSummary(liftStatus)
            } else {
                emptyStateCard(
                    icon: "cablecar.fill",
                    title: "No Lift Data",
                    message: "Lift status not available"
                )
            }

            // Map with lift lines
            if let mountainDetail = viewModel.locationData?.mountain {
                LocationMapSection(
                    mountain: mountain,
                    mountainDetail: mountainDetail,
                    liftData: viewModel.liftData
                )
            }
        }
    }

    private func liftStatusSummary(_ status: LiftStatus) -> some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack {
                Text("Lift Status")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(status.isOpen ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(status.isOpen ? "Open" : "Closed")
                    .font(.caption)
                    .foregroundColor(status.isOpen ? .green : .red)
            }

            HStack(spacing: .spacingL) {
                statBox(value: "\(status.liftsOpen)", label: "Lifts Open", total: status.liftsTotal)
                statBox(value: "\(status.runsOpen)", label: "Runs Open", total: status.runsTotal)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    private func statBox(value: String, label: String, total: Int) -> some View {
        VStack(spacing: .spacingXS) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                Text("/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(.cornerRadiusButton)
    }

    // MARK: - Social Tab

    private var socialTab: some View {
        LazyVStack(spacing: .spacingL) {
            SocialTab(viewModel: viewModel, mountain: mountain)
        }
    }

    // MARK: - Helper Views

    private func emptyStateCard(icon: String, title: String, message: String) -> some View {
        VStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingXL)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Scroll Offset Preference Key

struct ScrollOffsetPreferenceKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MountainDetailView(mountain: Mountain.mock)
    }
}
