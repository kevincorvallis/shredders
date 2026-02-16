import Foundation
import SwiftUI

@MainActor
@Observable
class HomeViewModel {
    var mountainData: [String: MountainBatchedResponse] = [:] {
        didSet { setNeedsHelperRebuild() }
    }
    var mountains: [Mountain] = [] {
        didSet {
            mountainsById = Dictionary(uniqueKeysWithValues: mountains.map { ($0.id, $0) })
        }
    }
    var isLoading = false
    var error: String?
    var lastRefreshDate: Date?

    // Enhanced data for homepage redesign
    var arrivalTimes: [String: ArrivalTimeRecommendation] = [:] {
        didSet { setNeedsHelperRebuild() }
    }
    var parkingPredictions: [String: ParkingPredictionResponse] = [:] {
        didSet { setNeedsHelperRebuild() }
    }

    /// Coalesces rapid didSet calls into a single rebuild
    private var helperRebuildTask: Task<Void, Never>?

    // Cached computed helpers — rebuilt when data changes
    private(set) var cachedBestPowder: (mountain: Mountain, score: MountainPowderScore, data: MountainBatchedResponse)?
    private(set) var cachedSmartSuggestion: String?
    private(set) var cachedLeaveNowMountains: [(mountain: Mountain, arrivalTime: ArrivalTimeRecommendation)] = []

    // Check-in feed for Today tab
    var recentCheckIns: [CheckIn] = []

    // Track failed enhanced data loads for potential retry
    var failedArrivalTimeLoads: Set<String> = []
    var failedParkingLoads: Set<String> = []
    var isLoadingEnhancedData = false

    // O(1) mountain lookup by ID
    private(set) var mountainsById: [String: Mountain] = [:]

    private let apiClient = APIClient.shared
    let favoritesService = FavoritesService.shared

    // MARK: - Data Loading

    /// Load the complete list of all mountains via MountainService singleton
    func loadMountains() async {
        await MountainService.shared.fetchMountains()
        mountains = MountainService.shared.allMountains
    }

    /// Batch load data for all favorited mountains using the batch endpoint
    func loadFavoritesData() async {
        let favoriteIds = favoritesService.favoriteIds
        guard !favoriteIds.isEmpty else {
            isLoading = false
            lastRefreshDate = Date()
            return
        }

        isLoading = true
        error = nil

        #if DEBUG
        print("📡 [HomeVM] loadFavoritesData (batch) starting for: \(favoriteIds)")
        #endif

        do {
            let response = try await apiClient.fetchBatchMountainData(for: favoriteIds)
            for (id, data) in response.mountains {
                mountainData[id] = data
            }
            #if DEBUG
            if let errors = response.errors, !errors.isEmpty {
                print("⚠️ [HomeVM] Batch had errors: \(errors)")
            }
            print("📡 [HomeVM] loadFavoritesData (batch) complete. mountainData keys: \(Array(mountainData.keys))")
            #endif
        } catch {
            #if DEBUG
            print("❌ [HomeVM] Batch endpoint failed: \(error.localizedDescription), falling back to individual requests")
            #endif
            // Fallback to individual requests
            await loadFavoritesDataIndividually()
        }

        isLoading = false
        lastRefreshDate = Date()
    }

    /// Fallback: load favorites data individually if batch endpoint fails
    private func loadFavoritesDataIndividually() async {
        #if DEBUG
        print("📡 [HomeVM] loadFavoritesDataIndividually starting for: \(favoritesService.favoriteIds)")
        #endif

        await withTaskGroup(of: (String, MountainBatchedResponse?).self) { group in
            for mountainId in favoritesService.favoriteIds {
                group.addTask {
                    do {
                        let data = try await self.apiClient.fetchMountainData(for: mountainId)
                        #if DEBUG
                        print("📡 [HomeVM] Loaded \(mountainId) - forecast count: \(data.forecast.count)")
                        #endif
                        return (mountainId, data)
                    } catch {
                        #if DEBUG
                        print("❌ [HomeVM] Failed to load \(mountainId): \(error.localizedDescription)")
                        #endif
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

        #if DEBUG
        print("📡 [HomeVM] loadFavoritesDataIndividually complete. mountainData keys: \(Array(mountainData.keys))")
        #endif
    }

    /// Load recent check-ins for favorited mountains
    func loadRecentCheckIns() async {
        let favoriteIds = favoritesService.favoriteIds
        guard !favoriteIds.isEmpty else {
            recentCheckIns = []
            return
        }

        do {
            recentCheckIns = try await CheckInService.shared.fetchRecentCheckIns(for: favoriteIds)
        } catch {
            #if DEBUG
            print("❌ [HomeVM] Failed to load recent check-ins: \(error.localizedDescription)")
            #endif
        }
    }

    /// Get the mountain name for a given mountain ID
    func mountainName(for id: String) -> String {
        mountainsById[id]?.shortName ?? mountainsById[id]?.name ?? id
    }

    /// Refresh all data (mountains list + favorites data) in parallel
    func refresh() async {
        let span = PerformanceLogger.beginHomeRefresh()
        async let m: Void = loadMountains()
        async let f: Void = loadFavoritesData()
        async let c: Void = loadRecentCheckIns()
        _ = await (m, f, c)
        span.end()
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

    /// Get all favorite mountains with their complete data
    func getFavoritesWithData() -> [(mountain: Mountain, data: MountainBatchedResponse)] {
        return favoritesService.favoriteIds.compactMap { mountainId in
            guard let mountain = mountainsById[mountainId],
                  let data = mountainData[mountainId] else {
                return nil
            }
            return (mountain, data)
        }
    }

    /// Get all favorite mountains with their forecast data
    func getFavoritesWithForecast() -> [(mountain: Mountain, forecast: [ForecastDay])] {
        // Skip lookup until both mountains and forecast data have loaded
        guard !mountainsById.isEmpty, !mountainData.isEmpty else {
            return []
        }

        return favoritesService.favoriteIds.compactMap { mountainId in
            guard let mountain = mountainsById[mountainId],
                  let data = mountainData[mountainId] else {
                return nil
            }
            return (mountain, data.forecast)
        }
    }

    // MARK: - Enhanced Data Loading

    /// Load arrival times and parking predictions for favorites
    func loadEnhancedData() async {
        isLoadingEnhancedData = true
        failedArrivalTimeLoads.removeAll()
        failedParkingLoads.removeAll()

        await withTaskGroup(of: Void.self) { group in
            // Load arrival times
            for mountainId in favoritesService.favoriteIds {
                group.addTask {
                    do {
                        let arrivalTime = try await self.apiClient.fetchArrivalTime(for: mountainId)
                        await MainActor.run {
                            self.arrivalTimes[mountainId] = arrivalTime
                            self.failedArrivalTimeLoads.remove(mountainId)
                        }
                    } catch {
                        _ = await MainActor.run {
                            self.failedArrivalTimeLoads.insert(mountainId)
                        }
                        #if DEBUG
                        print("Failed to load arrival time for \(mountainId): \(error.localizedDescription)")
                        #endif
                    }
                }

                // Load parking predictions
                group.addTask {
                    do {
                        let parking = try await self.apiClient.fetchParkingPrediction(for: mountainId)
                        await MainActor.run {
                            self.parkingPredictions[mountainId] = parking
                            self.failedParkingLoads.remove(mountainId)
                        }
                    } catch {
                        _ = await MainActor.run {
                            self.failedParkingLoads.insert(mountainId)
                        }
                        #if DEBUG
                        print("Failed to load parking for \(mountainId): \(error.localizedDescription)")
                        #endif
                    }
                }
            }
        }

        isLoadingEnhancedData = false
    }

    /// Retry loading enhanced data for a specific mountain
    func retryEnhancedData(for mountainId: String) async {
        if failedArrivalTimeLoads.contains(mountainId) {
            do {
                let arrivalTime = try await apiClient.fetchArrivalTime(for: mountainId)
                arrivalTimes[mountainId] = arrivalTime
                failedArrivalTimeLoads.remove(mountainId)
            } catch {
                #if DEBUG
                print("Retry failed for arrival time \(mountainId): \(error.localizedDescription)")
                #endif
            }
        }

        if failedParkingLoads.contains(mountainId) {
            do {
                let parking = try await apiClient.fetchParkingPrediction(for: mountainId)
                parkingPredictions[mountainId] = parking
                failedParkingLoads.remove(mountainId)
            } catch {
                #if DEBUG
                print("Retry failed for parking \(mountainId): \(error.localizedDescription)")
                #endif
            }
        }
    }

    // MARK: - Cached Helper Rebuild

    /// Debounce rapid didSet calls (e.g. batch loop setting mountainData per-key)
    private func setNeedsHelperRebuild() {
        helperRebuildTask?.cancel()
        helperRebuildTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms coalesce window
            guard !Task.isCancelled else { return }
            cachedBestPowder = getBestPowderToday()
            cachedSmartSuggestion = generateSmartSuggestion()
            cachedLeaveNowMountains = getLeaveNowMountains()
        }
    }
}
