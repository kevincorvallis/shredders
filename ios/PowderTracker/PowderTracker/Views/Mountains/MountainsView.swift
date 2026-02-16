import SwiftUI
import CoreLocation

// MARK: - Redesigned Mountains View

/// Discovery-focused Mountains tab with smart sections, regions, and visual hierarchy
/// Inspired by Apple's Weather app and App Store design patterns
struct MountainsView: View {
    @State private var viewModel = MountainSelectionViewModel()
    @ObservedObject private var favoritesManager = FavoritesService.shared

    @State private var searchText = ""
    @State private var isSearching = false
    @State private var selectedRegion: MountainRegion?
    @State private var viewMode: ViewMode = .discover
    @State private var showFilters = false
    @State private var selectedFilters: Set<QuickFilter> = []
    @State private var compareMode = false
    @State private var selectedForComparison: Set<String> = []

    @Namespace private var namespace

    enum ViewMode: String, CaseIterable {
        case discover = "Discover"
        case list = "List"
        case map = "Map"

        var icon: String {
            switch self {
            case .discover: return "sparkles"
            case .list: return "list.bullet"
            case .map: return "map"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Search header
                        searchSection
                            .padding(.horizontal)
                            .padding(.bottom, .spacingM)

                        if isSearching && !searchText.isEmpty {
                            searchResultsView
                        } else {
                            mainContentView
                        }
                    }
                }
                .refreshable {
                    await viewModel.loadMountains()
                }

                // Comparison bar
                if compareMode && !selectedForComparison.isEmpty {
                    comparisonBar
                }
            }
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("View", selection: $viewMode) {
                            ForEach(ViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode.icon)
                            }
                        }

                        Divider()

                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                compareMode.toggle()
                                if !compareMode {
                                    selectedForComparison.removeAll()
                                }
                            }
                        } label: {
                            Label(
                                compareMode ? "Exit Compare" : "Compare Mountains",
                                systemImage: compareMode ? "xmark.circle" : "square.on.square"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                    }
                }
            }
            .task {
                await viewModel.loadMountains()
            }
        }
    }

    // MARK: - Search Section

    private var searchSection: some View {
        VStack(spacing: .spacingM) {
            // Search bar
            HStack(spacing: .spacingM) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search mountains, regions...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                isSearching = true
                            }
                        }

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)

                if isSearching {
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.3)) {
                            isSearching = false
                            searchText = ""
                        }
                    }
                    .foregroundColor(.blue)
                }
            }

            // Quick filters
            if !isSearching {
                quickFiltersRow
            }
        }
    }

    private var quickFiltersRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingS) {
                ForEach(QuickFilter.allCases, id: \.self) { filter in
                    QuickFilterChipView(
                        filter: filter,
                        isSelected: selectedFilters.contains(filter),
                        onTap: {
                            withAnimation(.spring(response: 0.25)) {
                                if selectedFilters.contains(filter) {
                                    selectedFilters.remove(filter)
                                } else {
                                    selectedFilters.insert(filter)
                                }
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContentView: some View {
        switch viewMode {
        case .discover:
            discoverView
        case .list:
            listView
        case .map:
            mapView
        }
    }

    // MARK: - Discover View

    private var discoverView: some View {
        LazyVStack(spacing: .spacingXL) {
            // Conditions Summary Card
            conditionsSummaryCard
                .padding(.horizontal)

            // Best Conditions Now
            if !bestConditionsMountains.isEmpty {
                DiscoverySection(
                    title: "Best Conditions Now",
                    subtitle: "Top powder scores today",
                    icon: "sparkles",
                    iconColor: .yellow
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacingM) {
                            ForEach(bestConditionsMountains.prefix(5)) { mountain in
                                NavigationLink {
                                    MountainDetailView(mountain: mountain)
                                } label: {
                                    ConditionCardView(
                                        mountain: mountain,
                                        score: viewModel.getScore(for: mountain),
                                        conditions: viewModel.getConditions(for: mountain),
                                        isFavorite: favoritesManager.isFavorite(mountain.id),
                                        compareMode: compareMode,
                                        isSelectedForComparison: selectedForComparison.contains(mountain.id),
                                        onFavoriteToggle: { toggleFavorite(mountain.id) },
                                        onCompareToggle: { toggleComparison(mountain.id) }
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Nearest to You
            if !nearestMountains.isEmpty {
                DiscoverySection(
                    title: "Nearest to You",
                    subtitle: "Quick day trips",
                    icon: "location.fill",
                    iconColor: .blue
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacingM) {
                            ForEach(nearestMountains.prefix(5)) { mountain in
                                NavigationLink {
                                    MountainDetailView(mountain: mountain)
                                } label: {
                                    NearbyCardView(
                                        mountain: mountain,
                                        distance: viewModel.getDistance(to: mountain),
                                        score: viewModel.getScore(for: mountain),
                                        conditions: viewModel.getConditions(for: mountain)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // Browse by Region
            DiscoverySection(
                title: "Browse by Region",
                subtitle: "Explore mountains by area",
                icon: "map.fill",
                iconColor: .green
            ) {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: .spacingM) {
                    ForEach(MountainRegion.allCases, id: \.self) { region in
                        RegionCardView(
                            region: region,
                            mountainCount: mountainsInRegion(region).count,
                            topScore: topScoreInRegion(region),
                            onTap: {
                                selectedRegion = region
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Your Favorites
            if !favoriteMountains.isEmpty {
                DiscoverySection(
                    title: "Your Favorites",
                    subtitle: "Quick access to your mountains",
                    icon: "star.fill",
                    iconColor: .yellow
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacingM) {
                            ForEach(favoriteMountains) { mountain in
                                NavigationLink {
                                    MountainDetailView(mountain: mountain)
                                } label: {
                                    FavoriteCardView(
                                        mountain: mountain,
                                        score: viewModel.getScore(for: mountain),
                                        conditions: viewModel.getConditions(for: mountain)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }

            // All Mountains
            DiscoverySection(
                title: "All Mountains",
                subtitle: "\(filteredMountains.count) resorts",
                icon: "mountain.2.fill",
                iconColor: .purple
            ) {
                LazyVStack(spacing: .spacingM) {
                    ForEach(filteredMountains) { mountain in
                        NavigationLink {
                            MountainDetailView(mountain: mountain)
                        } label: {
                            CompactMountainRowView(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                distance: viewModel.getDistance(to: mountain),
                                conditions: viewModel.getConditions(for: mountain),
                                isFavorite: favoritesManager.isFavorite(mountain.id),
                                compareMode: compareMode,
                                isSelectedForComparison: selectedForComparison.contains(mountain.id),
                                onFavoriteToggle: { toggleFavorite(mountain.id) },
                                onCompareToggle: { toggleComparison(mountain.id) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            Spacer(minLength: 100)
        }
        .sheet(item: $selectedRegion) { region in
            RegionDetailSheetView(
                region: region,
                mountains: mountainsInRegion(region),
                viewModel: viewModel,
                favoritesManager: favoritesManager
            )
        }
    }

    // MARK: - List View

    private var listView: some View {
        LazyVStack(spacing: .spacingM) {
            ForEach(filteredMountains) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    MountainCardRow(
                        mountain: mountain,
                        conditions: viewModel.getConditions(for: mountain),
                        powderScore: viewModel.getScore(for: mountain).map { score in
                            MountainPowderScore(
                                mountain: MountainInfo(id: mountain.id, name: mountain.name, shortName: mountain.shortName),
                                score: score,
                                factors: [],
                                verdict: "",
                                conditions: MountainPowderScore.ScoreConditions(snowfall24h: 0, snowfall48h: 0, temperature: 0, windSpeed: 0, upcomingSnow: 0),
                                stormInfo: nil,
                                dataAvailable: MountainPowderScore.DataAvailability(snotel: mountain.hasSnotel, noaa: true)
                            )
                        },
                        isFavorite: favoritesManager.isFavorite(mountain.id),
                        onFavoriteToggle: { toggleFavorite(mountain.id) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Map View

    private var mapView: some View {
        MapSectionView(
            mountains: filteredMountains,
            scores: mountainScores,
            isExpanded: .constant(true),
            onMountainSelected: { _ in }
        )
        .frame(height: UIScreen.main.bounds.height * 0.7)
        .padding(.horizontal)
    }

    // MARK: - Search Results

    private var searchResultsView: some View {
        LazyVStack(spacing: .spacingM) {
            if searchResults.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different search term")
                )
                .padding(.top, 60)
            } else {
                ForEach(searchResults) { mountain in
                    NavigationLink {
                        MountainDetailView(mountain: mountain)
                    } label: {
                        SearchResultRowView(
                            mountain: mountain,
                            score: viewModel.getScore(for: mountain),
                            distance: viewModel.getDistance(to: mountain),
                            searchText: searchText
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Conditions Summary Card

    private var conditionsSummaryCard: some View {
        VStack(spacing: .spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Conditions")
                        .font(.headline)
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Overall condition indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text(overallConditionText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(overallConditionColor)
                    Text("\(mountainsWithFreshSnow) with fresh snow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Quick stats
            HStack(spacing: 0) {
                ConditionStatView(
                    value: "\(mountainsOpen)",
                    label: "Open",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                ConditionStatView(
                    value: avgPowderScore,
                    label: "Avg Score",
                    icon: "star.fill",
                    color: .yellow
                )

                Divider()
                    .frame(height: 40)

                ConditionStatView(
                    value: "\(totalFreshSnow)\"",
                    label: "Max 24h",
                    icon: "cloud.snow.fill",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
    }

    // MARK: - Comparison Bar

    private var comparisonBar: some View {
        VStack {
            Spacer()

            HStack {
                // Selected mountains
                HStack(spacing: -8) {
                    ForEach(Array(selectedForComparison.prefix(3)), id: \.self) { id in
                        if let mountain = viewModel.mountains.first(where: { $0.id == id }) {
                            MountainLogoView(
                                logoUrl: mountain.logo,
                                color: mountain.color,
                                size: 36
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color(.systemBackground), lineWidth: 2)
                            )
                        }
                    }
                }

                Text("\(selectedForComparison.count) selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Compare") {
                    // TODO: Open comparison view
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedForComparison.count < 2)

                Button {
                    withAnimation {
                        selectedForComparison.removeAll()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(.cornerRadiusHero)
            .padding()
            .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        }
    }

    // MARK: - Computed Properties

    private var filteredMountains: [Mountain] {
        var mountains = viewModel.mountains

        // Apply quick filters — pass types use OR logic, others use AND
        let passFilters = selectedFilters.intersection([.epic, .ikon])
        let otherFilters = selectedFilters.subtracting(passFilters)

        // OR: show mountains matching ANY selected pass type
        if !passFilters.isEmpty {
            let passTypes: Set<PassType> = Set(passFilters.compactMap { filter -> PassType? in
                switch filter {
                case .epic: return .epic
                case .ikon: return .ikon
                default: return nil
                }
            })
            mountains = mountains.filter { mountain in
                guard let pt = mountain.passType else { return false }
                return passTypes.contains(pt)
            }
        }

        // AND: each remaining filter further narrows the list
        for filter in otherFilters {
            switch filter {
            case .favorites:
                mountains = mountains.filter { favoritesManager.isFavorite($0.id) }
            case .freshPowder:
                mountains = mountains.filter {
                    (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 6
                }
            case .open:
                mountains = mountains.filter {
                    viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
                }
            default:
                break // pass types already handled above
            }
        }

        return mountains.sorted { m1, m2 in
            let s1 = viewModel.getScore(for: m1) ?? 0
            let s2 = viewModel.getScore(for: m2) ?? 0
            return s1 > s2
        }
    }

    private var searchResults: [Mountain] {
        guard !searchText.isEmpty else { return [] }
        return viewModel.mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            $0.region.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var bestConditionsMountains: [Mountain] {
        viewModel.mountains
            .filter { viewModel.getScore(for: $0) != nil }
            .sorted { (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0) }
    }

    private var nearestMountains: [Mountain] {
        viewModel.mountains
            .filter { viewModel.getDistance(to: $0) != nil }
            .sorted { (viewModel.getDistance(to: $0) ?? .infinity) < (viewModel.getDistance(to: $1) ?? .infinity) }
    }

    private var favoriteMountains: [Mountain] {
        viewModel.mountains.filter { favoritesManager.isFavorite($0.id) }
    }

    private var mountainScores: [String: Double] {
        Dictionary(uniqueKeysWithValues:
            viewModel.mountains.compactMap { mountain in
                guard let score = viewModel.getScore(for: mountain) else { return nil }
                return (mountain.id, score)
            }
        )
    }

    private var mountainsWithFreshSnow: Int {
        viewModel.mountains.filter {
            (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 1
        }.count
    }

    private var mountainsOpen: Int {
        viewModel.mountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }.count
    }

    private var avgPowderScore: String {
        let scores = viewModel.mountains.compactMap { viewModel.getScore(for: $0) }
        guard !scores.isEmpty else { return "--" }
        let avg = scores.reduce(0, +) / Double(scores.count)
        return String(format: "%.1f", avg)
    }

    private var totalFreshSnow: Int {
        viewModel.mountains.compactMap { viewModel.getConditions(for: $0)?.snowfall24h }
            .max() ?? 0
    }

    private var overallConditionText: String {
        let avgScore = viewModel.mountains.compactMap { viewModel.getScore(for: $0) }
            .reduce(0, +) / max(1, Double(viewModel.mountains.count))
        if avgScore >= 7 { return "Excellent" }
        if avgScore >= 5 { return "Good" }
        if avgScore >= 3 { return "Fair" }
        return "Variable"
    }

    private var overallConditionColor: Color {
        let avgScore = viewModel.mountains.compactMap { viewModel.getScore(for: $0) }
            .reduce(0, +) / max(1, Double(viewModel.mountains.count))
        if avgScore >= 7 { return .green }
        if avgScore >= 5 { return .yellow }
        if avgScore >= 3 { return .orange }
        return .red
    }

    // MARK: - Helpers

    private func mountainsInRegion(_ region: MountainRegion) -> [Mountain] {
        viewModel.mountains.filter { $0.region.lowercased() == region.rawValue.lowercased() }
    }

    private func topScoreInRegion(_ region: MountainRegion) -> Double? {
        mountainsInRegion(region)
            .compactMap { viewModel.getScore(for: $0) }
            .max()
    }

    private func toggleFavorite(_ id: String) {
        if favoritesManager.isFavorite(id) {
            favoritesManager.remove(id)
        } else {
            _ = favoritesManager.add(id)
        }
    }

    private func toggleComparison(_ id: String) {
        if selectedForComparison.contains(id) {
            selectedForComparison.remove(id)
        } else if selectedForComparison.count < 3 {
            selectedForComparison.insert(id)
        }
    }
}

// MARK: - Preview

#Preview {
    MountainsView()
}
