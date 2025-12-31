import SwiftUI

/// Redesigned Mountains tab - Visual grid with sorting/filtering
struct NewMountainsView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var sortBy: SortOption = .distance
    @State private var filterRegion: RegionFilter = .all
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Search and filters
                    VStack(spacing: 12) {
                        // Search bar
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

                        // Filter chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                // Sort options
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

                                // Region filters
                                ForEach(RegionFilter.allCases, id: \.self) { region in
                                    Button {
                                        filterRegion = region
                                    } label: {
                                        FilterChip(
                                            icon: region.icon,
                                            label: region.rawValue,
                                            isActive: filterRegion == region
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal)

                    // Mountains grid
                    if filteredMountains.isEmpty {
                        EmptyStateView(
                            icon: "mountain.2",
                            message: "No mountains found",
                            description: "Try adjusting your filters"
                        )
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredMountains) { mountain in
                                NavigationLink {
                                    MountainDetailView(
                                        mountainId: mountain.id,
                                        mountainName: mountain.name
                                    )
                                } label: {
                                    MountainGridCard(
                                        mountain: mountain,
                                        score: viewModel.getScore(for: mountain),
                                        distance: viewModel.getDistance(to: mountain),
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
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.loadData()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    private var filteredMountains: [Mountain] {
        var mountains = viewModel.mountains

        // Apply region filter
        if filterRegion != .all {
            mountains = mountains.filter { $0.region == filterRegion.regionKey }
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

enum RegionFilter: String, CaseIterable {
    case all = "All"
    case washington = "WA"
    case oregon = "OR"
    case idaho = "ID"
    case canada = "BC"

    var icon: String {
        switch self {
        case .all: return "mountain.2.fill"
        case .washington: return "w.circle.fill"
        case .oregon: return "o.circle.fill"
        case .idaho: return "i.circle.fill"
        case .canada: return "c.circle.fill"
        }
    }

    var regionKey: String? {
        switch self {
        case .all: return nil
        case .washington: return "washington"
        case .oregon: return "oregon"
        case .idaho: return "idaho"
        case .canada: return "canada"
        }
    }
}

// MARK: - Color Extension

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview {
    NewMountainsView()
}
