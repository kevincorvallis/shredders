//
//  TodayTabView.swift
//  PowderTracker
//
//  Today tab - Current conditions and favorites
//

import SwiftUI

struct TodayTabView: View {
    var viewModel: HomeViewModel
    @StateObject private var favoritesManager = FavoritesService.shared
    @State private var isVisible = false
    @State private var showAllFavorites = false

    var body: some View {
        LazyVStack(spacing: .spacingM) {
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Section 1: Quick Comparison Grid
                yourFavoritesSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.smooth.delay(0.1), value: isVisible)

                // Section 2: 7-Day Snow Forecast Chart
                forecastChartSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.smooth.delay(0.2), value: isVisible)

                // Section 3: Mountain Details (Expandable)
                mountainDetailsSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.smooth.delay(0.3), value: isVisible)
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingL)
        .onAppear {
            isVisible = true
        }
    }

    private var yourFavoritesSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("Quick Comparison")
                .sectionHeader()
                .padding(.horizontal, .spacingXS)

            // Comparison Grid - shows all favorites at once
            let favoritesWithData = favoritesManager.favoriteIds.compactMap { mountainId -> (Mountain, MountainBatchedResponse)? in
                guard let mountain = viewModel.mountains.first(where: { $0.id == mountainId }),
                      let data = viewModel.mountainData[mountainId] else {
                    return nil
                }
                return (mountain, data)
            }

            ComparisonGrid(
                favorites: favoritesWithData,
                bestMountainId: viewModel.getBestPowderToday()?.mountain.id,
                viewModel: viewModel
            )
        }
    }

    private var forecastChartSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            let favoritesWithForecast = favoritesManager.favoriteIds.compactMap { mountainId -> (Mountain, [ForecastDay])? in
                guard let mountain = viewModel.mountains.first(where: { $0.id == mountainId }),
                      let data = viewModel.mountainData[mountainId] else {
                    return nil
                }
                return (mountain, data.forecast)
            }

            SnowForecastChart(favorites: favoritesWithForecast)
                .padding(.spacingM)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard)
                .accessibilityLabel("7-day snow forecast chart for your favorite mountains")
        }
    }

    private var mountainDetailsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("All Favorites")
                .sectionHeader()
                .padding(.horizontal, .spacingXS)

            let displayedFavorites = showAllFavorites ? favoritesManager.favoriteIds : Array(favoritesManager.favoriteIds.prefix(3))

            ForEach(displayedFavorites, id: \.self) { mountainId in
                if let mountain = viewModel.mountains.first(where: { $0.id == mountainId }),
                   let data = viewModel.mountainData[mountainId] {
                    MountainDetailRow(
                        mountain: mountain,
                        data: data,
                        powderScore: data.powderScore,
                        trend: viewModel.getSnowTrend(for: mountainId),
                        viewModel: viewModel
                    )
                }
            }

            // Show "See All" button if there are more than 3 favorites
            if favoritesManager.favoriteIds.count > 3 {
                Button {
                    HapticFeedback.selection.trigger()
                    withAnimation(.bouncy) {
                        showAllFavorites.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showAllFavorites ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)

                        Text(showAllFavorites ? "Show Less" : "See All (\(favoritesManager.favoriteIds.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()
                    }
                    .foregroundColor(.blue)
                    .padding(.spacingM)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(showAllFavorites ? "Show fewer favorites" : "Show all \(favoritesManager.favoriteIds.count) favorites")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)

            Text("No Favorites Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add mountains to track conditions and snowfall")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No favorites yet. Add mountains to track conditions and snowfall.")
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
