import SwiftUI

struct MountainsTabView: View {
    var viewModel: MountainSelectionViewModel
    private var favoritesManager: FavoritesService { FavoritesService.shared }
    @State private var searchText = ""
    @State private var sortBy: MountainSort = .bestConditions

    // Filters
    @State private var filterFreshPowder = false
    @State private var filterOpenOnly = false
    @State private var filterFavoritesOnly = false
    @State private var filterNearby = false
    @State private var filterEpic = false
    @State private var filterIkon = false

    init(viewModel: MountainSelectionViewModel = MountainSelectionViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    mainContent
                } else {
                    searchResultsView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search mountains...")
            .enhancedRefreshable {
                await viewModel.loadMountains()
            }
            .task {
                if viewModel.mountains.isEmpty {
                    await viewModel.loadMountains()
                }
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                sortPicker
                    .padding(.horizontal)

                filterChips
                    .padding(.horizontal)

                if viewModel.isLoading && viewModel.mountains.isEmpty {
                    MountainListSkeleton(itemCount: 6)
                        .padding(.top, 8)
                } else if sortedMountains.isEmpty {
                    emptyState
                } else {
                    ForEach(sortedMountains) { mountain in
                        NavigationLink {
                            MountainDetailView(mountain: mountain)
                        } label: {
                            ConditionMountainCard(
                                mountain: mountain,
                                conditions: viewModel.getConditions(for: mountain),
                                score: viewModel.getScore(for: mountain),
                                distance: viewModel.getDistance(to: mountain),
                                isFavorite: favoritesManager.isFavorite(mountain.id),
                                onFavoriteToggle: { toggleFavorite(mountain.id) }
                            )
                        }
                        .buttonStyle(.plain)
                        .navigationHaptic()
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mountain.2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text(hasActiveFilters ? "No mountains match filters" : "No mountains found")
                .font(.headline)
            if hasActiveFilters {
                Button("Clear Filters") {
                    clearFilters()
                    HapticFeedback.light.trigger()
                }
                .font(.subheadline)
            } else {
                Text("Pull to refresh")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Search

    private var searchResults: [Mountain] {
        viewModel.mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            $0.region.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if searchResults.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No mountains found")
                            .font(.headline)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    Text("\(searchResults.count) results")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    ForEach(searchResults) { mountain in
                        NavigationLink {
                            MountainDetailView(mountain: mountain)
                        } label: {
                            ConditionMountainCard(
                                mountain: mountain,
                                conditions: viewModel.getConditions(for: mountain),
                                score: viewModel.getScore(for: mountain),
                                distance: viewModel.getDistance(to: mountain),
                                isFavorite: favoritesManager.isFavorite(mountain.id),
                                onFavoriteToggle: { toggleFavorite(mountain.id) }
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
    }

    // MARK: - Sort & Filter

    private var sortPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MountainSort.allCases, id: \.self) { sort in
                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            sortBy = sort
                        }
                    } label: {
                        Text(sort.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(sortBy == sort ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(sortBy == sort ? Color.blue : Color(.tertiarySystemBackground))
                            .cornerRadius(.cornerRadiusPill)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var filterChips: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterToggleChip(icon: "snowflake", label: "6\"+ Snow", isActive: filterFreshPowder, activeColor: .cyan) {
                        withAnimation(.spring(response: 0.25)) { filterFreshPowder.toggle() }
                        HapticFeedback.selection.trigger()
                    }
                    .accessibilityIdentifier("mountains_filter_fresh_powder")

                    FilterToggleChip(icon: "checkmark.circle", label: "Open Now", isActive: filterOpenOnly, activeColor: .green) {
                        withAnimation(.spring(response: 0.25)) { filterOpenOnly.toggle() }
                        HapticFeedback.selection.trigger()
                    }
                    .accessibilityIdentifier("mountains_filter_open_only")

                    FilterToggleChip(icon: "star.fill", label: "Favorites", isActive: filterFavoritesOnly, activeColor: .yellow) {
                        withAnimation(.spring(response: 0.25)) { filterFavoritesOnly.toggle() }
                        HapticFeedback.selection.trigger()
                    }
                    .accessibilityIdentifier("mountains_filter_favorites")

                    FilterToggleChip(icon: "location.fill", label: "< 2 hrs", isActive: filterNearby, activeColor: .orange) {
                        withAnimation(.spring(response: 0.25)) { filterNearby.toggle() }
                        HapticFeedback.selection.trigger()
                    }
                    .accessibilityIdentifier("mountains_filter_nearby")

                    FilterToggleChip(icon: "p.circle", label: "Epic", isActive: filterEpic, activeColor: .purple) {
                        withAnimation(.spring(response: 0.25)) {
                            filterEpic.toggle()
                            if filterEpic { filterIkon = false }
                        }
                        HapticFeedback.selection.trigger()
                    }
                    .accessibilityIdentifier("mountains_filter_epic")

                    FilterToggleChip(icon: "i.circle", label: "Ikon", isActive: filterIkon, activeColor: .red) {
                        withAnimation(.spring(response: 0.25)) {
                            filterIkon.toggle()
                            if filterIkon { filterEpic = false }
                        }
                        HapticFeedback.selection.trigger()
                    }
                    .accessibilityIdentifier("mountains_filter_ikon")
                }
            }

            if hasActiveFilters {
                HStack {
                    Text("\(sortedMountains.count) mountains")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        clearFilters()
                        HapticFeedback.light.trigger()
                    } label: {
                        Text("Clear All")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    // MARK: - Data

    private var hasActiveFilters: Bool {
        filterFreshPowder || filterOpenOnly || filterFavoritesOnly || filterNearby || filterEpic || filterIkon
    }

    private var sortedMountains: [Mountain] {
        var mountains = viewModel.mountains

        if filterFreshPowder {
            mountains = mountains.filter {
                (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 6
            }
        }
        if filterOpenOnly {
            mountains = mountains.filter {
                viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
            }
        }
        if filterFavoritesOnly {
            mountains = mountains.filter {
                favoritesManager.isFavorite($0.id)
            }
        }
        if filterNearby {
            mountains = mountains.filter {
                (viewModel.getDistance(to: $0) ?? .infinity) <= 100
            }
        }
        if filterEpic {
            mountains = mountains.filter { $0.passType == .epic }
        }
        if filterIkon {
            mountains = mountains.filter { $0.passType == .ikon }
        }

        switch sortBy {
        case .bestConditions:
            return mountains.sorted { m1, m2 in
                let open1 = viewModel.getConditions(for: m1)?.liftStatus?.isOpen ?? false
                let open2 = viewModel.getConditions(for: m2)?.liftStatus?.isOpen ?? false
                if open1 != open2 { return open1 }
                return (viewModel.getScore(for: m1) ?? 0) > (viewModel.getScore(for: m2) ?? 0)
            }
        case .nearest:
            return mountains.sorted {
                (viewModel.getDistance(to: $0) ?? .infinity) < (viewModel.getDistance(to: $1) ?? .infinity)
            }
        case .mostSnow:
            return mountains.sorted {
                (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) > (viewModel.getConditions(for: $1)?.snowfall24h ?? 0)
            }
        case .openLifts:
            return mountains.sorted {
                (viewModel.getConditions(for: $0)?.liftStatus?.liftsOpen ?? 0) >
                (viewModel.getConditions(for: $1)?.liftStatus?.liftsOpen ?? 0)
            }
        }
    }

    // MARK: - Actions

    private func toggleFavorite(_ id: String) {
        if favoritesManager.isFavorite(id) {
            favoritesManager.remove(id)
        } else {
            _ = favoritesManager.add(id)
        }
    }

    private func clearFilters() {
        withAnimation(.spring(response: 0.25)) {
            filterFreshPowder = false
            filterOpenOnly = false
            filterFavoritesOnly = false
            filterNearby = false
            filterEpic = false
            filterIkon = false
        }
    }
}

// MARK: - Sort Options

enum MountainSort: String, CaseIterable {
    case bestConditions = "Best Conditions"
    case nearest = "Nearest"
    case mostSnow = "Most Snow"
    case openLifts = "Most Lifts Open"
}

// MARK: - Components

struct ConditionMountainCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let score: Double?
    let distance: Double?
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 56
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mountain.shortName)
                        .font(.headline)

                    if let status = conditions?.liftStatus {
                        Text(status.isOpen ? "OPEN" : "CLOSED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(status.isOpen ? Color.green : Color.red.opacity(0.8))
                            .cornerRadius(.cornerRadiusTiny)
                    }
                }

                HStack(spacing: 12) {
                    if let conditions = conditions {
                        Label("\(conditions.snowfall24h)\"", systemImage: "cloud.snow.fill")
                            .font(.caption)
                            .foregroundColor(.blue)

                        if let lifts = conditions.liftStatus {
                            Label("\(lifts.liftsOpen)/\(lifts.liftsTotal)", systemImage: "cablecar.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text(mountain.region.capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let distance = distance {
                        Label("\(Int(distance))mi", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            if let score = score {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", score))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(scoreColor(score))
                    Text("score")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Button(action: onFavoriteToggle) {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .orange
    }
}

struct FilterToggleChip: View {
    let icon: String
    let label: String
    let isActive: Bool
    let activeColor: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isActive ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? activeColor : Color(.tertiarySystemBackground))
            .cornerRadius(.cornerRadiusPill)
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusPill)
                    .stroke(isActive ? activeColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(label) filter")
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview {
    MountainsTabView()
}
