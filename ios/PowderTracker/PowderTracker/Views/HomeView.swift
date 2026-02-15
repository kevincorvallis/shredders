import SwiftUI

/// Enhanced Homepage with time-based tabs and smart alerts
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @ObservedObject private var favoritesManager = FavoritesService.shared
    @StateObject private var scrollSync = TimelineScrollSync()
    @State private var selectedTab: HomeTab = .forecast
    @State private var showingManageFavorites = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab Picker
                tabPicker

                // Smart Alerts Banner (if any)
                SmartAlertsBanner(
                    leaveNowMountains: viewModel.cachedLeaveNowMountains,
                    weatherAlerts: viewModel.getActiveAlerts()
                )

                // Last updated indicator
                if let lastRefresh = viewModel.lastRefreshDate, !viewModel.isLoading {
                    HStack {
                        LastUpdatedPill(date: lastRefresh, source: nil, showIcon: true)
                        Spacer()
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingXS)
                    .background(Color(.systemBackground))
                }

                // Tab Content with floating Leave Now banner
                FloatingLeaveNowContainer(
                    leaveNowMountain: viewModel.cachedLeaveNowMountains.first
                ) {
                    ScrollView {
                        if viewModel.isLoading && viewModel.mountainData.isEmpty {
                            loadingContent
                        } else {
                            tabContent
                        }
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingManageFavorites = true
                    } label: {
                        Image(systemName: "gear")
                    }
                    .accessibilityIdentifier("home_settings_button")
                    .accessibilityLabel("Settings")
                }
            }
            .refreshable {
                await refreshData()
            }
            .task {
                await loadData()
            }
            .sheet(isPresented: $showingManageFavorites) {
                FavoritesManagementSheet()
            }
        }
    }

    private var tabPicker: some View {
        Picker("View", selection: $selectedTab) {
            ForEach(HomeTab.allCases) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingS)
        .background(Color(.systemBackground))
    }

    private var loadingContent: some View {
        VStack(spacing: .spacingM) {
            ForEach(0..<3, id: \.self) { _ in
                SkeletonMountainCard()
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingS)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .forecast:
            ForecastTabView(viewModel: viewModel)
        case .conditions:
            ConditionsTabView(viewModel: viewModel)
        case .favorites:
            FavoritesTabView(viewModel: viewModel)
        }
    }

    private func loadData() async {
        // Skip if already pre-fetched during app launch
        guard viewModel.mountainData.isEmpty else { return }
        await viewModel.loadData()
        await viewModel.loadEnhancedData()
    }

    private func refreshData() async {
        await viewModel.refresh()
        await viewModel.loadEnhancedData()
    }
}

// MARK: - Home Tab Enum

enum HomeTab: String, CaseIterable, Identifiable {
    case forecast = "Forecast"
    case conditions = "Conditions"
    case favorites = "Favorites"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .forecast: return "calendar"
        case .conditions: return "bolt.fill"
        case .favorites: return "star.fill"
        }
    }
}

// MARK: - Snow Filter Enum (used in Today tab)

enum SnowFilter: String, CaseIterable {
    case weather = "Weather"
    case snowSummary = "Snow Summary"
    case snowForecast = "Snow Forecast"
}

// MARK: - Favorites ViewModel

@MainActor
class FavoritesViewModel: ObservableObject {
    @Published var mountains: [Mountain] = []
    @Published var mountainData: [String: MountainBatchedResponse] = [:]
    @Published var isLoading = false

    private let apiClient = APIClient.shared
    private let favoritesManager = FavoritesService.shared

    func loadData() async {
        isLoading = true

        // Load mountains list
        do {
            let response = try await apiClient.fetchMountains()
            mountains = response.mountains
        } catch {
            // Mountains list failed to load
        }

        // Load data for each favorite
        await loadFavoritesData()

        isLoading = false
    }

    func loadFavoritesData() async {
        await withTaskGroup(of: (String, MountainBatchedResponse?).self) { group in
            for mountainId in favoritesManager.favoriteIds {
                group.addTask {
                    do {
                        let data = try await self.apiClient.fetchMountainData(for: mountainId)
                        return (mountainId, data)
                    } catch {
                        return (mountainId, nil)
                    }
                }
            }

            for await (id, data) in group {
                if let data = data {
                    mountainData[id] = data
                }
            }
        }
    }

    func refresh() async {
        await loadData()
    }
}

// MARK: - Mountain Selector Header

struct MountainSelectorHeader: View {
    let mountainName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Current Mountain")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(mountainName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }

                Spacer()

                Image(systemName: "chevron.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(.cornerRadiusCard)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mountain Picker Sheet

struct MountainPickerSheet: View {
    @State private var viewModel = MountainSelectionViewModel()
    let selectedMountainId: String
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.mountains) { mountain in
                    Button {
                        onSelect(mountain.id)
                    } label: {
                        HStack {
                            MountainLogoView(
                                logoUrl: mountain.logo,
                                color: mountain.color,
                                size: 40
                            )

                            VStack(alignment: .leading, spacing: .spacingXS) {
                                Text(mountain.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(mountain.region.uppercased())
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if mountain.id == selectedMountainId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, .spacingXS)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Choose Mountain")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadMountains()
            }
        }
    }
}

// MARK: - Single Mountain ViewModel

@MainActor
@Observable
class SingleMountainViewModel {
    var mountain: Mountain?
    var conditions: MountainConditions?
    var powderScore: MountainPowderScore?
    var forecast: [ForecastDay] = []
    var snowTimelineData: [SnowDataPoint] = []
    var isLoading = false
    var error: String?

    private let apiClient = APIClient.shared
    private var currentMountainId: String = ""

    func loadData(for mountainId: String) async {
        currentMountainId = mountainId
        isLoading = true
        error = nil

        do {
            // Load mountain info
            let mountainsResponse = try await apiClient.fetchMountains()
            mountain = mountainsResponse.mountains.first { $0.id == mountainId }

            // Load full data
            let data = try await apiClient.fetchMountainData(for: mountainId)
            conditions = data.conditions
            powderScore = data.powderScore
            forecast = data.forecast

            // Build snow timeline from forecast
            buildSnowTimeline()

        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func refresh() async {
        await loadData(for: currentMountainId)
    }

    private func buildSnowTimeline() {
        var timeline: [SnowDataPoint] = []
        let today = Date()

        // Past 7 days (use historical data if available, or zeros)
        for i in (1...7).reversed() {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: today)!
            timeline.append(SnowDataPoint(
                date: date,
                snowfall: 0, // TODO: Add historical snowfall API
                isForecast: false,
                isToday: false
            ))
        }

        // Today
        timeline.append(SnowDataPoint(
            date: today,
            snowfall: conditions?.snowfall24h ?? 0,
            isForecast: false,
            isToday: true
        ))

        // Future from forecast
        for (index, day) in forecast.prefix(7).enumerated() {
            let date = Calendar.current.date(byAdding: .day, value: index + 1, to: today)!
            timeline.append(SnowDataPoint(
                date: date,
                snowfall: Int(day.snowfall),
                isForecast: true,
                isToday: false
            ))
        }

        snowTimelineData = timeline
    }
}

// MARK: - Custom Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Skeleton Loading Card

struct SkeletonMountainCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: .spacingS) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .shimmering(isAnimating: isAnimating)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 16)
                        .shimmering(isAnimating: isAnimating)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 12)
                        .shimmering(isAnimating: isAnimating)
                }

                Spacer()
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(Color(.tertiarySystemBackground))

            // Content area
            VStack(spacing: .spacingS) {
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(spacing: .spacingXS) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 10)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingM)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmering(isAnimating: Bool) -> some View {
        self.overlay(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.white.opacity(0.3),
                    Color.clear
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: isAnimating ? 200 : -200)
            .mask(self)
        )
    }
}

// MARK: - Timeline Scroll Synchronization

class TimelineScrollSync: ObservableObject {
    @Published var scrollOffset: CGFloat = 0
    @Published var targetDayOffset: Int = 0

    private let dayWidth: CGFloat = 26 // Width of each day column (20pt + 6pt spacing)

    // Convert scroll offset to day offset
    func updateFromScroll(_ offset: CGFloat) {
        scrollOffset = offset
        targetDayOffset = Int(round(offset / dayWidth))
    }

    // Convert day offset to scroll offset
    func scrollPosition(for dayOffset: Int) -> CGFloat {
        CGFloat(dayOffset) * dayWidth
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
