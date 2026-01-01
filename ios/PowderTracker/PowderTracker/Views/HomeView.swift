import SwiftUI

/// OpenSnow-style Favorites view - List of mountains with snow timelines
struct HomeView: View {
    @StateObject private var viewModel = FavoritesViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedFilter: SnowFilter = .snowSummary
    @State private var showingManageFavorites = false
    @State private var timelineOffset: Int = 0 // Synchronized timeline scroll: -7 to +7

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterTabs
                timelineNavigator
                favoritesListView
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

    private var favoritesListView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if favoritesManager.favoriteIds.isEmpty {
                    emptyState
                        .transition(.scale.combined(with: .opacity))
                } else if viewModel.isLoading && viewModel.mountainData.isEmpty {
                    loadingSkeletons
                } else {
                    mountainCardsList
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.mountainData.count)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: favoritesManager.favoriteIds)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var loadingSkeletons: some View {
        ForEach(0..<3, id: \.self) { _ in
            SkeletonMountainCard()
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var mountainCardsList: some View {
        ForEach(favoritesManager.favoriteIds, id: \.self) { mountainId in
            if let mountain = viewModel.mountains.first(where: { $0.id == mountainId }) {
                mountainCardRow(for: mountain, mountainId: mountainId)
            }
        }
    }

    private func mountainCardRow(for mountain: Mountain, mountainId: String) -> some View {
        Group {
            if let data = viewModel.mountainData[mountainId] {
                NavigationLink {
                    MountainDetailView(mountainId: mountainId, mountainName: mountain.name)
                } label: {
                    MountainTimelineCard(
                        mountain: mountain,
                        conditions: data.conditions,
                        powderScore: data.powderScore,
                        forecast: data.forecast,
                        filterMode: selectedFilter,
                        timelineOffset: timelineOffset
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.9).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            } else {
                SkeletonMountainCard()
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var timelineNavigator: some View {
        HStack(spacing: 16) {
            // Previous button
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    timelineOffset = max(-7, timelineOffset - 1)
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Day")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
                .foregroundColor(timelineOffset <= -7 ? .secondary : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .disabled(timelineOffset <= -7)
            .opacity(timelineOffset <= -7 ? 0.5 : 1.0)

            Spacer()

            // Current position indicator
            VStack(spacing: 1) {
                Text(timelineLabel)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text(timelineSubtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )

            Spacer()

            // Next button
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    timelineOffset = min(7, timelineOffset + 1)
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Day")
                        .font(.caption2)
                        .fontWeight(.medium)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(timelineOffset >= 7 ? .secondary : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
            }
            .disabled(timelineOffset >= 7)
            .opacity(timelineOffset >= 7 ? 0.5 : 1.0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }

    private var timelineLabel: String {
        if timelineOffset == 0 {
            return "Today"
        } else if timelineOffset < 0 {
            return "\(abs(timelineOffset)) days ago"
        } else {
            return "\(timelineOffset) days ahead"
        }
    }

    private var timelineSubtitle: String {
        let date = Calendar.current.date(byAdding: .day, value: timelineOffset, to: Date()) ?? Date()
        return date.formatted(.dateTime.month(.abbreviated).day())
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SnowFilter.allCases, id: \.self) { filter in
                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .light)
                        impactMed.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedFilter == filter ? Color.blue : Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .scaleEffect(selectedFilter == filter ? 1.0 : 0.96)
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedFilter)
                }
            }
            .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
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
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .shimmering(isAnimating: isAnimating)

                VStack(alignment: .leading, spacing: 6) {
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.tertiarySystemBackground))

            // Content area
            VStack(spacing: 8) {
                HStack(spacing: 0) {
                    ForEach(0..<3, id: \.self) { _ in
                        VStack(spacing: 4) {
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
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
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

// MARK: - Preview

#Preview {
    HomeView()
}
