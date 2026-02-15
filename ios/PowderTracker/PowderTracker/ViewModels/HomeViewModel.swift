import Foundation
import SwiftUI

@MainActor
@Observable
class HomeViewModel {
    var mountainData: [String: MountainBatchedResponse] = [:] {
        didSet { rebuildCachedHelpers() }
    }
    var mountains: [Mountain] = [] {
        didSet {
            // Rebuild lookup dictionary when mountains change
            mountainsById = Dictionary(uniqueKeysWithValues: mountains.map { ($0.id, $0) })
        }
    }
    var isLoading = false
    var error: String?
    var lastRefreshDate: Date?

    // Enhanced data for homepage redesign
    var arrivalTimes: [String: ArrivalTimeRecommendation] = [:] {
        didSet { rebuildCachedHelpers() }
    }
    var parkingPredictions: [String: ParkingPredictionResponse] = [:] {
        didSet { rebuildCachedHelpers() }
    }

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
    private let favoritesService = FavoritesService.shared

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

    private func rebuildCachedHelpers() {
        cachedBestPowder = getBestPowderToday()
        cachedSmartSuggestion = generateSmartSuggestion()
        cachedLeaveNowMountains = getLeaveNowMountains()
    }

    // MARK: - Smart Helpers

    // Static formatter to avoid expensive instantiation on each call
    private static let arrivalTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Get mountains that need to leave soon (within 60 minutes of optimal arrival)
    func getLeaveNowMountains() -> [(mountain: Mountain, arrivalTime: ArrivalTimeRecommendation)] {
        let now = Date()

        return arrivalTimes.compactMap { (mountainId, arrival) -> (Mountain, ArrivalTimeRecommendation)? in
            guard let mountain = mountainsById[mountainId],
                  let optimalTime = Self.arrivalTimeFormatter.date(from: arrival.arrivalWindow.optimal) else {
                return nil
            }

            let timeUntilArrival = optimalTime.timeIntervalSince(now)
            // If optimal arrival is within next 15-60 minutes, show "Leave Now"
            if timeUntilArrival > 15 * 60 && timeUntilArrival < 60 * 60 {
                return (mountain, arrival)
            }
            return nil
        }.sorted { $0.arrivalTime.confidence.rawValue < $1.arrivalTime.confidence.rawValue }
    }

    /// Get the mountain with the best powder score today
    func getBestPowderToday() -> (mountain: Mountain, score: MountainPowderScore, data: MountainBatchedResponse)? {
        let favoriteMountainIds = Set(favoritesService.favoriteIds)

        return mountainData
            .filter { favoriteMountainIds.contains($0.key) }
            .compactMap { (id, data) -> (Mountain, MountainPowderScore, MountainBatchedResponse)? in
                guard let mountain = mountainsById[id] else { return nil }
                return (mountain, data.powderScore, data)
            }
            .max { $0.1.score < $1.1.score }
    }

    /// Get all active weather alerts across favorites (filters out expired alerts)
    func getActiveAlerts() -> [WeatherAlert] {
        let favoriteMountainIds = Set(favoritesService.favoriteIds)
        return mountainData
            .filter { favoriteMountainIds.contains($0.key) }
            .flatMap { $0.value.alerts }
            .filter { !$0.isExpired }
    }

    /// Get active storm alerts (powder-boosting events only)
    func getActiveStormAlerts() -> [WeatherAlert] {
        return getActiveAlerts().filter { $0.isPowderBoostEvent }
    }

    /// Get the most significant active storm alert
    func getMostSignificantStorm() -> WeatherAlert? {
        let stormAlerts = getActiveStormAlerts()
        // Sort by severity (Extreme > Severe > Moderate > Minor)
        let severityOrder = ["extreme": 0, "severe": 1, "moderate": 2, "minor": 3, "unknown": 4]
        return stormAlerts.min { a, b in
            let aOrder = severityOrder[a.severity.lowercased()] ?? 4
            let bOrder = severityOrder[b.severity.lowercased()] ?? 4
            return aOrder < bOrder
        }
    }

    /// Generate smart suggestion based on conditions
    func generateSmartSuggestion() -> String? {
        let favoriteMountainIds = Set(favoritesService.favoriteIds)

        // Score each mountain on multiple factors
        let scores = mountainData
            .filter { favoriteMountainIds.contains($0.key) }
            .compactMap { (id, data) -> (mountain: Mountain, score: Double, data: MountainBatchedResponse)? in
                guard let mountain = mountainsById[id],
                      let status = data.status,
                      status.isOpen else {
                    return nil
                }

                var totalScore: Double = 0

                // Powder score (40% weight)
                totalScore += data.powderScore.score * 0.4

                // Parking ease (30% weight) - inverse of difficulty
                if let parking = parkingPredictions[id] {
                    let parkingScore: Double
                    switch parking.difficulty {
                    case .easy: parkingScore = 10.0
                    case .moderate: parkingScore = 7.0
                    case .challenging: parkingScore = 4.0
                    case .veryDifficult: parkingScore = 1.0
                    }
                    totalScore += parkingScore * 0.3
                }

                // Crowd level (20% weight) - inverse of crowds
                if let tripAdvice = data.tripAdvice {
                    let crowdScore: Double
                    switch tripAdvice.crowd {
                    case .low: crowdScore = 10.0
                    case .medium: crowdScore = 6.0
                    case .high: crowdScore = 2.0
                    }
                    totalScore += crowdScore * 0.2
                }

                // Lift status (10% weight)
                if let liftStatus = data.conditions.liftStatus {
                    let liftsOpenPct = Double(liftStatus.liftsOpen) / Double(liftStatus.liftsTotal)
                    totalScore += liftsOpenPct * 10 * 0.1
                }

                return (mountain, totalScore, data)
            }
            .sorted { $0.score > $1.score }

        // If top score differs significantly from user's #1 favorite, suggest it
        guard scores.count > 1,
              let topMountain = scores.first,
              let userFirstFavoriteId = favoritesService.favoriteIds.first,
              topMountain.mountain.id != userFirstFavoriteId else {
            return nil
        }

        // Build suggestion with 1-2 key differentiators
        var suggestion = "Consider \(topMountain.mountain.shortName)"

        var reasons: [String] = []

        // Add powder reason
        if topMountain.data.powderScore.score >= 8.0 {
            let snow24h = topMountain.data.conditions.snowfall24h
            reasons.append("\(Int(snow24h))\" fresh")
        }

        // Add parking reason
        if let parking = parkingPredictions[topMountain.mountain.id],
           parking.difficulty == ParkingDifficulty.easy || parking.difficulty == ParkingDifficulty.moderate {
            reasons.append("easy parking")
        }

        // Add crowd reason
        if let tripAdvice = topMountain.data.tripAdvice,
           tripAdvice.crowd == RiskLevel.low {
            reasons.append("minimal crowds")
        }

        if !reasons.isEmpty {
            suggestion += " - " + reasons.prefix(2).joined(separator: ", ")
        }

        return suggestion
    }

    /// Get a personalized ranking of favorite mountains using MountainRecommender.
    /// Falls back to powder-score ordering when no user profile is available.
    func getPersonalizedRanking(
        userProfile: UserProfile? = nil,
        checkInHistory: [CheckIn] = []
    ) -> [RecommendationScore] {
        let favoriteMountainIds = Set(favoritesService.favoriteIds)

        let mountains: [(Mountain, MountainBatchedResponse)] = mountainData
            .filter { favoriteMountainIds.contains($0.key) }
            .compactMap { id, data in
                guard let mountain = mountainsById[id] else { return nil }
                return (mountain, data)
            }

        return MountainRecommender.shared.rank(
            mountains: mountains,
            userProfile: userProfile,
            parkingPredictions: parkingPredictions,
            checkInHistory: checkInHistory
        )
    }

    /// Get favorite mountains with their data
    func getFavoriteMountains() -> [(mountain: Mountain, data: MountainBatchedResponse)] {
        favoritesService.favoriteIds.compactMap { id in
            guard let mountain = mountainsById[id],
                  let data = mountainData[id] else {
                return nil
            }
            return (mountain, data)
        }
    }

    // MARK: - Trend Calculation

    /// Calculate snow trend for a mountain based on recent snowfall
    func getSnowTrend(for mountainId: String) -> TrendIndicator {
        guard let data = mountainData[mountainId] else { return .stable }

        let snowfall24h = data.conditions.snowfall24h
        let snowfall48h = data.conditions.snowfall48h

        // Calculate previous 24h snowfall (48h total - most recent 24h)
        let previous24h = snowfall48h - snowfall24h
        let diff = snowfall24h - previous24h

        // Thresholds for trend classification
        if diff > 2 {
            return .improving
        } else if diff < -2 {
            return .declining
        } else {
            return .stable
        }
    }

    /// Get comparison text for "Why Best?" section
    func getComparisonToBest(mountainId: String, bestMountainId: String) -> String? {
        guard mountainId != bestMountainId,
              let mountain = mountainData[mountainId],
              let best = mountainData[bestMountainId] else {
            return nil
        }

        let diff = best.conditions.snowfall24h - mountain.conditions.snowfall24h

        if diff > 0 {
            if let bestMountain = mountainsById[bestMountainId] {
                return "+\(diff)\" more than \(bestMountain.shortName)"
            }
        }

        return nil
    }

    /// Generate "Why Best?" reasons for the top powder mountain
    func getWhyBestReasons(for mountainId: String) -> [String] {
        guard let data = mountainData[mountainId],
              mountainsById[mountainId] != nil else {
            return []
        }

        var reasons: [String] = []

        // Reason 1: Fresh snow
        let snow24h = data.conditions.snowfall24h
        if snow24h >= 6 {
            reasons.append("\(snow24h)\" fresh snow in 24h")
        }

        // Reason 2: Crowd level
        if let tripAdvice = data.tripAdvice {
            switch tripAdvice.crowd {
            case .low:
                let dayOfWeek = Calendar.current.component(.weekday, from: Date())
                let dayName = dayOfWeek == 2 ? "Monday" : dayOfWeek == 3 ? "Tuesday" : dayOfWeek == 4 ? "Wednesday" : dayOfWeek == 5 ? "Thursday" : dayOfWeek == 6 ? "Friday" : ""
                if !dayName.isEmpty {
                    reasons.append("Light crowds expected (\(dayName))")
                }
            default:
                break
            }
        }

        // Reason 3: Comparison to other favorites (if this is the best)
        if let best = getBestPowderToday(), best.mountain.id == mountainId {
            // Find the second-best mountain
            let sorted = mountainData
                .filter { favoritesService.favoriteIds.contains($0.key) }
                .filter { $0.key != mountainId }
                .sorted { $0.value.powderScore.score > $1.value.powderScore.score }

            if let secondBest = sorted.first,
               let secondBestMountain = mountainsById[secondBest.key] {
                let diff = snow24h - secondBest.value.conditions.snowfall24h
                if diff > 0 {
                    reasons.append("+\(diff)\" more than \(secondBestMountain.shortName)")
                }
            }
        }

        return Array(reasons.prefix(3))
    }

    // MARK: - Webcam Helpers

    /// Get all webcams from favorite mountains for the webcam strip
    func getAllFavoriteWebcams() -> [(mountain: Mountain, webcam: MountainDetail.Webcam)] {
        var webcams: [(mountain: Mountain, webcam: MountainDetail.Webcam)] = []

        for mountainId in favoritesService.favoriteIds {
            guard let mountain = mountainsById[mountainId],
                  let data = mountainData[mountainId] else {
                continue
            }

            // Add the first webcam from each mountain (or first 2 if many favorites)
            let webcamsToAdd = favoritesService.favoriteIds.count <= 3 ? 2 : 1
            for webcam in data.mountain.webcams.prefix(webcamsToAdd) {
                webcams.append((mountain, webcam))
            }
        }

        return webcams
    }

    /// Get pick reasons for TodaysPickCard
    func getPickReasons(for mountainId: String) -> [PickReason] {
        guard let data = mountainData[mountainId] else { return [] }

        var reasons: [PickReason] = []

        // Fresh snow reason
        let snow24h = data.conditions.snowfall24h
        if snow24h >= 6 {
            reasons.append(PickReason(
                icon: "snowflake",
                text: "\(snow24h)\" fresh snow"
            ))
        }

        // Crowd reason
        if let tripAdvice = data.tripAdvice, tripAdvice.crowd == .low {
            reasons.append(PickReason(
                icon: "person.2.fill",
                text: "Low crowds today"
            ))
        }

        // Powder score reason
        if data.powderScore.score >= 7.5 {
            reasons.append(PickReason(
                icon: "star.fill",
                text: "Excellent conditions"
            ))
        }

        return Array(reasons.prefix(3))
    }
}

// MARK: - Pick Reason Model

struct PickReason: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
}
