import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showingManagement = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Text("My Mountains")
                            .font(.title2)
                            .fontWeight(.bold)

                        Spacer()

                        Button {
                            showingManagement = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                Text("Manage")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Loading state for initial load
                    if viewModel.isLoading && favoritesManager.favoriteIds.isEmpty {
                        ProgressView("Loading mountains...")
                            .padding(.top, 40)
                    }
                    // Error state
                    else if let error = viewModel.error, viewModel.mountains.isEmpty {
                        ErrorView(message: error) {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                        .padding()
                    }
                    // Favorites list or empty state
                    else if favoritesManager.favoriteIds.isEmpty {
                        FavoritesEmptyState {
                            showingManagement = true
                        }
                    } else {
                        // Favorite mountains cards
                        VStack(spacing: 12) {
                            ForEach(favoritesManager.favoriteIds, id: \.self) { mountainId in
                                if let mountain = viewModel.mountains.first(where: { $0.id == mountainId }) {
                                    NavigationLink {
                                        MountainDetailView(mountainId: mountain.id, mountainName: mountain.name)
                                    } label: {
                                        MountainCardRow(
                                            mountain: mountain,
                                            conditions: viewModel.mountainData[mountainId]?.conditions,
                                            powderScore: viewModel.mountainData[mountainId]?.powderScore
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // All mountains section
                    if !viewModel.mountains.isEmpty {
                        Divider()
                            .padding(.vertical, 8)

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("All Mountains")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                Spacer()

                                Text("\(viewModel.mountains.count) resorts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)

                            ForEach(viewModel.mountains) { mountain in
                                NavigationLink {
                                    MountainDetailView(mountainId: mountain.id, mountainName: mountain.name)
                                } label: {
                                    CompactMountainRow(
                                        mountain: mountain,
                                        isFavorite: favoritesManager.isFavorite(mountain.id),
                                        hasLiveData: viewModel.hasLiveData(for: mountain.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .onChange(of: favoritesManager.favoriteIds) { oldValue, newValue in
                // Reload favorites data when favorites change
                Task {
                    await viewModel.loadFavoritesData()
                }
            }
            .sheet(isPresented: $showingManagement) {
                FavoritesManagementView(mountains: viewModel.mountains)
            }
        }
    }
}

// MARK: - Compact Mountain Row

struct CompactMountainRow: View {
    let mountain: Mountain
    let isFavorite: Bool
    let hasLiveData: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Star icon
            Image(systemName: isFavorite ? "star.fill" : "star")
                .foregroundColor(isFavorite ? .yellow : .secondary.opacity(0.4))
                .font(.body)
                .frame(width: 24)

            // Mountain logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 32
            )

            // Mountain name
            VStack(alignment: .leading, spacing: 2) {
                Text(mountain.shortName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(mountain.region.uppercased())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Live/Static indicator
            if hasLiveData {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            } else if mountain.hasSnotel {
                HStack(spacing: 4) {
                    Image(systemName: "cloud.snow.fill")
                        .font(.caption2)
                    Text("DATA")
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            } else {
                Text("STATIC")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
