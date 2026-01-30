import SwiftUI

/// Redesigned Mountains tab - Visual grid with sorting/filtering
struct MountainsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var sortBy: SortOption = .distance
    @State private var filterPass: PassFilter = .all
    @State private var searchText = ""
    @State private var isMapExpanded = false
    @State private var isInitialLoad = true
    @State private var showScrollToTop = false
    @State private var stickyRegions: Set<String> = []
    @Namespace private var heroNamespace

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(spacing: .spacingL) {
                            // Anchor for scroll-to-top
                            Color.clear
                                .frame(height: 1)
                                .id("top")

                            searchAndFiltersSection

                            // Map section
                            MapSectionView(
                                mountains: filteredMountains,
                                scores: mountainScores,
                                isExpanded: $isMapExpanded,
                                onMountainSelected: navigateToMountain
                            )
                            .padding(.horizontal, .spacingL)

                            // Best powder today card
                            bestPowderTodaySection

                            mountainsGridSection
                        }
                        .padding(.vertical, .spacingS)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: ScrollOffsetPreferenceKey.self,
                                        value: geo.frame(in: .named("scroll")).minY
                                    )
                            }
                        )
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showScrollToTop = offset < -300
                        }
                    }

                    // Scroll to top button
                    if showScrollToTop {
                        Button {
                            HapticFeedback.light.trigger()
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                proxy.scrollTo("top", anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.blue))
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, .spacingL)
                        .padding(.bottom, .spacingXL)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticFeedback.selection.trigger()
                        withAnimation(.bouncy) {
                            isMapExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isMapExpanded ? "map.fill" : "map")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel(isMapExpanded ? "Collapse map" : "Expand map")
                }
            }
            .refreshable {
                await viewModel.loadMountains()
            }
            .task {
                await viewModel.loadMountains()
                isInitialLoad = false
            }
        }
    }

    // MARK: - Best Powder Today

    @ViewBuilder
    private var bestPowderTodaySection: some View {
        if let bestMountain = bestPowderMountain {
            NavigationLink {
                MountainDetailView(mountain: bestMountain)
            } label: {
                BestPowderTodayCard(
                    mountain: bestMountain,
                    conditions: viewModel.getConditions(for: bestMountain),
                    powderScore: viewModel.getScore(for: bestMountain).map { Int($0) },
                    arrivalTime: nil, // Will load dynamically
                    parking: nil,
                    viewModel: nil
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    private var bestPowderMountain: Mountain? {
        filteredMountains
            .filter { viewModel.getScore(for: $0) != nil }
            .max { m1, m2 in
                (viewModel.getScore(for: m1) ?? 0) < (viewModel.getScore(for: m2) ?? 0)
            }
    }

    private var searchAndFiltersSection: some View {
        VStack(spacing: .spacingM) {
            searchBar
            filterChipsRow
        }
        .padding(.horizontal, .spacingL)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search mountains...", text: $searchText)
                .textFieldStyle(.plain)

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
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingM) {
                sortMenu

                ForEach(PassFilter.allCases, id: \.self) { passFilter in
                    Button {
                        filterPass = passFilter
                    } label: {
                        FilterChip(
                            icon: passFilter.icon,
                            label: passFilter.rawValue,
                            isActive: filterPass == passFilter
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    HapticFeedback.selection.trigger()
                    sortBy = option
                } label: {
                    Label(
                        option.rawValue,
                        systemImage: sortBy == option ? "checkmark" : ""
                    )
                }
            }
        } label: {
            FilterChip(
                icon: "arrow.up.arrow.down",
                label: sortBy.rawValue,
                isActive: true
            )
        }
    }

    private var mountainsGridSection: some View {
        Group {
            // Show skeletons only if loading AND no mountains yet (partial data shows as soon as mountains load)
            if viewModel.isLoading && viewModel.mountains.isEmpty && isInitialLoad {
                // Show skeletons during initial load
                LazyVStack(spacing: .spacingM) {
                    ForEach(0..<3, id: \.self) { _ in
                        ListItemSkeleton(height: 200)
                    }
                }
                .padding(.horizontal, .spacingL)
            } else if filteredMountains.isEmpty {
                let state = emptyStateMessage
                CardEmptyStateView(
                    icon: state.icon,
                    title: state.message,
                    message: state.description
                )
                .padding(.top, .spacingXXL * 2.5)
            } else {
                mountainsGrid
            }
        }
    }

    private var emptyStateMessage: (icon: String, message: String, description: String) {
        switch filterPass {
        case .epic:
            return ("ticket.fill", "No Epic Pass mountains found", "Stevens Pass and Whistler Blackcomb honor Epic Pass")
        case .ikon:
            return ("star.square.fill", "No Ikon Pass mountains found", "Crystal, Snoqualmie, Bachelor, Schweitzer, Sun Valley, Revelstoke, RED, Cypress, Panorama, and Sun Peaks honor Ikon Pass")
        case .favorites:
            return ("star.fill", "No favorites yet", "Tap the star icon on any mountain to add it to your favorites")
        case .freshPowder:
            return ("snow", "No fresh powder today", "Check back after the next storm for powder days")
        default:
            return ("mountain.2", "No mountains found", "Try adjusting your search or filters")
        }
    }

    private var mountainsGrid: some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(mountainsByRegion, id: \.region) { regionGroup in
                Section {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(regionGroup.mountains.enumerated()), id: \.element.id) { index, mountain in
                            mountainRow(mountain: mountain, index: index)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, .spacingM)
                } header: {
                    RegionSectionHeader(
                        region: regionGroup.region,
                        mountainCount: regionGroup.mountains.count,
                        isSticky: stickyRegions.contains(regionGroup.region)
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: StickyHeaderPreferenceKey.self,
                                    value: [regionGroup.region: geo.frame(in: .global).minY]
                                )
                        }
                    )
                }
            }
        }
        .onPreferenceChange(StickyHeaderPreferenceKey.self) { values in
            let newSticky = Set(values.filter { $0.value <= 100 }.keys)
            if newSticky != stickyRegions {
                withAnimation(.easeOut(duration: 0.15)) {
                    stickyRegions = newSticky
                }
            }
        }
    }

    @ViewBuilder
    private func mountainRow(mountain: Mountain, index: Int) -> some View {
        NavigationLink {
            MountainDetailView(mountain: mountain)
                .zoomNavigationTransition(sourceID: mountain.id, in: heroNamespace)
        } label: {
            MountainCardRow(
                mountain: mountain,
                conditions: viewModel.getConditions(for: mountain),
                powderScore: viewModel.getScore(for: mountain).map { score in
                    MountainPowderScore(
                        mountain: MountainInfo(
                            id: mountain.id,
                            name: mountain.name,
                            shortName: mountain.shortName
                        ),
                        score: score,
                        factors: [],
                        verdict: "",
                        conditions: MountainPowderScore.ScoreConditions(
                            snowfall24h: 0,
                            snowfall48h: 0,
                            temperature: 0,
                            windSpeed: 0,
                            upcomingSnow: 0
                        ),
                        stormInfo: nil,
                        dataAvailable: MountainPowderScore.DataAvailability(
                            snotel: mountain.hasSnotel,
                            noaa: true
                        )
                    )
                },
                isFavorite: favoritesManager.isFavorite(mountain.id),
                onFavoriteToggle: {
                    toggleFavorite(mountain.id)
                }
            )
            .matchedTransitionSourceIfAvailable(id: mountain.id, in: heroNamespace)
        }
        .buttonStyle(.plain)
        .opacity(isInitialLoad ? 0 : 1)
        .offset(y: isInitialLoad ? 20 : 0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.8)
                .delay(Double(index) * 0.05),
            value: isInitialLoad
        )
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.8)
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
                .blur(radius: phase.isIdentity ? 0 : 1)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                HapticFeedback.success.trigger()
                toggleFavorite(mountain.id)
            } label: {
                Label(
                    favoritesManager.isFavorite(mountain.id) ? "Unfavorite" : "Favorite",
                    systemImage: favoritesManager.isFavorite(mountain.id) ? "star.slash" : "star.fill"
                )
            }
            .tint(favoritesManager.isFavorite(mountain.id) ? .orange : .yellow)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: false) {
            if let url = URL(string: mountain.website) {
                Link(destination: url) {
                    Label("Website", systemImage: "safari")
                }
                .tint(.blue)
            }
        }
    }

    private struct RegionGroup: Hashable {
        let region: String
        let mountains: [Mountain]

        func hash(into hasher: inout Hasher) {
            hasher.combine(region)
        }

        static func == (lhs: RegionGroup, rhs: RegionGroup) -> Bool {
            lhs.region == rhs.region
        }
    }

    private var mountainsByRegion: [RegionGroup] {
        let grouped = Dictionary(grouping: filteredMountains) { $0.region }
        return grouped
            .map { RegionGroup(region: $0.key, mountains: $0.value) }
            .sorted { $0.region < $1.region }
    }

    private var filteredMountains: [Mountain] {
        var mountains = viewModel.mountains

        // Apply pass filter
        if filterPass != .all {
            if let passType = filterPass.passTypeKey {
                mountains = mountains.filter {
                    ($0.passType ?? .independent) == passType
                }
            } else if filterPass == .favorites {
                // Filter for favorited mountains only
                mountains = mountains.filter { mountain in
                    favoritesManager.isFavorite(mountain.id)
                }
            } else if filterPass == .freshPowder {
                // Filter for mountains with 6"+ fresh snow in 24h
                mountains = mountains.filter { mountain in
                    guard let conditions = viewModel.getConditions(for: mountain) else { return false }
                    return conditions.snowfall24h >= 6
                }
            } else if filterPass == .alertsActive {
                // TODO: Filter for mountains with active alerts when alerts data is available
                // For now, no filtering applied
            }
        }

        // Apply search
        if !searchText.isEmpty {
            mountains = mountains.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.shortName.localizedCaseInsensitiveContains(searchText) ||
                $0.region.localizedCaseInsensitiveContains(searchText) ||
                ($0.passType?.rawValue ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sort
        mountains = mountains.sorted { m1, m2 in
            switch sortBy {
            case .name:
                return m1.name < m2.name
            case .distance:
                let d1 = viewModel.getDistance(to: m1) ?? Double.infinity
                let d2 = viewModel.getDistance(to: m2) ?? Double.infinity
                return d1 < d2
            case .powderScore:
                let s1 = viewModel.getScore(for: m1) ?? 0
                let s2 = viewModel.getScore(for: m2) ?? 0
                return s1 > s2
            case .favorites:
                let f1 = favoritesManager.isFavorite(m1.id)
                let f2 = favoritesManager.isFavorite(m2.id)
                if f1 != f2 { return f1 }
                return m1.name < m2.name
            }
        }

        return mountains
    }

    private var mountainScores: [String: Double] {
        return Dictionary(uniqueKeysWithValues:
            filteredMountains.compactMap { mountain in
                guard let score = viewModel.getScore(for: mountain) else { return nil }
                return (mountain.id, score)
            }
        )
    }

    private func toggleFavorite(_ mountainId: String) {
        if favoritesManager.isFavorite(mountainId) {
            favoritesManager.remove(mountainId)
        } else {
            _ = favoritesManager.add(mountainId)
        }
    }

    private func navigateToMountain(_ mountain: Mountain) {
        // Navigation is handled automatically via NavigationStack
        // This method exists for future enhancements (e.g., analytics, camera animation)
    }
}

// MARK: - Mountain Grid Card

struct MountainGridCard: View {
    @Environment(\.colorScheme) private var colorScheme

    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header with logo and favorite
            ZStack(alignment: .topTrailing) {
                // Logo background
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 80
                )
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: mountain.color)?.opacity(0.2) ?? .blue.opacity(0.2),
                            Color(hex: mountain.color)?.opacity(0.05) ?? .blue.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                // Favorite button with haptic feedback and bounce animation
                Button {
                    HapticFeedback.medium.trigger()
                    onFavoriteToggle()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundColor(isFavorite ? .yellow : .white)
                        .symbolEffect(.bounce, value: isFavorite)
                        .shadow(radius: 2)
                        .padding(8)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibleButton(
                    label: isFavorite ? "Remove from favorites" : "Add to favorites"
                )
            }

            // Info section
            VStack(alignment: .leading, spacing: 8) {
                // Name
                Text(mountain.shortName)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // Region
                Text(mountain.region.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(.cornerRadiusTiny)

                Spacer()

                // Stats row
                HStack(spacing: .spacingM) {
                    // Powder score
                    if let score = score {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(scoreColor(score))
                                .frame(width: 8, height: 8)

                            Text(String(format: "%.1f", score))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(scoreColor(score))
                        }
                    }

                    Spacer()

                    // Distance
                    if let distance = distance {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)

                            Text("\(Int(distance))mi")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.spacingM)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusHero))
        .adaptiveShadow(colorScheme: colorScheme, radius: 8, y: 4)
        .accessibleCard(
            label: "\(mountain.shortName), \(mountain.region). \(score.map { "Powder score \(String(format: "%.1f", $0))" } ?? "No score available"). \(distance.map { "\(Int($0)) miles away" } ?? "")",
            hint: "Double tap to view mountain details"
        )
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        if score >= 3 { return .orange }
        return .red
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let label: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .symbolRenderingMode(.hierarchical)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(isActive ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background {
            if isActive {
                Capsule().fill(Color.blue)
            } else {
                Capsule().fill(.ultraThinMaterial)
            }
        }
        .adaptiveShadow(colorScheme: colorScheme, radius: isActive ? 4 : 2, y: 2)
        .accessibilityLabel("\(label) filter")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}


// MARK: - Sort and Filter Options

enum SortOption: String, CaseIterable {
    case distance = "Distance"
    case powderScore = "Powder Score"
    case name = "Name"
    case favorites = "Favorites"
}

enum PassFilter: String, CaseIterable {
    case all = "All"
    case epic = "Epic"
    case ikon = "Ikon"
    case favorites = "Favorites"
    case freshPowder = "Fresh Powder"
    case alertsActive = "Alerts"

    var icon: String {
        switch self {
        case .all: return "mountain.2.fill"
        case .epic: return "e.square.fill"
        case .ikon: return "i.square.fill"
        case .favorites: return "star.fill"
        case .freshPowder: return "snow"
        case .alertsActive: return "exclamationmark.triangle.fill"
        }
    }

    var passTypeKey: PassType? {
        switch self {
        case .all: return nil
        case .epic: return .epic
        case .ikon: return .ikon
        case .favorites, .freshPowder, .alertsActive: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    MountainsView()
}
