import Foundation

// MARK: - Arrival Time Recommendation

struct ArrivalTimeRecommendation: Codable, Identifiable {
    var id: String { mountainId }

    let mountainId: String
    let mountainName: String
    let generated: String
    let recommendedArrivalTime: String
    let arrivalWindow: ArrivalWindow
    let confidence: Confidence
    let reasoning: [String]
    let factors: ArrivalFactors
    let alternatives: [AlternativeTime]
    let tips: [String]

    enum Confidence: String, Codable {
        case high
        case medium
        case low

        var displayName: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .high: return "green"
            case .medium: return "orange"
            case .low: return "red"
            }
        }

        var icon: String {
            switch self {
            case .high: return "checkmark.circle.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .low: return "questionmark.circle.fill"
            }
        }
    }

    struct ArrivalWindow: Codable {
        let earliest: String
        let optimal: String
        let latest: String
    }

    struct ArrivalFactors: Codable {
        let expectedCrowdLevel: CrowdLevel
        let roadConditions: RoadConditionLevel
        let weatherQuality: WeatherQuality
        let powderFreshness: PowderFreshness
        let parkingDifficulty: ParkingDifficulty

        enum CrowdLevel: String, Codable {
            case low
            case medium
            case high
            case extreme

            var displayName: String { rawValue.capitalized }
            var icon: String { "person.3.fill" }
            var color: String {
                switch self {
                case .low: return "green"
                case .medium: return "yellow"
                case .high: return "orange"
                case .extreme: return "red"
                }
            }
        }

        enum RoadConditionLevel: String, Codable {
            case clear
            case snow
            case ice
            case chainsRequired = "chains-required"

            var displayName: String {
                switch self {
                case .clear: return "Clear"
                case .snow: return "Snow"
                case .ice: return "Ice"
                case .chainsRequired: return "Chains Req'd"
                }
            }
            var icon: String { "car.fill" }
            var color: String {
                switch self {
                case .clear: return "green"
                case .snow: return "yellow"
                case .ice: return "orange"
                case .chainsRequired: return "red"
                }
            }
        }

        enum WeatherQuality: String, Codable {
            case excellent
            case good
            case fair
            case poor

            var displayName: String { rawValue.capitalized }
            var icon: String { "cloud.sun.fill" }
            var color: String {
                switch self {
                case .excellent: return "green"
                case .good: return "blue"
                case .fair: return "orange"
                case .poor: return "red"
                }
            }
        }

        enum PowderFreshness: String, Codable {
            case fresh
            case trackedOut = "tracked-out"
            case packed

            var displayName: String {
                switch self {
                case .fresh: return "Fresh"
                case .trackedOut: return "Tracked Out"
                case .packed: return "Packed"
                }
            }
            var icon: String { "snow" }
            var color: String {
                switch self {
                case .fresh: return "green"
                case .trackedOut: return "yellow"
                case .packed: return "orange"
                }
            }
        }

        enum ParkingDifficulty: String, Codable {
            case easy
            case moderate
            case challenging
            case veryDifficult = "very-difficult"

            var displayName: String {
                switch self {
                case .easy: return "Easy"
                case .moderate: return "Moderate"
                case .challenging: return "Challenging"
                case .veryDifficult: return "Very Difficult"
                }
            }
            var icon: String { "parkingsign.circle.fill" }
            var color: String {
                switch self {
                case .easy: return "green"
                case .moderate: return "yellow"
                case .challenging: return "orange"
                case .veryDifficult: return "red"
                }
            }
        }
    }

    struct AlternativeTime: Codable, Identifiable {
        var id: String { time }
        let time: String
        let description: String
        let tradeoff: String
    }
}

// MARK: - Mock Data

#if DEBUG
extension ArrivalTimeRecommendation {
    static let mock = ArrivalTimeRecommendation(
        mountainId: "baker",
        mountainName: "Mt. Baker",
        generated: ISO8601DateFormatter().string(from: Date()),
        recommendedArrivalTime: "7:30 AM",
        arrivalWindow: ArrivalWindow(
            earliest: "6:30 AM",
            optimal: "7:30 AM",
            latest: "8:30 AM"
        ),
        confidence: .high,
        reasoning: [
            "Fresh powder overnight (8\" new snow) - arrive early for first tracks",
            "Weekend crowds expected - parking fills by 9:00 AM",
            "Lift opens at 9:00 AM - arrive 90 min early to gear up",
            "Road conditions require chains - add 20 min to drive time"
        ],
        factors: ArrivalFactors(
            expectedCrowdLevel: .high,
            roadConditions: .chainsRequired,
            weatherQuality: .excellent,
            powderFreshness: .fresh,
            parkingDifficulty: .challenging
        ),
        alternatives: [
            AlternativeTime(
                time: "9:00 AM",
                description: "Sleep in option",
                tradeoff: "Avoid early morning drive but miss first tracks and fight for parking"
            ),
            AlternativeTime(
                time: "12:00 PM",
                description: "Midday arrival",
                tradeoff: "Better road conditions and parking, but powder will be tracked out"
            )
        ],
        tips: [
            "Bring tire chains - required by law",
            "Fill gas tank before heading up - last station 30 miles away",
            "Pack breakfast to eat in parking lot while gearing up",
            "Upper parking lot closest to lifts - aim for that",
            "Check webcams for real-time parking status"
        ]
    )
}
#endif
