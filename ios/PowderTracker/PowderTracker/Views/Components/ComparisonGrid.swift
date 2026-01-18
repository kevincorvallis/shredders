import SwiftUI

/// Container for comparison grid showing 2-5 favorite mountains
/// Uses LazyVGrid with 2-column adaptive layout
struct ComparisonGrid: View {
    let favorites: [(mountain: Mountain, data: MountainBatchedResponse)]
    let bestMountainId: String?
    @ObservedObject var viewModel: HomeViewModel
    var onWebcamTap: ((Mountain) -> Void)? = nil

    // 2-column grid layout with tighter spacing
    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(favorites, id: \.mountain.id) { favorite in
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
                            onWebcamTap?(favorite.mountain)
                        }
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
