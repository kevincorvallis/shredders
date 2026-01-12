//
//  TodayTabView.swift
//  PowderTracker
//
//  Today tab - Current conditions and favorites
//

import SwiftUI

struct TodayTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var isVisible = false
    @State private var showAllFavorites = false

    var body: some View {
        LazyVStack(spacing: .spacingL) {
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Section 1: Best Powder Today (Hero)
                if let best = viewModel.getBestPowderToday() {
                    bestPowderHeroSection(best: best)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
                }

                // Section 2: Quick Comparison Grid
                yourFavoritesSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)

                // Section 3: 7-Day Snow Forecast Chart
                forecastChartSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)

                // Section 4: Mountain Details (Expandable)
                mountainDetailsSection
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isVisible)
            }
        }
        .padding(.spacingL)
        .onAppear {
            isVisible = true
        }
    }

    private func bestPowderHeroSection(best: (mountain: Mountain, score: MountainPowderScore, data: MountainBatchedResponse)) -> some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("Best Powder Today")
                .sectionHeader()
                .padding(.horizontal, .spacingXS)

            BestPowderTodayCard(
                mountain: best.mountain,
                conditions: best.data.conditions,
                powderScore: Int(best.score.score),
                arrivalTime: viewModel.arrivalTimes[best.mountain.id],
                parking: viewModel.parkingPredictions[best.mountain.id],
                viewModel: viewModel
            )
            .accessibilityLabel("Best powder today: \(best.mountain.name) with a score of \(Int(best.score.score)) out of 10")
        }
    }

    private var yourFavoritesSection: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
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
        VStack(alignment: .leading, spacing: .spacingM) {
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
        VStack(alignment: .leading, spacing: .spacingM) {
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showAllFavorites.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: showAllFavorites ? "chevron.up" : "chevron.down")
                            .font(.caption)

                        Text(showAllFavorites ? "Show Less" : "See All (\(favoritesManager.favoriteIds.count))")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()
                    }
                    .foregroundColor(.blue)
                    .padding(.spacingM)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(.cornerRadiusCard)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "star.slash")
                .font(.system(size: 60))
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
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
