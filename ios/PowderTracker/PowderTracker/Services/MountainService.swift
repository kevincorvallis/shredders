//
//  MountainService.swift
//  PowderTracker
//
//  Service for fetching and caching mountains data.
//

import Foundation

@MainActor
class MountainService: ObservableObject {
    static let shared = MountainService()

    @Published private(set) var allMountains: [Mountain] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let apiClient = APIClient.shared
    private var hasFetched = false

    private init() {
        // Start with mock data until we fetch from API
        allMountains = Mountain.mockMountains
    }

    /// Fetch mountains from the API
    func fetchMountains() async {
        guard !hasFetched else { return }

        isLoading = true
        error = nil

        do {
            let response = try await apiClient.fetchMountains()
            allMountains = response.mountains.sorted { $0.name < $1.name }
            hasFetched = true
        } catch {
            self.error = error.localizedDescription
            // Keep using mock data on error
            if allMountains.isEmpty {
                allMountains = Mountain.mockMountains
            }
        }

        isLoading = false
    }

    /// Get a mountain by ID
    func mountain(byId id: String) -> Mountain? {
        allMountains.first { $0.id == id }
    }

    /// Refresh mountains (force fetch)
    func refresh() async {
        hasFetched = false
        await fetchMountains()
    }
}
