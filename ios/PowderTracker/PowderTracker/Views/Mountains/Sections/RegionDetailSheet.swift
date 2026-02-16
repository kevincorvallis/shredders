import SwiftUI

struct RegionDetailSheetView: View {
    let region: MountainRegion
    let mountains: [Mountain]
    let viewModel: MountainSelectionViewModel
    let favoritesManager: FavoritesService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(mountains) { mountain in
                NavigationLink {
                    MountainDetailView(mountain: mountain)
                } label: {
                    HStack {
                        MountainLogoView(
                            logoUrl: mountain.logo,
                            color: mountain.color,
                            size: 40
                        )

                        VStack(alignment: .leading) {
                            Text(mountain.name)
                                .font(.headline)
                            if let score = viewModel.getScore(for: mountain) {
                                Text(String(format: "Score: %.1f", score))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if favoritesManager.isFavorite(mountain.id) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .navigationTitle(region.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
