import SwiftUI

struct FavoritesManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared
    let mountains: [Mountain]

    @State private var showMaxFavoritesAlert = false

    private var mountainsByRegion: [(String, [Mountain])] {
        Dictionary(grouping: mountains, by: { $0.region })
            .sorted { $0.key < $1.key }
            .map { ($0.key, $0.value.sorted { $0.name < $1.name }) }
    }

    var body: some View {
        NavigationView {
            List {
                // Favorites section (with reordering)
                if !favoritesManager.favoriteIds.isEmpty {
                    Section {
                        ForEach(favoritesManager.favoriteIds, id: \.self) { id in
                            if let mountain = mountains.first(where: { $0.id == id }) {
                                MountainManagementRow(mountain: mountain, isFavorite: true)
                            }
                        }
                        .onMove { source, destination in
                            favoritesManager.reorder(from: source, to: destination)
                        }
                    } header: {
                        HStack {
                            Text("My Favorites")
                            Spacer()
                            Text("\(favoritesManager.favoriteIds.count)/5")
                                .foregroundColor(.secondary)
                        }
                    } footer: {
                        Text("Drag to reorder your favorites")
                            .font(.caption)
                    }
                    .headerProminence(.increased)
                }

                // All mountains by region
                ForEach(mountainsByRegion, id: \.0) { region, regionMountains in
                    Section(region) {
                        ForEach(regionMountains) { mountain in
                            let isFavorite = favoritesManager.isFavorite(mountain.id)
                            MountainManagementRow(mountain: mountain, isFavorite: isFavorite)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleFavorite(mountain.id)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Manage Mountains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .alert("Maximum Favorites Reached", isPresented: $showMaxFavoritesAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can favorite up to 5 mountains. Remove one to add another.")
            }
        }
    }

    private func toggleFavorite(_ mountainId: String) {
        if favoritesManager.isFavorite(mountainId) {
            favoritesManager.remove(mountainId)
        } else {
            let added = favoritesManager.add(mountainId)
            if !added {
                showMaxFavoritesAlert = true
            }
        }
    }
}

struct MountainManagementRow: View {
    let mountain: Mountain
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Star icon
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundColor(isFavorite ? .yellow : .secondary)
                .font(.body)

            // Mountain logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 32
            )

            // Mountain name
            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.shortName)
                    .font(.body)
                    .foregroundColor(.primary)

                if mountain.hasSnotel {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.snow.fill")
                            .font(.caption2)
                        Text("Live data")
                            .font(.caption2)
                    }
                    .foregroundColor(.green)
                }
            }

            Spacer()

            // Region badge
            Text(mountain.region.uppercased())
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(.cornerRadiusMicro)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesManagementView(
        mountains: [
            Mountain(
                id: "baker",
                name: "Mt. Baker",
                shortName: "Baker",
                location: MountainLocation(lat: 48.8587, lng: -121.6714),
                elevation: MountainElevation(base: 3500, summit: 5089),
                region: "WA",
                color: "#4A90E2",
                website: "https://www.mtbaker.us",
                hasSnotel: true,
                webcamCount: 3,
                logo: "/logos/baker.svg",
                status: nil,
                passType: .independent
            ),
            Mountain(
                id: "crystal",
                name: "Crystal Mountain",
                shortName: "Crystal",
                location: MountainLocation(lat: 46.9356, lng: -121.4747),
                elevation: MountainElevation(base: 4400, summit: 7012),
                region: "WA",
                color: "#9B59B6",
                website: "https://www.crystalmountainresort.com",
                hasSnotel: true,
                webcamCount: 4,
                logo: "/logos/crystal.svg",
                status: nil,
                passType: .ikon
            ),
            Mountain(
                id: "meadows",
                name: "Mt. Hood Meadows",
                shortName: "Meadows",
                location: MountainLocation(lat: 45.3318, lng: -121.6654),
                elevation: MountainElevation(base: 4523, summit: 7300),
                region: "OR",
                color: "#E74C3C",
                website: "https://www.skihood.com",
                hasSnotel: true,
                webcamCount: 2,
                logo: "/logos/meadows.svg",
                status: nil,
                passType: .independent
            )
        ]
    )
}
