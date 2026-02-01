import SwiftUI

/// Detailed favorites comparison tab inspired by OpenSnow's Favorites tab
/// Shows complete list of favorite mountains with detailed information
struct FavoritesTabView: View {
    @ObservedObject var viewModel: HomeViewModel
    @StateObject private var favoritesManager = FavoritesService.shared

    var body: some View {
        LazyVStack(spacing: .spacingM) {
            if favoritesManager.favoriteIds.isEmpty {
                emptyState
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                mountainDetailsSection
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingS)
        .padding(.bottom, .spacingL)
    }

    // MARK: - Mountain Details Section (from TodayTabView)

    private var mountainDetailsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Header with count
            HStack {
                SectionHeaderView(title: "All Favorites")

                Spacer()

                Text("\(favoritesManager.favoriteIds.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, .spacingXS / 2)
                    .background(Color.blue)
                    .cornerRadius(.cornerRadiusButton / 2)
            }

            // All favorites (no "See All" toggle - this is a dedicated tab)
            ForEach(favoritesManager.favoriteIds, id: \.self) { mountainId in
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
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        TabEmptyStateView(
            icon: "star.slash",
            title: "No Favorites Yet",
            message: "Add mountains to your favorites to see detailed comparisons"
        ) {
            NavigationLink(destination: Text("Mountains View")) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Favorites")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingM)
                .background(Color.blue)
                .cornerRadius(.cornerRadiusButton)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    FavoritesTabView(viewModel: HomeViewModel())
}
