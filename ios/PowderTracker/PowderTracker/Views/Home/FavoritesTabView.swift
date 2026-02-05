import SwiftUI

/// Detailed favorites comparison tab inspired by OpenSnow's Favorites tab
/// Shows complete list of favorite mountains with detailed information
struct FavoritesTabView: View {
    var viewModel: HomeViewModel
    @ObservedObject private var favoritesService = FavoritesService.shared

    var body: some View {
        LazyVStack(spacing: .spacingM) {
            if favoritesService.favoriteIds.isEmpty {
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

                Text("\(favoritesService.favoriteIds.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, .spacingXS / 2)
                    .background(Color.blue)
                    .cornerRadius(.cornerRadiusButton / 2)
            }

            // All favorites (no "See All" toggle - this is a dedicated tab)
            ForEach(favoritesService.favoriteIds, id: \.self) { mountainId in
                if let mountain = viewModel.mountainsById[mountainId],
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
        BrockEmptyState(
            title: "No Favorites Yet",
            message: "Brock wants to help you track your favorite mountains! Add some to compare conditions.",
            expression: .curious,
            actionTitle: "Sniff Out Mountains",
            action: nil // Navigation handled by parent
        )
    }
}

// MARK: - Preview

#Preview {
    FavoritesTabView(viewModel: HomeViewModel())
}
