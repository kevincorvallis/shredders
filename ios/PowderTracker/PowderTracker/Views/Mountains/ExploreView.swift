//
//  ExploreView.swift
//  PowderTracker
//
//  "What mountains exist? Find something new"
//  Focus: Discovery, regions, terrain types
//
//  Extracted from MountainsTabView.swift for better code organization and
//  improved compilation performance.
//

import SwiftUI

struct ExploreView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesService
    @State private var searchText = ""
    @State private var selectedRegion: ExploreRegion?
    @State private var selectedCategory: ExploreCategory?

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Search
                searchBar
                    .padding(.horizontal)

                if searchText.isEmpty {
                    // Browse by Region
                    regionSection

                    // Categories
                    categoriesSection

                    // All Mountains A-Z
                    allMountainsSection
                } else {
                    // Search results
                    searchResultsSection
                }

                Spacer(minLength: 50)
            }
            .padding(.top)
        }
        .sheet(item: $selectedRegion) { region in
            RegionSheet(
                region: region,
                mountains: mountainsInRegion(region),
                viewModel: viewModel,
                favoritesManager: favoritesManager
            )
            .modernSheet(detents: [.medium, .large])
        }
        .sheet(item: $selectedCategory) { category in
            CategorySheet(
                category: category,
                mountains: mountainsForCategory(category),
                viewModel: viewModel,
                favoritesManager: favoritesManager
            )
            .modernSheet(detents: [.medium, .large])
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search mountains, regions...", text: $searchText)
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
        .cornerRadius(.cornerRadiusCard)
    }

    private var regionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MountainsTabSectionHeader(title: "Browse by Region", icon: "map.fill")
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ExploreRegion.allCases, id: \.self) { region in
                        RegionTile(
                            region: region,
                            count: mountainsInRegion(region).count,
                            onTap: { selectedRegion = region }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MountainsTabSectionHeader(title: "Quick Filters", icon: "square.grid.2x2.fill")
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                CategoryTile(
                    title: "Fresh Powder",
                    subtitle: "6\"+ in 24 hours",
                    icon: "snowflake",
                    color: .cyan,
                    count: freshPowderMountains.count,
                    onTap: { selectedCategory = .freshPowder }
                )

                CategoryTile(
                    title: "Best Scores",
                    subtitle: "Powder score 7+",
                    icon: "star.fill",
                    color: .yellow,
                    count: bestScoreMountains.count,
                    onTap: { selectedCategory = .bestScores }
                )

                CategoryTile(
                    title: "Open Now",
                    subtitle: "Lifts spinning",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    count: openMountains.count,
                    onTap: { selectedCategory = .openNow }
                )

                CategoryTile(
                    title: "Your Favorites",
                    subtitle: "Mountains you love",
                    icon: "heart.fill",
                    color: .pink,
                    count: favoriteMountains.count,
                    onTap: { selectedCategory = .favorites }
                )
            }
            .padding(.horizontal)
        }
    }

    private var allMountainsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MountainsTabSectionHeader(title: "All Mountains", icon: "mountain.2.fill")
                .padding(.horizontal)

            ForEach(viewModel.mountains.sorted { $0.name < $1.name }) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    ExploreRow(
                        mountain: mountain,
                        isFavorite: favoritesManager.isFavorite(mountain.id)
                    )
                }
                .buttonStyle(.plain)
                .navigationHaptic()
                .padding(.horizontal)
            }
        }
    }

    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if searchResults.isEmpty {
                // Empty search state with suggestions
                emptySearchSuggestions
            } else {
                Text("\(searchResults.count) results")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                ForEach(searchResults) { mountain in
                    NavigationLink {
                        MountainDetailView(mountain: mountain)
                    } label: {
                        ExploreRow(
                            mountain: mountain,
                            isFavorite: favoritesManager.isFavorite(mountain.id)
                        )
                    }
                    .buttonStyle(.plain)
                    .navigationHaptic()
                    .padding(.horizontal)
                }
            }
        }
    }

    private var emptySearchSuggestions: some View {
        VStack(spacing: 20) {
            // Empty state icon
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
                .symbolEffect(.pulse.byLayer, options: .repeating)

            VStack(spacing: 4) {
                Text("No mountains found")
                    .font(.headline)
                Text("Try one of these suggestions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Suggested actions
            VStack(spacing: 12) {
                // Popular search suggestions
                HStack(spacing: 8) {
                    ForEach(["Baker", "Crystal", "Stevens"], id: \.self) { suggestion in
                        Button {
                            searchText = suggestion
                            HapticFeedback.light.trigger()
                        } label: {
                            Text(suggestion)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()
                    .padding(.vertical, 8)

                // Action buttons
                VStack(spacing: 8) {
                    Button {
                        searchText = ""
                        HapticFeedback.light.trigger()
                    } label: {
                        Label("Clear search", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.secondary.opacity(0.3))

                    Button {
                        selectedRegion = ExploreRegion.allCases.first
                        searchText = ""
                        HapticFeedback.light.trigger()
                    } label: {
                        Label("Browse by region", systemImage: "map")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.top, 40)
    }

    private var searchResults: [Mountain] {
        viewModel.mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText) ||
            $0.region.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func mountainsInRegion(_ region: ExploreRegion) -> [Mountain] {
        viewModel.mountains.filter {
            $0.region.lowercased().contains(region.searchKey.lowercased())
        }
    }

    // Category filters with real logic
    private var freshPowderMountains: [Mountain] {
        viewModel.mountains.filter { mountain in
            (viewModel.getConditions(for: mountain)?.snowfall24h ?? 0) >= 6
        }
    }

    private var bestScoreMountains: [Mountain] {
        viewModel.mountains.filter { mountain in
            (viewModel.getScore(for: mountain) ?? 0) >= 7
        }
    }

    private var openMountains: [Mountain] {
        viewModel.mountains.filter { mountain in
            viewModel.getConditions(for: mountain)?.liftStatus?.isOpen ?? false
        }
    }

    private var favoriteMountains: [Mountain] {
        viewModel.mountains.filter { mountain in
            favoritesManager.isFavorite(mountain.id)
        }
    }

    private func mountainsForCategory(_ category: ExploreCategory) -> [Mountain] {
        switch category {
        case .freshPowder:
            return freshPowderMountains.sorted {
                (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >
                (viewModel.getConditions(for: $1)?.snowfall24h ?? 0)
            }
        case .bestScores:
            return bestScoreMountains.sorted {
                (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0)
            }
        case .openNow:
            return openMountains.sorted {
                (viewModel.getScore(for: $0) ?? 0) > (viewModel.getScore(for: $1) ?? 0)
            }
        case .favorites:
            return favoriteMountains.sorted { $0.name < $1.name }
        }
    }
}
