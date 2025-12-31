import SwiftUI

/// OpenSnow-style Favorites view - List of mountains with snow timelines
struct HomeView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedFilter: SnowFilter = .snowSummary
    @State private var showingManageFavorites = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter tabs (Weather, Snow Summary, Snow Forecast)
                filterTabs

                // Favorites list
                ScrollView {
                    VStack(spacing: 16) {
                        if favoritesManager.favoriteIds.isEmpty {
                            emptyState
                        } else {
                            ForEach(favoritesManager.favoriteIds, id: \.self) { mountainId in
                                if let mountain = viewModel.mountains.first(where: { $0.id == mountainId }),
                                   let data = viewModel.mountainData[mountainId] {
                                    NavigationLink {
                                        MountainDetailView(mountainId: mountainId, mountainName: mountain.name)
                                    } label: {
                                        MountainTimelineCard(
                                            mountain: mountain,
                                            conditions: data.conditions,
                                            powderScore: data.powderScore,
                                            forecast: data.forecast
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingManageFavorites = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingManageFavorites) {
                FavoritesManagementSheet()
            }
        }
    }

    private var filterTabs: some View {
        HStack(spacing: 12) {
            ForEach(SnowFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == filter ? Color.blue : Color(.secondarySystemBackground))
                        .cornerRadius(20)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add mountains to track conditions and snowfall")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingManageFavorites = true
            } label: {
                Text("Add Favorites")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding(.top, 80)
    }
}

// MARK: - Snow Filter Enum

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
    private let favoritesManager = FavoritesManager.shared

    func loadData() async {
        isLoading = true

        // Load mountains list
        do {
            let response = try await apiClient.fetchMountains()
            mountains = response.mountains
        } catch {
            print("Failed to load mountains: \(error)")
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
                        print("Failed to load \(mountainId): \(error)")
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

// MARK: - Favorites Management Sheet

struct FavoritesManagementSheet: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(favoritesManager.favoriteIds, id: \.self) { id in
                        if let mountain = viewModel.mountains.first(where: { $0.id == id }) {
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary)

                                Text(mountain.shortName)

                                Spacer()

                                Button {
                                    favoritesManager.remove(id)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .onMove { source, destination in
                        favoritesManager.reorder(from: source, to: destination)
                    }
                } header: {
                    Text("Favorites (\(favoritesManager.favoriteIds.count)/5)")
                }

                Section("All Mountains") {
                    ForEach(viewModel.mountains.filter { !favoritesManager.isFavorite($0.id) }) { mountain in
                        Button {
                            _ = favoritesManager.add(mountain.id)
                        } label: {
                            HStack {
                                Text(mountain.shortName)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .disabled(favoritesManager.favoriteIds.count >= 5)
                        .opacity(favoritesManager.favoriteIds.count >= 5 ? 0.5 : 1)
                    }
                }
            }
            .navigationTitle("Manage Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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

// MARK: - Mountain Selector Header

struct MountainSelectorHeader: View {
    let mountainName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
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
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Actions Grid

struct QuickActionsGrid: View {
    let mountainId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                NavigationLink {
                    ForecastView()
                } label: {
                    QuickActionCard(
                        icon: "calendar",
                        title: "7-Day Forecast",
                        color: .blue
                    )
                }

                NavigationLink {
                    WebcamsView()
                } label: {
                    QuickActionCard(
                        icon: "video.fill",
                        title: "Webcams",
                        color: .purple
                    )
                }

                NavigationLink {
                    HistoryChartView()
                } label: {
                    QuickActionCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Snow History",
                        color: .green
                    )
                }

                NavigationLink {
                    MountainDetailView(mountainId: mountainId, mountainName: "")
                } label: {
                    QuickActionCard(
                        icon: "info.circle.fill",
                        title: "Full Details",
                        color: .orange
                    )
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
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

                            VStack(alignment: .leading, spacing: 4) {
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
                        .padding(.vertical, 4)
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

    // Mock road conditions - TODO: Wire up real data
    var mockRoadConditions: [RoadCondition] = [
        RoadCondition(
            name: "Main Access Road",
            status: "Open",
            conditions: "Snow and ice, drive carefully",
            chainsRequired: true
        )
    ]

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

// MARK: - Preview

#Preview {
    HomeView()
}
