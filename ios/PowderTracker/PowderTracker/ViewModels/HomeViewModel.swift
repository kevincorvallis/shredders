import Foundation
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var mountainData: [String: MountainBatchedResponse] = [:]
    @Published var mountains: [Mountain] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var lastRefreshDate: Date?

    private let apiClient = APIClient.shared
    private let favoritesManager = FavoritesManager.shared

    // MARK: - Data Loading

    /// Load the complete list of all mountains
    func loadMountains() async {
        do {
            let response = try await apiClient.fetchMountains()
            mountains = response.mountains
        } catch {
            self.error = error.localizedDescription
            print("Failed to load mountains: \(error)")
        }
    }

    /// Batch load data for all favorited mountains in parallel
    func loadFavoritesData() async {
        isLoading = true
        error = nil

        await withTaskGroup(of: (String, MountainBatchedResponse?).self) { group in
            for mountainId in favoritesManager.favoriteIds {
                group.addTask {
                    do {
                        let data = try await self.apiClient.fetchMountainData(for: mountainId)
                        return (mountainId, data)
                    } catch {
                        print("Failed to load data for \(mountainId): \(error)")
                        return (mountainId, nil)
                    }
                }
            }

            for await (id, data) in group {
                if let data = data {
                    mountainData[id] = data
                }
            }
        }

        isLoading = false
        lastRefreshDate = Date()
    }

    /// Refresh all data (mountains list + favorites data)
    func refresh() async {
        await loadMountains()
        await loadFavoritesData()
    }

    /// Initial load on view appear
    func loadData() async {
        await refresh()
    }

    // MARK: - Helpers

    /// Get mountain data for a specific ID
    func data(for mountainId: String) -> MountainBatchedResponse? {
        mountainData[mountainId]
    }

    /// Check if a mountain has live lift status data
    func hasLiveData(for mountainId: String) -> Bool {
        mountainData[mountainId]?.conditions.liftStatus != nil
    }
}
