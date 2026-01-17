import SwiftUI

/// Container for comparison grid showing 2-5 favorite mountains
/// Uses LazyVGrid with 2-column adaptive layout
struct ComparisonGrid: View {
    let favorites: [(mountain: Mountain, data: MountainBatchedResponse)]
    let bestMountainId: String?
    @ObservedObject var viewModel: HomeViewModel

    // 2-column grid layout
    private let columns = [
        GridItem(.flexible(), spacing: .spacingM),
        GridItem(.flexible(), spacing: .spacingM)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: .spacingM) {
            ForEach(favorites, id: \.mountain.id) { favorite in
                NavigationLink {
                    LocationView(mountain: favorite.mountain)
                } label: {
                    ComparisonGridCard(
                        mountain: favorite.mountain,
                        conditions: favorite.data.conditions,
                        powderScore: favorite.data.powderScore,
                        trend: viewModel.getSnowTrend(for: favorite.mountain.id),
                        isBest: favorite.mountain.id == bestMountainId
                    )
                }
                .buttonStyle(.plain)
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
