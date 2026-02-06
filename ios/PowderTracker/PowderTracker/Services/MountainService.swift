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

    @Published private(set) var allMountains: [Mountain] = [] {
        didSet {
            mountainsById = Dictionary(uniqueKeysWithValues: allMountains.map { ($0.id, $0) })
        }
    }
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    /// O(1) mountain lookup by ID
    private(set) var mountainsById: [String: Mountain] = [:]

    private let apiClient = APIClient.shared
    private var hasFetched = false
    /// Prevents concurrent duplicate network calls
    private var fetchTask: Task<Void, Never>?

    private init() {
        // Start with mock data until we fetch from API
        allMountains = Mountain.mockMountains
    }

    /// Fetch mountains from the API (deduplicates concurrent calls)
    func fetchMountains() async {
        guard !hasFetched else { return }

        // If a fetch is already in flight, await it instead of starting another
        if let existing = fetchTask {
            await existing.value
            return
        }

        let task = Task { @MainActor in
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
            fetchTask = nil
        }

        fetchTask = task
        await task.value
    }

    /// Get a mountain by ID (O(1) dictionary lookup)
    func mountain(byId id: String) -> Mountain? {
        mountainsById[id]
    }

    /// Refresh mountains (force fetch)
    func refresh() async {
        hasFetched = false
        fetchTask = nil
        await fetchMountains()
    }
}
