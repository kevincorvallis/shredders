import SwiftUI

/// Sheet for managing favorite mountains
struct FavoritesManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var viewModel = MountainSelectionViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                // Current favorites section
                if !favoritesManager.favoriteIds.isEmpty {
                    Section {
                        ForEach(favoriteMountains) { mountain in
                            FavoriteMountainRow(
                                mountain: mountain,
                                isFavorite: true,
                                onToggle: {
                                    favoritesManager.remove(mountain.id)
                                }
                            )
                        }
                        .onMove { source, destination in
                            favoritesManager.reorder(from: source, to: destination)
                        }
                    } header: {
                        Text("Your Mountains")
                    } footer: {
                        Text("Drag to reorder. Your top mountain appears as Today's Pick.")
                    }
                }

                // Add more mountains section
                Section {
                    ForEach(nonFavoriteMountains.filter { searchMatches($0) }) { mountain in
                        FavoriteMountainRow(
                            mountain: mountain,
                            isFavorite: false,
                            onToggle: {
                                _ = favoritesManager.add(mountain.id)
                            }
                        )
                    }
                } header: {
                    Text("Add Mountains")
                }
            }
            .searchable(text: $searchText, prompt: "Search mountains...")
            .navigationTitle("Manage Favorites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadMountains()
            }
        }
    }

    private var favoriteMountains: [Mountain] {
        favoritesManager.favoriteIds.compactMap { id in
            viewModel.mountains.first { $0.id == id }
        }
    }

    private var nonFavoriteMountains: [Mountain] {
        viewModel.mountains.filter { !favoritesManager.isFavorite($0.id) }
    }

    private func searchMatches(_ mountain: Mountain) -> Bool {
        if searchText.isEmpty { return true }
        return mountain.name.localizedCaseInsensitiveContains(searchText) ||
               mountain.shortName.localizedCaseInsensitiveContains(searchText) ||
               mountain.region.localizedCaseInsensitiveContains(searchText)
    }
}

// MARK: - Favorite Mountain Row

struct FavoriteMountainRow: View {
    let mountain: Mountain
    let isFavorite: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: .spacingM) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: .spacingS) {
                    Text(mountain.region)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let passType = mountain.passType {
                        Text(passType.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(passTypeColor(passType))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(passTypeColor(passType).opacity(0.15))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Button {
                onToggle()
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.title3)
                    .foregroundColor(isFavorite ? .yellow : .gray)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, .spacingXS)
    }

    private func passTypeColor(_ passType: PassType) -> Color {
        switch passType {
        case .epic: return .purple
        case .ikon: return .orange
        case .independent: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    FavoritesManagementSheet()
}
