import Foundation
import CoreLocation
import Combine

@MainActor
class MountainSelectionViewModel: ObservableObject {
    @Published var mountains: [Mountain] = []
    @Published var mountainScores: [String: Double] = [:]
    @Published var selectedMountain: Mountain?
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient = APIClient.shared
    private let locationManager = LocationManager.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to location updates to recalculate distances
        locationManager.$location
            .sink { [weak self] location in
                guard location != nil else { return }
                self?.updateDistances()
            }
            .store(in: &cancellables)
    }

    func loadMountains() async {
        isLoading = true
        error = nil

        do {
            let response = try await apiClient.fetchMountains()
            mountains = response.mountains

            // Request location to calculate distances
            locationManager.requestLocation()

            // Fetch powder scores for all mountains
            await fetchAllPowderScores()

            // Set default selection if none
            if selectedMountain == nil, let first = mountains.first {
                selectedMountain = first
            }
        } catch {
            self.error = error
            print("Failed to load mountains: \(error)")
        }

        isLoading = false
    }

    private func fetchAllPowderScores() async {
        await withTaskGroup(of: (String, Double?).self) { group in
            for mountain in mountains {
                group.addTask {
                    do {
                        let score = try await self.apiClient.fetchPowderScore(for: mountain.id)
                        return (mountain.id, score.score)
                    } catch {
                        return (mountain.id, nil)
                    }
                }
            }

            for await (id, score) in group {
                if let score = score {
                    mountainScores[id] = score
                }
            }
        }
    }

    private func updateDistances() {
        guard let location = locationManager.location else { return }

        mountains = mountains.map { mountain in
            var updated = mountain
            // We can't mutate the struct directly since distance is computed
            // The Mountain struct stores distance from CLLocation calculation
            return updated
        }

        // Sort by distance
        mountains = locationManager.sortMountainsByDistance(mountains)
    }

    func selectMountain(_ mountain: Mountain) {
        selectedMountain = mountain
    }

    func getScore(for mountain: Mountain) -> Double? {
        mountainScores[mountain.id]
    }

    func getDistance(to mountain: Mountain) -> Double? {
        locationManager.distanceTo(mountain)
    }

    var washingtonMountains: [Mountain] {
        mountains.filter { $0.region == "washington" }
    }

    var oregonMountains: [Mountain] {
        mountains.filter { $0.region == "oregon" }
    }
}
