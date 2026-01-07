import SwiftUI

/// Redesigned Mountains tab - Visual grid with sorting/filtering
struct MountainsView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var sortBy: SortOption = .distance
    @State private var filterPass: PassFilter = .all
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick stats dashboard
                    quickStatsDashboard
                        .padding(.horizontal)

                    searchAndFiltersSection

                    // Best powder today card
                    bestPowderTodaySection

                    mountainsGridSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadMountains()
            }
            .task {
                await viewModel.loadMountains()
            }
        }
    }

    // MARK: - Quick Stats Dashboard

    private var quickStatsDashboard: some View {
        QuickStatsDashboard(
            mountains: viewModel.mountains,
            conditionsMap: viewModel.mountainConditions,
            scoresMap: viewModel.mountainScores.mapValues { Int($0) },
            alertsMap: [:] // Will be populated when alerts are loaded
        )
    }

    // MARK: - Best Powder Today

    @ViewBuilder
    private var bestPowderTodaySection: some View {
        if let bestMountain = bestPowderMountain {
            NavigationLink {
                LocationView(mountain: bestMountain)
            } label: {
                BestPowderTodayCard(
                    mountain: bestMountain,
                    conditions: viewModel.getConditions(for: bestMountain),
                    powderScore: viewModel.getScore(for: bestMountain).map { Int($0) },
                    arrivalTime: nil // Will load dynamically
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    private var bestPowderMountain: Mountain? {
        viewModel.mountains
            .filter { viewModel.getScore(for: $0) != nil }
            .max { m1, m2 in
                (viewModel.getScore(for: m1) ?? 0) < (viewModel.getScore(for: m2) ?? 0)
            }
    }

    private var searchAndFiltersSection: some View {
        VStack(spacing: 12) {
            searchBar
            filterChipsRow
        }
        .padding(.horizontal)
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
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
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
            if filteredMountains.isEmpty {
                let state = emptyStateMessage
                EmptyStateView(
                    icon: state.icon,
                    message: state.message,
                    description: state.description
                )
                .padding(.top, 60)
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
            return ("star.square.fill", "No Ikon Pass mountains found", "Crystal, Snoqualmie, Bachelor, and Schweitzer honor Ikon Pass")
        default:
            return ("mountain.2", "No mountains found", "Try adjusting your search or filters")
        }
    }

    private var mountainsGrid: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredMountains) { mountain in
                NavigationLink {
                    LocationView(mountain: mountain)
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
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var filteredMountains: [Mountain] {
        var mountains = viewModel.mountains

        // Apply pass filter
        if filterPass != .all {
            if let passType = filterPass.passTypeKey {
                mountains = mountains.filter {
                    ($0.passType ?? .independent) == passType
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
                $0.shortName.localizedCaseInsensitiveContains(searchText)
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

    private func toggleFavorite(_ mountainId: String) {
        if favoritesManager.isFavorite(mountainId) {
            favoritesManager.remove(mountainId)
        } else {
            _ = favoritesManager.add(mountainId)
        }
    }
}

// MARK: - Mountain Grid Card

struct MountainGridCard: View {
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

                // Favorite button
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title3)
                        .foregroundColor(isFavorite ? .yellow : .white)
                        .shadow(radius: 2)
                        .padding(8)
                }
                .buttonStyle(.plain)
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
                    .cornerRadius(4)

                Spacer()

                // Stats row
                HStack(spacing: 12) {
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
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: 200)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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
    let icon: String
    let label: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)

            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .foregroundColor(isActive ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isActive ? Color.blue : Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

// MARK: - Empty State

struct EmptyStateView: View {
    let icon: String
    let message: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text(message)
                .font(.title3)
                .fontWeight(.semibold)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
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
    case freshPowder = "Fresh Powder"
    case alertsActive = "Alerts"

    var icon: String {
        switch self {
        case .all: return "mountain.2.fill"
        case .epic: return "e.square.fill"
        case .ikon: return "i.square.fill"
        case .freshPowder: return "snow"
        case .alertsActive: return "exclamationmark.triangle.fill"
        }
    }

    var passTypeKey: PassType? {
        switch self {
        case .all: return nil
        case .epic: return .epic
        case .ikon: return .ikon
        case .freshPowder, .alertsActive: return nil
        }
    }
}

// MARK: - Preview

#Preview {
    MountainsView()
}
