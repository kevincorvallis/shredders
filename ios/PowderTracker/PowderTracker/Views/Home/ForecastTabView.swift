import SwiftUI

/// Redesigned Forecast-first tab with hero chart and horizontal powder outlook
/// Follows the Phase 4 layout improvements
struct ForecastTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @StateObject private var favoritesManager = FavoritesManager.shared

    var body: some View {
        LazyVStack(spacing: 12) {
            // Section 1: Hero Chart
            heroChartSection

            // Section 2: Quick Stats Row
            quickStatsSection

            // Section 3: Your Mountains (comparison grid)
            comparisonGridSection

            // Section 4: 3-Day Outlook (horizontal scroll)
            powderOutlookSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Hero Chart Section

    private var heroChartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let favoritesWithForecast = viewModel.getFavoritesWithForecast()

            if !favoritesWithForecast.isEmpty {
                // Chart without header - it IS the hero
                SnowForecastChart(favorites: favoritesWithForecast)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusSmall)
                    .accessibilityLabel("7-day snow forecast chart for your favorite mountains")
            } else {
                emptyForecastState
            }
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        let favoritesWithForecast = viewModel.getFavoritesWithForecast()

        // Calculate total snow for next 7 days across all favorites
        let totalSnow = favoritesWithForecast.reduce(0) { total, item in
            let forecastSnow = item.forecast.prefix(7).reduce(0) { $0 + Int($1.snowfall) }
            return max(total, forecastSnow)
        }

        // Find the best day
        let bestDay = findBestDay(from: favoritesWithForecast)

        // Alert count
        let alertCount = viewModel.getActiveAlerts().count

        return QuickStatsRow(
            totalSnow7Day: totalSnow,
            bestDay: bestDay,
            alertCount: alertCount
        )
    }

    private func findBestDay(from favorites: [(mountain: Mountain, forecast: [ForecastDay])]) -> (name: String, snowfall: Int)? {
        var bestDay: (name: String, snowfall: Int)?

        for (_, forecast) in favorites {
            for day in forecast.prefix(7) {
                let snowfall = Int(day.snowfall)
                if snowfall > (bestDay?.snowfall ?? 0) {
                    // Get day name from date
                    let dayName = shortDayName(from: day.date)
                    bestDay = (dayName, snowfall)
                }
            }
        }

        return bestDay
    }

    private func shortDayName(from dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]

        guard let date = formatter.date(from: dateString) else {
            // Try parsing without timezone
            let fallbackFormatter = DateFormatter()
            fallbackFormatter.dateFormat = "yyyy-MM-dd"
            guard let fallbackDate = fallbackFormatter.date(from: String(dateString.prefix(10))) else {
                return "—"
            }
            return formatShortDay(fallbackDate)
        }
        return formatShortDay(date)
    }

    private func formatShortDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // MARK: - Comparison Grid Section

    private var comparisonGridSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(title: "Your Mountains")

            let favoritesWithData = viewModel.getFavoritesWithData()

            if !favoritesWithData.isEmpty {
                ComparisonGrid(
                    favorites: favoritesWithData,
                    bestMountainId: viewModel.getBestPowderToday()?.mountain.id,
                    viewModel: viewModel
                )
            } else {
                emptyComparisonState
            }
        }
    }

    // MARK: - Powder Outlook Section (Horizontal)

    private var powderOutlookSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeaderView(title: "3-Day Outlook")

            // Use forecast data directly instead of powder day plans
            let mountainsWithForecast = favoritesManager.favoriteIds.compactMap { mountainId -> (mountain: Mountain, forecast: [ForecastDay])? in
                guard let mountain = viewModel.mountains.first(where: { $0.id == mountainId }),
                      let data = viewModel.mountainData[mountainId],
                      !data.forecast.isEmpty else {
                    return nil
                }
                return (mountain, data.forecast)
            }

            HorizontalPowderOutlook(mountains: mountainsWithForecast)
        }
    }

    // MARK: - Empty States

    private var emptyForecastState: some View {
        CardEmptyStateView(
            icon: "calendar",
            title: "No Forecast Data",
            message: "Add mountains to your favorites to see forecast"
        )
    }

    private var emptyComparisonState: some View {
        CardEmptyStateView(
            icon: "star",
            title: "No Favorites",
            message: "Add mountains to favorites to compare conditions"
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            ForecastTabView(viewModel: HomeViewModel())
        }
        .background(Color(.systemGroupedBackground))
    }
}
