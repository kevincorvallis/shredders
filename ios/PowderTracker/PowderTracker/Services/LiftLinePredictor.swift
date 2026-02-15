import Foundation

/// Predicts lift line wait times based on conditions, time, and historical patterns
class LiftLinePredictor {

    enum BusynessLevel: String {
        case empty = "Empty"
        case light = "Light"
        case moderate = "Moderate"
        case busy = "Busy"
        case veryBusy = "Very Busy"
        case packed = "Packed"

        var waitMinutes: Int {
            switch self {
            case .empty: return 0
            case .light: return 3
            case .moderate: return 7
            case .busy: return 12
            case .veryBusy: return 20
            case .packed: return 30
            }
        }

        var color: String {
            switch self {
            case .empty: return "green"
            case .light: return "green"
            case .moderate: return "yellow"
            case .busy: return "orange"
            case .veryBusy: return "red"
            case .packed: return "red"
            }
        }

        var icon: String {
            switch self {
            case .empty: return "checkmark.circle.fill"
            case .light: return "checkmark.circle"
            case .moderate: return "person.2"
            case .busy: return "person.3"
            case .veryBusy: return "exclamationmark.triangle.fill"
            case .packed: return "xmark.octagon.fill"
            }
        }
    }

    struct LiftPrediction {
        let liftName: String
        let busyness: BusynessLevel
        let waitMinutes: Int
        let reason: String
        let confidence: Double // 0-1
    }

    // MARK: - Main Prediction Method

    /// Predicts overall mountain busyness and individual lift lines
    static func predictMountainBusyness(
        powderScore: Int,
        temperature: Double,
        windSpeed: Double,
        percentOpen: Int,
        liftsOpen: Int,
        liftsTotal: Int,
        currentTime: Date = Date()
    ) -> (overall: BusynessLevel, predictions: [LiftPrediction]) {

        // Calculate base crowd factor (0-1)
        var crowdFactor = 0.5

        // 1. Powder score impact (high score = more crowds)
        if powderScore >= 8 {
            crowdFactor += 0.3 // Epic powder brings crowds
        } else if powderScore >= 6 {
            crowdFactor += 0.15
        } else if powderScore <= 3 {
            crowdFactor -= 0.2 // Poor conditions = fewer people
        }

        // 2. Time of day impact
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let timeMultiplier = timeOfDayMultiplier(hour: hour)
        crowdFactor *= timeMultiplier

        // 3. Day of week impact
        let weekday = calendar.component(.weekday, from: currentTime)
        if weekday == 1 || weekday == 7 { // Weekend
            crowdFactor += 0.25
        } else { // Weekday
            crowdFactor -= 0.15
        }

        // 4. Weather impact (extreme weather = fewer people)
        if temperature < 10 || temperature > 45 {
            crowdFactor -= 0.15
        }
        if windSpeed > 30 {
            crowdFactor -= 0.2
        } else if windSpeed > 20 {
            crowdFactor -= 0.1
        }

        // 5. Terrain availability (less open = funneling effect)
        if percentOpen < 50 {
            crowdFactor += 0.2 // Funneling effect when limited terrain
        } else if percentOpen >= 90 {
            crowdFactor -= 0.1 // Crowds spread out
        }

        // Clamp to 0-1
        crowdFactor = max(0, min(1, crowdFactor))

        // Determine overall busyness
        let overall = busynessLevel(from: crowdFactor)

        // Generate lift-specific predictions
        let predictions = generateLiftPredictions(
            crowdFactor: crowdFactor,
            powderScore: powderScore,
            percentOpen: percentOpen,
            liftsOpen: liftsOpen,
            liftsTotal: liftsTotal,
            currentTime: currentTime
        )

        return (overall, predictions)
    }

    // MARK: - Helper Methods

    /// Returns a multiplier based on time of day
    private static func timeOfDayMultiplier(hour: Int) -> Double {
        switch hour {
        case 7...8:   return 0.6  // Early morning - light crowds
        case 9...10:  return 1.3  // Morning rush - peak
        case 11...12: return 1.1  // Late morning - still busy
        case 13...14: return 0.8  // Lunch time - lull
        case 15...16: return 1.0  // Afternoon - moderate
        case 17...18: return 0.7  // Late afternoon - dying down
        default:      return 0.4  // Off hours
        }
    }

    /// Converts crowd factor to busyness level
    private static func busynessLevel(from factor: Double) -> BusynessLevel {
        if factor >= 0.85 { return .packed }
        if factor >= 0.7 { return .veryBusy }
        if factor >= 0.5 { return .busy }
        if factor >= 0.3 { return .moderate }
        if factor >= 0.15 { return .light }
        return .empty
    }

    /// Generates predictions for specific lift types
    private static func generateLiftPredictions(
        crowdFactor: Double,
        powderScore: Int,
        percentOpen: Int,
        liftsOpen: Int,
        liftsTotal: Int,
        currentTime: Date
    ) -> [LiftPrediction] {

        var predictions: [LiftPrediction] = []

        // Predict for common lift categories

        // 1. Main/Express lifts (busiest)
        let mainCrowdFactor = crowdFactor * 1.2
        predictions.append(LiftPrediction(
            liftName: "Main Express Lifts",
            busyness: busynessLevel(from: mainCrowdFactor),
            waitMinutes: Int(Double(busynessLevel(from: mainCrowdFactor).waitMinutes) * 1.2),
            reason: mainCrowdFactor > 0.7 ? "Primary access - expect lines" : "Main route up",
            confidence: 0.85
        ))

        // 2. Powder/Summit lifts (busy on powder days)
        let powderCrowdFactor = powderScore >= 6 ? crowdFactor * 1.4 : crowdFactor * 0.9
        predictions.append(LiftPrediction(
            liftName: "Powder/Summit Lifts",
            busyness: busynessLevel(from: powderCrowdFactor),
            waitMinutes: busynessLevel(from: powderCrowdFactor).waitMinutes,
            reason: powderScore >= 6 ? "Fresh powder attracts crowds" : "Expert terrain",
            confidence: powderScore >= 6 ? 0.9 : 0.7
        ))

        // 3. Beginner lifts (moderate, consistent)
        let beginnerCrowdFactor = crowdFactor * 0.8
        predictions.append(LiftPrediction(
            liftName: "Beginner Area",
            busyness: busynessLevel(from: beginnerCrowdFactor),
            waitMinutes: busynessLevel(from: beginnerCrowdFactor).waitMinutes,
            reason: "Beginner lessons and families",
            confidence: 0.75
        ))

        // 4. Side/Alternative lifts (lighter)
        let sideCrowdFactor = crowdFactor * 0.6
        predictions.append(LiftPrediction(
            liftName: "Side/Alternative Lifts",
            busyness: busynessLevel(from: sideCrowdFactor),
            waitMinutes: busynessLevel(from: sideCrowdFactor).waitMinutes,
            reason: percentOpen < 50 ? "Limited alternative routes" : "Less crowded option",
            confidence: 0.65
        ))

        // 5. Gondola/Tram (if exists - busiest on bad weather days)
        // TODO: Could enhance with actual wind data to adjust crowd factor
        let gondolaCrowdFactor = crowdFactor * 1.15 // Generally busy
        predictions.append(LiftPrediction(
            liftName: "Gondola/Enclosed Lifts",
            busyness: busynessLevel(from: gondolaCrowdFactor),
            waitMinutes: Int(Double(busynessLevel(from: gondolaCrowdFactor).waitMinutes) * 1.3),
            reason: "Preferred in cold/windy conditions",
            confidence: 0.8
        ))

        return predictions
    }

    // MARK: - Public Helper

    /// Gets a simple wait time estimate for display
    static func estimatedWaitTime(busyness: BusynessLevel) -> String {
        let minutes = busyness.waitMinutes
        if minutes == 0 {
            return "No wait"
        } else if minutes < 5 {
            return "\(minutes) min"
        } else if minutes < 15 {
            return "\(minutes) min"
        } else {
            return "\(minutes)+ min"
        }
    }

    /// Gets a user-friendly reason for current crowd levels
    static func crowdReason(
        powderScore: Int,
        currentTime: Date,
        isWeekend: Bool
    ) -> String {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)

        var reasons: [String] = []

        if powderScore >= 8 {
            reasons.append("Epic powder conditions")
        }

        if isWeekend {
            reasons.append("Weekend crowds")
        }

        if hour >= 9 && hour <= 10 {
            reasons.append("Morning rush hour")
        } else if hour >= 13 && hour <= 14 {
            reasons.append("Lunch lull")
        }

        if reasons.isEmpty {
            return "Typical conditions"
        } else {
            return reasons.joined(separator: " • ")
        }
    }
}
