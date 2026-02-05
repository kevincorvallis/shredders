import SwiftUI

/// Real-time conditions tab showing live status and weather alerts
struct ConditionsTabView: View {
    var viewModel: HomeViewModel
    @ObservedObject private var favoritesManager = FavoritesService.shared

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
                WeatherAlertRowView(alert: alert)
            }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        BrockEmptyState(
            title: "No Favorites Yet",
            message: "Brock wants to show you live conditions! Add some mountains to track.",
            expression: .curious,
            actionTitle: nil,
            action: nil
        )
    }

    private var noAlertsState: some View {
        VStack(spacing: .spacingM) {
            // Happy Brock with checkmark
            ZStack {
                Circle()
                    .fill(Color.brockGold.opacity(0.2))
                    .frame(width: 80, height: 80)

                Text("🐕")
                    .font(.system(size: 40))

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
                    .offset(x: 25, y: -20)
            }

            Text("All Clear!")
                .font(.headline)

            Text("Brock says no weather alerts for your favorites. Enjoy the slopes!")
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
