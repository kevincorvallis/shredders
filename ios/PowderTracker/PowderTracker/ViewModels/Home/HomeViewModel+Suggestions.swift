import Foundation
import SwiftUI

// MARK: - Smart Suggestion Engine

extension HomeViewModel {

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
}
