import Foundation
import CoreLocation
import Combine

@MainActor
class MountainSelectionViewModel: ObservableObject {
    @Published var mountains: [Mountain] = []
    @Published var mountainScores: [String: Double] = [:]
    @Published var mountainConditions: [String: MountainConditions] = [:]
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

            // Fetch powder scores and conditions for all mountains
            await fetchAllPowderScores()
            await fetchAllConditions()

            // Set default selection if none
            if selectedMountain == nil, let first = mountains.first {
                selectedMountain = first
            }
        } catch {
            self.error = error
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

    private func fetchAllConditions() async {
        await withTaskGroup(of: (String, MountainConditions?).self) { group in
            for mountain in mountains {
                group.addTask {
                    do {
                        let conditions = try await self.apiClient.fetchConditions(for: mountain.id)
                        return (mountain.id, conditions)
                    } catch {
                        #if DEBUG
                        print("Failed to fetch conditions for \(mountain.id): \(error.localizedDescription)")
                        #endif
                        return (mountain.id, nil)
                    }
                }
            }

            for await (id, conditions) in group {
                if let conditions = conditions {
                    mountainConditions[id] = conditions
                }
            }
        }
    }

    private func updateDistances() {
        guard locationManager.location != nil else { return }

        mountains = mountains.map { mountain in
            let updated = mountain
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

    func getConditions(for mountain: Mountain) -> MountainConditions? {
        mountainConditions[mountain.id]
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

    var idahoMountains: [Mountain] {
        mountains.filter { $0.region == "idaho" }
    }
}
