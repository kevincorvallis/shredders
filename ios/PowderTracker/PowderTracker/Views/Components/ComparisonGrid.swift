import SwiftUI

/// Container for comparison grid showing 2-5 favorite mountains
/// Uses LazyVGrid with 2-column adaptive layout
/// Enhanced with design system tokens and smooth animations
struct ComparisonGrid: View {
    let favorites: [(mountain: Mountain, data: MountainBatchedResponse)]
    let bestMountainId: String?
    var viewModel: HomeViewModel
    var onWebcamTap: ((Mountain) -> Void)? = nil

    // 2-column grid layout with design system spacing
    private let columns = [
        GridItem(.flexible(), spacing: .spacingM),
        GridItem(.flexible(), spacing: .spacingM)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: .spacingM) {
            ForEach(Array(favorites.enumerated()), id: \.element.mountain.id) { index, favorite in
                NavigationLink {
                    MountainDetailView(mountain: favorite.mountain)
                } label: {
                    ComparisonGridCard(
                        mountain: favorite.mountain,
                        conditions: favorite.data.conditions,
                        powderScore: favorite.data.powderScore,
                        trend: viewModel.getSnowTrend(for: favorite.mountain.id),
                        isBest: favorite.mountain.id == bestMountainId,
                        webcamCount: favorite.data.mountain.webcams.count,
                        alertCount: favorite.data.alerts.count,
                        crowdLevel: favorite.data.tripAdvice?.crowd,
                        onWebcamTap: {
                            HapticFeedback.light.trigger()
                            onWebcamTap?(favorite.mountain)
                        }
                    )
                    .scrollTransition(.animated(.bouncy)) { content, phase in
                        content
                            .opacity(phase.isIdentity ? 1 : 0.8)
                            .scaleEffect(phase.isIdentity ? 1 : 0.95)
                    }
                }
                .buttonStyle(.navigation)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Comparison Grid")
                    .font(.headline)
                    .padding(.horizontal)

                Text("Preview not available - requires view model")
                    .foregroundColor(.secondary)
                    .padding()
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}
