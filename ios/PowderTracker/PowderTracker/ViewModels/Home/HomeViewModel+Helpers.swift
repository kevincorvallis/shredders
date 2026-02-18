import Foundation
import SwiftUI

// MARK: - Trend & Comparison Helpers

extension HomeViewModel {

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

    /// Determines whether the Today's Pick card has earned its screen space.
    /// Returns true only when conditions are genuinely noteworthy — avoids
    /// cluttering the home screen on unremarkable days.
    func shouldShowTodaysPick() -> Bool {
        guard let best = cachedBestPowder else { return false }

        let data = best.data
        let score = best.score.score

        // Strong powder score (7.0+ out of 10)
        if score >= 7.0 { return true }

        // Meaningful fresh snow in last 24h
        if data.conditions.snowfall24h >= 6 { return true }

        // Active storm alert on any favorite — conditions are interesting
        if !getActiveStormAlerts().isEmpty { return true }

        // Decent score AND a clear standout among favorites
        if score >= 5.0 {
            let favoriteScores = mountainData
                .filter { favoritesService.favoriteIds.contains($0.key) }
                .map { $0.value.powderScore.score }
                .sorted(by: >)

            // #1 is at least 2 points above #2 — there's a real pick to make
            if favoriteScores.count >= 2,
               favoriteScores[0] - favoriteScores[1] >= 2.0 {
                return true
            }
        }

        return false
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
