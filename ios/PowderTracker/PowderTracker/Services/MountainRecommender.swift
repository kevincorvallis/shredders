import Foundation

/// Generates personalized mountain recommendations by blending current conditions
/// with user preferences, past experiences, and pass accessibility.
///
/// Replaces the hardcoded 40/30/20/10 weight split in `HomeViewModel.generateSmartSuggestion()`
/// with a 5-factor scoring model that adapts to the user's profile.
///
/// Scoring components (default weights):
///   1. **Conditions** (0.35) – powder score, parking, crowds, lifts
///   2. **Terrain match** (0.25) – user's preferred terrain vs mountain characteristics
///   3. **Historical satisfaction** (0.20) – average rating from past check-ins
///   4. **Pass accessibility** (0.10) – boost if user's season pass matches mountain
///   5. **Similar users** (0.10) – aggregate ratings from comparable profiles
///
/// Weight learning: after each rated check-in the weights are nudged toward factors
/// that predicted correctly. Persisted via UserDefaults.
@MainActor
@Observable
class MountainRecommender {
    static let shared = MountainRecommender()

    /// Current scoring weights. Indices: [conditions, terrain, historical, pass, similar].
    private(set) var weights: [Double] = MountainRecommender.defaultWeights

    private static let defaultWeights: [Double] = [0.35, 0.25, 0.20, 0.10, 0.10]
    private let storageKey = "MountainRecommender.weights"

    /// Known mountain → terrain tags mapping.
    /// In a future version this could be fetched from the API.
    static let mountainTerrainTags: [String: Set<TerrainType>] = [
        "baker":       [.trees, .backcountry, .groomers],
        "crystal":     [.trees, .moguls, .groomers],
        "stevens":     [.trees, .groomers, .park],
        "bachelor":    [.groomers, .park, .trees],
        "hood":        [.groomers, .moguls],
        "schweitzer":  [.trees, .groomers],
        "snoqualmie":  [.groomers, .park],
        "white":       [.backcountry, .trees, .groomers],
        "mission":     [.groomers, .park],
        "bluewood":    [.groomers, .trees],
    ]

    private init() {
        loadWeights()
    }

    // MARK: - Public API

    /// Score a single mountain for a user.
    func score(
        mountain: Mountain,
        data: MountainBatchedResponse,
        userProfile: UserProfile?,
        parkingPrediction: ParkingPredictionResponse?,
        checkInHistory: [CheckIn]
    ) -> RecommendationScore {
        let conditions = conditionsScore(data: data, parking: parkingPrediction)
        let terrain = terrainMatchScore(mountainId: mountain.id, userProfile: userProfile)
        let historical = historicalScore(mountainId: mountain.id, checkIns: checkInHistory)
        let pass = passBoostScore(mountain: mountain, userProfile: userProfile)
        let similar = similarUsersScore() // placeholder — future iteration

        let total =
            conditions * weights[0] +
            terrain    * weights[1] +
            historical * weights[2] +
            pass       * weights[3] +
            similar    * weights[4]

        let reasons = buildReasons(
            mountain: mountain,
            data: data,
            userProfile: userProfile,
            parking: parkingPrediction,
            conditionsScore: conditions,
            terrainScore: terrain,
            historicalScore: historical,
            passBoost: pass
        )

        return RecommendationScore(
            mountain: mountain,
            totalScore: total,
            conditionsScore: conditions,
            terrainMatchScore: terrain,
            historicalScore: historical,
            passBoost: pass,
            reasons: reasons
        )
    }

    /// Rank a list of mountains by personalized score, descending.
    func rank(
        mountains: [(Mountain, MountainBatchedResponse)],
        userProfile: UserProfile?,
        parkingPredictions: [String: ParkingPredictionResponse],
        checkInHistory: [CheckIn]
    ) -> [RecommendationScore] {
        mountains
            .map { mountain, data in
                score(
                    mountain: mountain,
                    data: data,
                    userProfile: userProfile,
                    parkingPrediction: parkingPredictions[mountain.id],
                    checkInHistory: checkInHistory
                )
            }
            .sorted { $0.totalScore > $1.totalScore }
    }

    /// After the user rates a check-in, nudge weights toward factors that
    /// predicted correctly for that mountain.
    func learnFromCheckIn(
        mountainId: String,
        rating: Int,
        previousScore: RecommendationScore?
    ) {
        guard let prev = previousScore else { return }
        let ratingNorm = Double(rating) / 5.0 * 10.0 // normalize 1-5 → 0-10
        let predictionError = ratingNorm - prev.totalScore

        // If the model under-predicted (error > 0), boost factors that were strong.
        // If over-predicted (error < 0), reduce factors that were strong.
        let learningRate = 0.02
        let factorScores = [
            prev.conditionsScore,
            prev.terrainMatchScore,
            prev.historicalScore,
            prev.passBoost,
            5.0 // placeholder for similar users
        ]

        let totalFactor = factorScores.reduce(0, +)
        guard totalFactor > 0 else { return }

        for i in 0..<weights.count {
            let contribution = factorScores[i] / totalFactor
            weights[i] += learningRate * predictionError * contribution
            weights[i] = max(0.05, min(0.60, weights[i])) // clamp
        }

        // Re-normalize so weights sum to 1
        let sum = weights.reduce(0, +)
        if sum > 0 {
            weights = weights.map { $0 / sum }
        }

        saveWeights()
    }

    /// Reset to default weights.
    func resetWeights() {
        weights = MountainRecommender.defaultWeights
        saveWeights()
    }

    // MARK: - Scoring Components

    /// Conditions sub-score (0-10): powder + parking + crowd + lifts.
    /// Mirrors the original HomeViewModel logic.
    func conditionsScore(
        data: MountainBatchedResponse,
        parking: ParkingPredictionResponse?
    ) -> Double {
        var total: Double = 0

        // Powder score (40% of conditions component)
        total += data.powderScore.score * 0.4

        // Parking ease (30%)
        if let parking {
            let parkingScore: Double
            switch parking.difficulty {
            case .easy:           parkingScore = 10.0
            case .moderate:       parkingScore = 7.0
            case .challenging:    parkingScore = 4.0
            case .veryDifficult:  parkingScore = 1.0
            }
            total += parkingScore * 0.3
        }

        // Crowd level (20%)
        if let tripAdvice = data.tripAdvice {
            let crowdScore: Double
            switch tripAdvice.crowd {
            case .low:    crowdScore = 10.0
            case .medium: crowdScore = 6.0
            case .high:   crowdScore = 2.0
            }
            total += crowdScore * 0.2
        }

        // Lift status (10%)
        if let liftStatus = data.conditions.liftStatus,
           liftStatus.liftsTotal > 0 {
            let liftsOpenPct = Double(liftStatus.liftsOpen) / Double(liftStatus.liftsTotal)
            total += liftsOpenPct * 10.0 * 0.1
        }

        return total
    }

    /// Terrain match sub-score (0-10): how well mountain terrain matches user preferences.
    func terrainMatchScore(mountainId: String, userProfile: UserProfile?) -> Double {
        guard let profile = userProfile else { return 5.0 } // neutral if no profile

        let preferred = profile.preferredTerrainEnums
        guard !preferred.isEmpty else { return 5.0 }

        let mountainTerrain = MountainRecommender.mountainTerrainTags[mountainId] ?? []
        guard !mountainTerrain.isEmpty else { return 5.0 }

        let matching = Set(preferred).intersection(mountainTerrain).count
        let matchRatio = Double(matching) / Double(preferred.count)

        // Scale to 0-10
        return matchRatio * 10.0
    }

    /// Historical satisfaction sub-score (0-10): average rating from past check-ins.
    func historicalScore(mountainId: String, checkIns: [CheckIn]) -> Double {
        let relevant = checkIns.filter { $0.mountainId == mountainId && $0.rating != nil }
        guard !relevant.isEmpty else { return 5.0 } // neutral if no history

        let avgRating = Double(relevant.compactMap(\.rating).reduce(0, +)) / Double(relevant.count)
        return avgRating * 2.0 // 1-5 → 2-10
    }

    /// Pass boost sub-score (0-10): strong boost if user's pass matches mountain pass.
    func passBoostScore(mountain: Mountain, userProfile: UserProfile?) -> Double {
        guard let profile = userProfile,
              let userPass = profile.seasonPassTypeEnum,
              let mountainPass = mountain.passType else {
            return 0
        }

        switch (userPass, mountainPass) {
        case (.ikon, .ikon), (.epic, .epic):
            return 10.0 // full boost
        case (.mountainSpecific, _):
            // Could match if it's their home mountain
            if profile.homeMountainId == mountain.id {
                return 10.0
            }
            return 0
        default:
            return 0
        }
    }

    /// Similar users sub-score — placeholder for future iteration.
    /// Will aggregate ratings from users with matching (experienceLevel, ridingStyle).
    func similarUsersScore() -> Double {
        5.0 // neutral baseline
    }

    // MARK: - Reason Builder

    private func buildReasons(
        mountain: Mountain,
        data: MountainBatchedResponse,
        userProfile: UserProfile?,
        parking: ParkingPredictionResponse?,
        conditionsScore: Double,
        terrainScore: Double,
        historicalScore: Double,
        passBoost: Double
    ) -> [String] {
        var reasons: [String] = []

        // Fresh snow
        let snow24 = data.conditions.snowfall24h
        if snow24 >= 6 {
            reasons.append("\(snow24)\" fresh")
        }

        // Terrain match
        if terrainScore >= 7.0, let profile = userProfile {
            let preferred = profile.preferredTerrainEnums
            let mountainTerrain = MountainRecommender.mountainTerrainTags[mountain.id] ?? []
            let matching = Set(preferred).intersection(mountainTerrain)
            if let first = matching.first {
                reasons.append("Great for \(first.displayName.lowercased())")
            }
        }

        // Pass compatibility
        if passBoost > 0, let pass = userProfile?.seasonPassTypeEnum {
            reasons.append("Your \(pass.displayName) pass")
        }

        // Parking
        if let parking, parking.difficulty == .easy {
            reasons.append("Easy parking")
        }

        // Low crowds
        if let crowd = data.tripAdvice?.crowd, crowd == .low {
            reasons.append("Low crowds")
        }

        // Historical
        if historicalScore >= 8.0 {
            reasons.append("You love it here")
        }

        return Array(reasons.prefix(3)) // max 3 reasons
    }

    // MARK: - Persistence

    private func saveWeights() {
        UserDefaults.standard.set(weights, forKey: storageKey)
    }

    private func loadWeights() {
        if let saved = UserDefaults.standard.array(forKey: storageKey) as? [Double],
           saved.count == MountainRecommender.defaultWeights.count {
            weights = saved
        }
    }
}
