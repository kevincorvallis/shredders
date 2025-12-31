import SwiftUI

/// OpenSnow-inspired Home view with horizontal snow timeline and sectioned content
struct HomeView: View {
    @State private var viewModel = SingleMountainViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showingMountainPicker = false

    // Get primary favorite (first one) or default to Baker
    private var selectedMountainId: String {
        favoritesManager.favoriteIds.first ?? "baker"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mountain selector header
                    MountainSelectorHeader(
                        mountainName: viewModel.mountain?.name ?? "Loading...",
                        onTap: { showingMountainPicker = true }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    if viewModel.isLoading && viewModel.conditions == nil {
                        ProgressView("Loading...")
                            .padding(.top, 60)
                    } else {
                        // Snow Timeline (OpenSnow-style horizontal scroll)
                        if !viewModel.snowTimelineData.isEmpty {
                            SnowTimelineView(
                                snowData: viewModel.snowTimelineData,
                                liftStatus: viewModel.conditions?.liftStatus
                            )
                            .padding(.horizontal)
                        }

                        // Weather section
                        WeatherSummarySection(conditions: viewModel.conditions)
                            .padding(.horizontal)

                        // Snow Summary section
                        SnowSummarySection(
                            conditions: viewModel.conditions,
                            powderScore: viewModel.powderScore
                        )
                        .padding(.horizontal)

                        // TODO: Road Conditions - Wire up LocationViewModel integration

                        // Quick actions
                        QuickActionsGrid(mountainId: selectedMountainId)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData(for: selectedMountainId)
            }
            .onChange(of: selectedMountainId) { oldValue, newValue in
                Task {
                    await viewModel.loadData(for: newValue)
                }
            }
            .sheet(isPresented: $showingMountainPicker) {
                MountainPickerSheet(
                    selectedMountainId: selectedMountainId,
                    onSelect: { mountainId in
                        // Update favorite to make it primary
                        if !favoritesManager.isFavorite(mountainId) {
                            _ = favoritesManager.add(mountainId)
                        }
                        // Move to first position
                        if let index = favoritesManager.favoriteIds.firstIndex(of: mountainId) {
                            favoritesManager.reorder(from: IndexSet(integer: index), to: 0)
                        }
                        showingMountainPicker = false
                    }
                )
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
