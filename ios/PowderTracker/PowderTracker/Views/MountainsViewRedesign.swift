import SwiftUI
import CoreLocation

// MARK: - Redesigned Mountains View

/// Discovery-focused Mountains tab with smart sections, regions, and visual hierarchy
/// Inspired by Apple's Weather app and App Store design patterns
struct MountainsViewRedesign: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared

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
                    QuickFilterChip(
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
                                    ConditionCard(
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
                                    NearbyCard(
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
                        RegionCard(
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
                                    FavoriteCard(
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
                            CompactMountainRow(
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
            RegionDetailSheet(
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
                        SearchResultRow(
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
                ConditionStat(
                    value: "\(mountainsOpen)",
                    label: "Open",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                Divider()
                    .frame(height: 40)

                ConditionStat(
                    value: avgPowderScore,
                    label: "Avg Score",
                    icon: "star.fill",
                    color: .yellow
                )

                Divider()
                    .frame(height: 40)

                ConditionStat(
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

        // Apply quick filters
        for filter in selectedFilters {
            switch filter {
            case .favorites:
                mountains = mountains.filter { favoritesManager.isFavorite($0.id) }
            case .epic:
                mountains = mountains.filter { $0.passType == .epic }
            case .ikon:
                mountains = mountains.filter { $0.passType == .ikon }
            case .freshPowder:
                mountains = mountains.filter {
                    (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 6
                }
            case .open:
                mountains = mountains.filter {
                    viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
                }
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

// MARK: - Supporting Types

enum QuickFilter: String, CaseIterable {
    case favorites = "Favorites"
    case epic = "Epic"
    case ikon = "Ikon"
    case freshPowder = "Fresh Snow"
    case open = "Open Now"

    var icon: String {
        switch self {
        case .favorites: return "star.fill"
        case .epic: return "e.square.fill"
        case .ikon: return "i.square.fill"
        case .freshPowder: return "snowflake"
        case .open: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .favorites: return .yellow
        case .epic: return .purple
        case .ikon: return .orange
        case .freshPowder: return .blue
        case .open: return .green
        }
    }
}

enum MountainRegion: String, CaseIterable, Identifiable {
    case washington = "washington"
    case oregon = "oregon"
    case idaho = "idaho"
    case britishColumbia = "british columbia"
    case montana = "montana"
    case california = "california"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .washington: return "Washington"
        case .oregon: return "Oregon"
        case .idaho: return "Idaho"
        case .britishColumbia: return "British Columbia"
        case .montana: return "Montana"
        case .california: return "California"
        }
    }

    var icon: String {
        switch self {
        case .washington: return "w.square.fill"
        case .oregon: return "o.square.fill"
        case .idaho: return "i.square.fill"
        case .britishColumbia: return "b.square.fill"
        case .montana: return "m.square.fill"
        case .california: return "c.square.fill"
        }
    }

    var color: Color {
        switch self {
        case .washington: return .blue
        case .oregon: return .green
        case .idaho: return .orange
        case .britishColumbia: return .red
        case .montana: return .purple
        case .california: return .yellow
        }
    }
}

// MARK: - Component Views

struct QuickFilterChip: View {
    let filter: QuickFilter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : filter.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? filter.color : filter.color.opacity(0.15))
            .cornerRadius(.cornerRadiusPill)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct DiscoverySection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)

            content()
        }
    }
}

struct ConditionCard: View {
    let mountain: Mountain
    let score: Double?
    let conditions: MountainConditions?
    let isFavorite: Bool
    let compareMode: Bool
    let isSelectedForComparison: Bool
    let onFavoriteToggle: () -> Void
    let onCompareToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Header
            ZStack(alignment: .topTrailing) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 60
                )
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: mountain.color)?.opacity(0.3) ?? .blue.opacity(0.3),
                            Color(hex: mountain.color)?.opacity(0.1) ?? .blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                if compareMode {
                    Button(action: onCompareToggle) {
                        Image(systemName: isSelectedForComparison ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelectedForComparison ? .blue : .white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                } else {
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(mountain.shortName)
                    .font(.headline)
                    .lineLimit(1)

                if let score = score {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(scoreColor(score))
                            .frame(width: 8, height: 8)
                        Text(String(format: "%.1f", score))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(scoreColor(score))
                    }
                }

                if let conditions = conditions {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.snow.fill")
                            .font(.caption2)
                        Text("\(conditions.snowfall24h)\" 24h")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.bottom, .spacingM)
        }
        .frame(width: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelectedForComparison ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .orange
    }
}

struct NearbyCard: View {
    let mountain: Mountain
    let distance: Double?
    let score: Double?
    let conditions: MountainConditions?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 44
                )

                Spacer()

                if let distance = distance {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text("\(Int(distance)) mi")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(.cornerRadiusButton)
                }
            }

            Text(mountain.shortName)
                .font(.headline)
                .lineLimit(1)

            HStack {
                if let score = score {
                    Text(String(format: "%.1f", score))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
                }

                Spacer()

                if let conditions = conditions {
                    Text("\(conditions.snowfall24h)\" new")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 160)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

struct FavoriteCard: View {
    let mountain: Mountain
    let score: Double?
    let conditions: MountainConditions?

    var body: some View {
        HStack(spacing: .spacingM) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 50
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.headline)

                if let conditions = conditions {
                    Text("\(conditions.snowfall24h)\" 24h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let score = score {
                Text(String(format: "%.1f", score))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

struct RegionCard: View {
    let region: MountainRegion
    let mountainCount: Int
    let topScore: Double?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .spacingS) {
                HStack {
                    Image(systemName: region.icon)
                        .font(.title2)
                        .foregroundColor(region.color)

                    Spacer()

                    if let score = topScore {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f", score))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.yellow)
                    }
                }

                Text(region.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(mountainCount) mountains")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(region.color.opacity(0.1))
            .cornerRadius(.cornerRadiusHero)
        }
        .buttonStyle(.plain)
    }
}

struct CompactMountainRow: View {
    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let conditions: MountainConditions?
    let isFavorite: Bool
    let compareMode: Bool
    let isSelectedForComparison: Bool
    let onFavoriteToggle: () -> Void
    let onCompareToggle: () -> Void

    var body: some View {
        HStack(spacing: .spacingM) {
            if compareMode {
                Button(action: onCompareToggle) {
                    Image(systemName: isSelectedForComparison ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelectedForComparison ? .blue : .secondary)
                }
            }

            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.headline)

                HStack(spacing: .spacingS) {
                    Text(mountain.region.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distance = distance {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(Int(distance)) mi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let score = score {
                    Text(String(format: "%.1f", score))
                        .font(.headline)
                        .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
                }

                if let conditions = conditions, conditions.snowfall24h > 0 {
                    Text("\(conditions.snowfall24h)\"")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if !compareMode {
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelectedForComparison ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct SearchResultRow: View {
    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let searchText: String

    var body: some View {
        HStack(spacing: .spacingM) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.name)
                    .font(.headline)

                Text(mountain.region.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let distance = distance {
                Text("\(Int(distance)) mi")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

struct ConditionStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RegionDetailSheet: View {
    let region: MountainRegion
    let mountains: [Mountain]
    let viewModel: MountainSelectionViewModel
    let favoritesManager: FavoritesManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(mountains) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    HStack {
                        MountainLogoView(
                            logoUrl: mountain.logo,
                            color: mountain.color,
                            size: 40
                        )

                        VStack(alignment: .leading) {
                            Text(mountain.name)
                                .font(.headline)
                            if let score = viewModel.getScore(for: mountain) {
                                Text(String(format: "Score: %.1f", score))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if favoritesManager.isFavorite(mountain.id) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .navigationTitle(region.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#Preview {
    MountainsViewRedesign()
}
