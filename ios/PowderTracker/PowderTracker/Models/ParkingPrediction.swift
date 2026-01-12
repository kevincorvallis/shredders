import Foundation

// MARK: - Parking Prediction Response

struct ParkingPredictionResponse: Codable {
    let mountain: MountainInfo
    let generated: String
    let difficulty: ParkingDifficulty
    let confidence: Confidence
    let recommendedArrivalTime: String
    let recommendedLots: [ParkingLotRecommendation]
    let tips: [String]
    let reservationUrl: String?
    let reservationRequired: Bool
    let headline: String
    let context: ParkingContext?
}

// MARK: - Parking Difficulty

enum ParkingDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case moderate = "moderate"
    case challenging = "challenging"
    case veryDifficult = "very-difficult"

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .challenging: return "Challenging"
        case .veryDifficult: return "Very Difficult"
        }
    }

    var icon: String {
        switch self {
        case .easy: return "checkmark.circle.fill"
        case .moderate: return "exclamationmark.circle.fill"
        case .challenging: return "exclamationmark.triangle.fill"
        case .veryDifficult: return "xmark.octagon.fill"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .moderate: return "yellow"
        case .challenging: return "orange"
        case .veryDifficult: return "red"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Parking should be readily available"
        case .moderate: return "Parking may be limited later in the morning"
        case .challenging: return "Expect parking to fill up - arrive early"
        case .veryDifficult: return "Parking will be extremely limited"
        }
    }
}

// MARK: - Confidence Level

enum Confidence: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var color: String {
        switch self {
        case .high: return "green"
        case .medium: return "yellow"
        case .low: return "gray"
        }
    }
}

// MARK: - Parking Lot Recommendation

struct ParkingLotRecommendation: Codable, Identifiable {
    var id: String { name }

    let name: String
    let type: LotType
    let capacity: LotCapacity
    let distanceToLift: String
    let notes: String?
    let availability: LotAvailability
    let arrivalTime: String?
}

enum LotType: String, Codable {
    case main = "main"
    case overflow = "overflow"
    case premium = "premium"
    case shuttle = "shuttle"

    var displayName: String {
        switch self {
        case .main: return "Main Lot"
        case .overflow: return "Overflow Lot"
        case .premium: return "Premium Lot"
        case .shuttle: return "Shuttle Lot"
        }
    }

    var icon: String {
        switch self {
        case .main: return "parkingsign.circle.fill"
        case .overflow: return "arrow.forward.circle.fill"
        case .premium: return "star.circle.fill"
        case .shuttle: return "bus.fill"
        }
    }

    var color: String {
        switch self {
        case .main: return "blue"
        case .overflow: return "orange"
        case .premium: return "purple"
        case .shuttle: return "green"
        }
    }
}

enum LotCapacity: String, Codable {
    case large = "large"
    case medium = "medium"
    case small = "small"

    var displayName: String {
        switch self {
        case .large: return "Large"
        case .medium: return "Medium"
        case .small: return "Small"
        }
    }
}

enum LotAvailability: String, Codable {
    case likely = "likely"
    case limited = "limited"
    case full = "full"

    var displayName: String {
        switch self {
        case .likely: return "Likely Available"
        case .limited: return "Limited Availability"
        case .full: return "Expected to Fill"
        }
    }

    var icon: String {
        switch self {
        case .likely: return "checkmark.circle.fill"
        case .limited: return "exclamationmark.circle.fill"
        case .full: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .likely: return "green"
        case .limited: return "yellow"
        case .full: return "red"
        }
    }
}

// MARK: - Parking Context

struct ParkingContext: Codable {
    let powderScore: Double?
    let upcomingSnow48h: Double?
    let isWeekend: Bool
    let isHolidayWindow: Bool
    let currentHour: Int
}

// MARK: - Mock Data for Previews

extension ParkingPredictionResponse {
    static var mock: ParkingPredictionResponse {
        ParkingPredictionResponse(
            mountain: MountainInfo(id: "stevens", name: "Stevens Pass", shortName: "Stevens"),
            generated: ISO8601DateFormatter().string(from: Date()),
            difficulty: .challenging,
            confidence: .high,
            recommendedArrivalTime: "Before 7:30 AM",
            recommendedLots: [
                ParkingLotRecommendation(
                    name: "Lot G",
                    type: .main,
                    capacity: .large,
                    distanceToLift: "0.1 mi",
                    notes: "Reservation required until 10am on weekends/holidays",
                    availability: .limited,
                    arrivalTime: "Before 8 AM"
                ),
                ParkingLotRecommendation(
                    name: "Lot A",
                    type: .main,
                    capacity: .large,
                    distanceToLift: "0.2 mi",
                    notes: "Reservation required until 10am on weekends/holidays",
                    availability: .limited,
                    arrivalTime: "Before 8 AM"
                ),
                ParkingLotRecommendation(
                    name: "Lot E",
                    type: .overflow,
                    capacity: .medium,
                    distanceToLift: "0.4 mi",
                    notes: "Reservation required until 10am on weekends/holidays",
                    availability: .likely,
                    arrivalTime: "After 9 AM often available"
                ),
            ],
            tips: [
                "Reserve N Ski: $20 reservation or free after 10am",
                "Free reservations: 4+ carpool, 1 adult + 2 kids, ADA, lesson participants",
                "Lots may fill up - aim for early arrival",
                "Book at parkstevenspass.com",
            ],
            reservationUrl: "https://www.parkstevenspass.com",
            reservationRequired: true,
            headline: "Reserve parking or arrive early",
            context: ParkingContext(
                powderScore: 7.5,
                upcomingSnow48h: 8.0,
                isWeekend: true,
                isHolidayWindow: false,
                currentHour: 6
            )
        )
    }

    static var mockEasy: ParkingPredictionResponse {
        ParkingPredictionResponse(
            mountain: MountainInfo(id: "bachelor", name: "Mt. Bachelor", shortName: "Bachelor"),
            generated: ISO8601DateFormatter().string(from: Date()),
            difficulty: .easy,
            confidence: .high,
            recommendedArrivalTime: "Standard arrival time (8-9 AM) should be fine",
            recommendedLots: [
                ParkingLotRecommendation(
                    name: "West Village",
                    type: .main,
                    capacity: .large,
                    distanceToLift: "0.1 mi",
                    notes: "Main base area, closest to lifts",
                    availability: .likely,
                    arrivalTime: "Before 8 AM"
                ),
                ParkingLotRecommendation(
                    name: "Sunrise Lodge",
                    type: .main,
                    capacity: .large,
                    distanceToLift: "0.2 mi",
                    notes: "East side base area",
                    availability: .likely,
                    arrivalTime: "Before 8 AM"
                ),
            ],
            tips: [
                "Free parking, no reservations required",
                "Free Interlodge shuttle connects all lots and base areas",
                "Rarely fills up, even on powder days",
            ],
            reservationUrl: nil,
            reservationRequired: false,
            headline: "Parking should be available",
            context: ParkingContext(
                powderScore: 5.0,
                upcomingSnow48h: 4.0,
                isWeekend: false,
                isHolidayWindow: false,
                currentHour: 7
            )
        )
    }
}
