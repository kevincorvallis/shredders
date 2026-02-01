import SwiftUI

/// Real-time conditions tab showing live status and weather alerts
struct ConditionsTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @StateObject private var favoritesManager = FavoritesService.shared

    var body: some View {
        LazyVStack(spacing: .spacingM) {
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Section 1: Live Status Grid (2-column)
                liveStatusSection
                    .transition(.move(edge: .top).combined(with: .opacity))

                // Section 2: Weather Alerts (if active)
                if !viewModel.getActiveAlerts().isEmpty {
                    weatherAlertsSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    noAlertsState
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingL)
    }

    // MARK: - Live Status Section (from NowTabView)

    private var liveStatusSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Live Status")

            let columns = [
                GridItem(.flexible()),
                GridItem(.flexible())
            ]

            LazyVGrid(columns: columns, spacing: .spacingM) {
                ForEach(viewModel.getFavoriteMountains(), id: \.mountain.id) { item in
                    LiveStatusCard(
                        mountain: item.mountain,
                        data: item.data
                    )
                }
            }
        }
    }

    // MARK: - Weather Alerts Section (from NowTabView)

    private var weatherAlertsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            SectionHeaderView(title: "Active Alerts", icon: "exclamationmark.triangle.fill")

            ForEach(viewModel.getActiveAlerts()) { alert in
                WeatherAlertRow(alert: alert)
            }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        TabEmptyStateView(
            icon: "star.slash",
            title: "No Favorites Yet",
            message: "Add mountains to see live status updates"
        )
    }

    private var noAlertsState: some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("No Active Alerts")
                .font(.headline)

            Text("All clear - no weather warnings for your favorites")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingXL)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

// MARK: - Preview

#Preview {
    ConditionsTabView(viewModel: HomeViewModel())
}
