import SwiftUI

/// New Today view - the main landing screen for the app
/// Shows today's conditions, recommendations, and quick access to favorites
struct TodayView: View {
    var viewModel: HomeViewModel
    @ObservedObject private var favoritesManager = FavoritesService.shared
    @State private var showingManageFavorites = false
    @State private var showingRegionPicker = false
    @State private var alertsDismissed = false
    @State private var selectedMountain: Mountain? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                AdaptiveContentView(maxWidth: .maxContentWidthFull) {
                    LazyVStack(spacing: .spacingL) {
                        // Alert banner (if alerts exist)
                        alertBanner

                        // Region header
                        regionHeader

                        // Today's Pick card
                        todaysPickSection

                        // Snow Forecast Chart
                        forecastChartSection

                        // Your Mountains grid
                        yourMountainsSection

                        // Webcam strip
                        webcamSection
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingM)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingManageFavorites = true
                    } label: {
                        Image(systemName: "star.circle")
                    }
                    .accessibilityIdentifier("today_manage_favorites_button")
                    .accessibilityLabel("Manage favorites")
                }
            }
            .refreshable {
                await viewModel.refresh()
                await viewModel.loadEnhancedData()
            }
            .task {
                await viewModel.loadData()
                await viewModel.loadEnhancedData()
            }
            .sheet(isPresented: $showingManageFavorites) {
                FavoritesManagementSheet()
            }
            .sheet(item: $selectedMountain) { mountain in
                NavigationStack {
                    MountainDetailView(mountain: mountain)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    selectedMountain = nil
                                }
                            }
                        }
                }
            }
        }
    }

    // MARK: - Alert Banner

    @ViewBuilder
    private var alertBanner: some View {
        let alerts = viewModel.getActiveAlerts()
        if !alerts.isEmpty {
            AlertBannerView(
                alerts: alerts,
                isDismissed: $alertsDismissed
            )
        }
    }

    // MARK: - Region Header

    private var regionHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(currentRegionName)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("\(favoritesManager.favoriteIds.count) mountains tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                showingRegionPicker = true
            } label: {
                Text("Change")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            .accessibilityIdentifier("today_change_region_button")
            .accessibilityLabel("Change region")
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
        .accessibilityElement(children: .combine)
    }

    private var currentRegionName: String {
        // Determine region from favorites
        let regions = favoritesManager.favoriteIds.compactMap { id -> String? in
            viewModel.mountainsById[id]?.region
        }
        let uniqueRegions = Set(regions)

        if uniqueRegions.count == 1, let region = uniqueRegions.first {
            return formatRegionName(region)
        } else if uniqueRegions.count > 1 {
            return "Multiple Regions"
        }
        return "No Region Selected"
    }

    private func formatRegionName(_ region: String) -> String {
        switch region.lowercased() {
        case "washington": return "Washington"
        case "oregon": return "Oregon"
        case "california": return "California"
        case "colorado": return "Colorado"
        case "utah": return "Utah"
        default: return region.capitalized
        }
    }

    // MARK: - Today's Pick Section

    @ViewBuilder
    private var todaysPickSection: some View {
        if let bestPick = viewModel.getBestPowderToday() {
            let reasons = viewModel.getWhyBestReasons(for: bestPick.mountain.id)

            TodaysPickCard(
                mountain: bestPick.mountain,
                powderScore: bestPick.score,
                data: bestPick.data,
                reasons: reasons,
                onTap: {
                    selectedMountain = bestPick.mountain
                }
            )
        } else {
            emptyPickState
        }
    }

    private var emptyPickState: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundColor(.secondary)

            Text("Add favorites to see your pick")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Add Mountains") {
                showingManageFavorites = true
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("today_add_mountains_button")
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingXL)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusHero)
    }

    // MARK: - Forecast Chart Section

    private var forecastChartSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            let favoritesWithForecast = viewModel.getFavoritesWithForecast()

            if !favoritesWithForecast.isEmpty {
                SnowForecastChart(
                    favorites: favoritesWithForecast,
                    showHeader: true
                )
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
            }
        }
    }

    // MARK: - Your Mountains Section

    private var yourMountainsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Your Mountains")

            let favoritesWithData = viewModel.getFavoritesWithData()

            if !favoritesWithData.isEmpty {
                ComparisonGrid(
                    favorites: favoritesWithData,
                    bestMountainId: viewModel.getBestPowderToday()?.mountain.id,
                    viewModel: viewModel,
                    onWebcamTap: { mountain in
                        selectedMountain = mountain
                    }
                )
            } else {
                emptyMountainsState
            }
        }
    }

    private var emptyMountainsState: some View {
        CardEmptyStateView(
            icon: "mountain.2",
            title: "No Mountains Added",
            message: "Add mountains to see conditions"
        )
    }

    // MARK: - Webcam Section

    @ViewBuilder
    private var webcamSection: some View {
        let webcams = viewModel.getAllFavoriteWebcams()

        if !webcams.isEmpty {
            WebcamStrip(
                webcams: webcams,
                onWebcamTap: { mountain, _ in
                    selectedMountain = mountain
                }
            )
            .padding(.horizontal, -.spacingL) // Full-bleed section
        }
    }
}

// MARK: - Preview

#Preview {
    TodayView(viewModel: HomeViewModel())
}
