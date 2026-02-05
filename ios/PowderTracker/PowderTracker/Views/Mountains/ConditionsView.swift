//
//  ConditionsView.swift
//  PowderTracker
//
//  "What's skiing like RIGHT NOW?"
//  Focus: Real-time conditions, what's open, current powder
//
//  Extracted from MountainsTabView.swift for better code organization and
//  improved compilation performance.
//

import SwiftUI

struct ConditionsView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    var favoritesManager: FavoritesService
    @State private var sortBy: ConditionSort = .bestConditions

    // Filter states
    @State private var filterFreshPowder: Bool = false  // 6"+ in 24h
    @State private var filterOpenOnly: Bool = false     // Only open resorts
    @State private var filterFavoritesOnly: Bool = false // Only favorites
    @State private var filterNearby: Bool = false       // Within 100 miles

    enum ConditionSort: String, CaseIterable {
        case bestConditions = "Best Conditions"
        case nearest = "Nearest"
        case mostSnow = "Most Snow"
        case openLifts = "Most Lifts Open"
    }

    private var hasActiveFilters: Bool {
        filterFreshPowder || filterOpenOnly || filterFavoritesOnly || filterNearby
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Quick status header
                statusHeader
                    .padding(.horizontal)

                // Sort picker
                sortPicker
                    .padding(.horizontal)

                // Filter chips
                filterChips
                    .padding(.horizontal)

                // Loading state
                if viewModel.isLoading && viewModel.mountains.isEmpty {
                    BrockLoadingView(.randomBrockMessage)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                } else if sortedMountains.isEmpty {
                    // Empty state with Brock
                    BrockEmptyState(
                        title: "No Mountains Found",
                        message: hasActiveFilters
                            ? "Brock couldn't find any mountains matching your filters. Try adjusting them!"
                            : "Brock is looking for mountains... Pull to refresh!",
                        expression: hasActiveFilters ? .curious : .sleepy,
                        actionTitle: hasActiveFilters ? "Clear Filters" : nil,
                        action: hasActiveFilters ? {
                            filterFreshPowder = false
                            filterOpenOnly = false
                            filterFavoritesOnly = false
                            filterNearby = false
                        } : nil
                    )
                    .padding(.top, 20)
                } else {
                    // Conditions cards
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

    private var statusHeader: some View {
        HStack(spacing: 16) {
            StatusPill(
                value: "\(openMountainsCount)",
                label: openLabel,
                color: openLabel == "Open" ? .green : .gray
            )

            StatusPill(
                value: "\(freshSnowCount)",
                label: "Fresh Snow",
                color: .blue
            )

            StatusPill(
                value: avgScore,
                label: "Avg Score",
                color: .yellow
            )
        }
    }

    private var sortPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ConditionSort.allCases, id: \.self) { sort in
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
                    // Fresh Powder filter
                    FilterToggleChip(
                        icon: "snowflake",
                        label: "6\"+ Snow",
                        isActive: filterFreshPowder,
                        activeColor: .cyan
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            filterFreshPowder.toggle()
                        }
                        HapticFeedback.selection.trigger()
                    }

                    // Open Only filter
                    FilterToggleChip(
                        icon: "checkmark.circle",
                        label: "Open Now",
                        isActive: filterOpenOnly,
                        activeColor: .green
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            filterOpenOnly.toggle()
                        }
                        HapticFeedback.selection.trigger()
                    }

                    // Favorites filter
                    FilterToggleChip(
                        icon: "star.fill",
                        label: "Favorites",
                        isActive: filterFavoritesOnly,
                        activeColor: .yellow
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            filterFavoritesOnly.toggle()
                        }
                        HapticFeedback.selection.trigger()
                    }

                    // Nearby filter
                    FilterToggleChip(
                        icon: "location.fill",
                        label: "< 2 hrs",
                        isActive: filterNearby,
                        activeColor: .orange
                    ) {
                        withAnimation(.spring(response: 0.25)) {
                            filterNearby.toggle()
                        }
                        HapticFeedback.selection.trigger()
                    }
                }
            }

            // Active filters bar
            if hasActiveFilters {
                HStack {
                    Text("\(filteredAndSortedMountains.count) mountains")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.25)) {
                            filterFreshPowder = false
                            filterOpenOnly = false
                            filterFavoritesOnly = false
                            filterNearby = false
                        }
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

    private var filteredAndSortedMountains: [Mountain] {
        var mountains = viewModel.mountains

        // Apply filters
        if filterFreshPowder {
            mountains = mountains.filter { mountain in
                (viewModel.getConditions(for: mountain)?.snowfall24h ?? 0) >= 6
            }
        }

        if filterOpenOnly {
            mountains = mountains.filter { mountain in
                viewModel.getConditions(for: mountain)?.liftStatus?.isOpen ?? false
            }
        }

        if filterFavoritesOnly {
            mountains = mountains.filter { mountain in
                favoritesManager.isFavorite(mountain.id)
            }
        }

        if filterNearby {
            // Filter to mountains within ~100 miles (roughly 2 hours drive)
            mountains = mountains.filter { mountain in
                (viewModel.getDistance(to: mountain) ?? .infinity) <= 100
            }
        }

        // Apply sorting
        switch sortBy {
        case .bestConditions:
            // Sort by score, with open mountains prioritized
            return mountains.sorted { m1, m2 in
                let open1 = viewModel.getConditions(for: m1)?.liftStatus?.isOpen ?? false
                let open2 = viewModel.getConditions(for: m2)?.liftStatus?.isOpen ?? false
                if open1 != open2 { return open1 }
                return (viewModel.getScore(for: m1) ?? 0) > (viewModel.getScore(for: m2) ?? 0)
            }
        case .nearest:
            return mountains.sorted { (viewModel.getDistance(to: $0) ?? .infinity) < (viewModel.getDistance(to: $1) ?? .infinity) }
        case .mostSnow:
            return mountains.sorted { (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) > (viewModel.getConditions(for: $1)?.snowfall24h ?? 0) }
        case .openLifts:
            return mountains.sorted {
                (viewModel.getConditions(for: $0)?.liftStatus?.liftsOpen ?? 0) >
                (viewModel.getConditions(for: $1)?.liftStatus?.liftsOpen ?? 0)
            }
        }
    }

    // Keep old name as alias for compatibility
    private var sortedMountains: [Mountain] {
        filteredAndSortedMountains
    }

    private var openMountainsCount: Int {
        let openCount = viewModel.mountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }.count
        // If no mountains are open, show total count
        return openCount > 0 ? openCount : viewModel.mountains.count
    }

    private var openLabel: String {
        let openCount = viewModel.mountains.filter {
            viewModel.getConditions(for: $0)?.liftStatus?.isOpen ?? false
        }.count
        return openCount > 0 ? "Open" : "Total"
    }

    private var freshSnowCount: Int {
        viewModel.mountains.filter {
            (viewModel.getConditions(for: $0)?.snowfall24h ?? 0) >= 3
        }.count
    }

    private var avgScore: String {
        let scores = viewModel.mountains.compactMap { viewModel.getScore(for: $0) }
        guard !scores.isEmpty else { return "--" }
        return String(format: "%.1f", scores.reduce(0, +) / Double(scores.count))
    }

    private func toggleFavorite(_ id: String) {
        if favoritesManager.isFavorite(id) {
            favoritesManager.remove(id)
        } else {
            _ = favoritesManager.add(id)
        }
    }
}
