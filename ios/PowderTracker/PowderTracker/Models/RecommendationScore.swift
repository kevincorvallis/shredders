import Foundation

/// A personalized recommendation score for a mountain, combining conditions,
/// terrain preference, historical satisfaction, and pass accessibility.
struct RecommendationScore: Equatable, Identifiable {
    var id: String { mountain.id }

    let mountain: Mountain
    /// Overall composite score (0-10 scale).
    let totalScore: Double
    /// Conditions sub-score: powder + parking + crowd + lifts.
    let conditionsScore: Double
    /// How well the mountain matches the user's preferred terrain.
    let terrainMatchScore: Double
    /// Average rating from user's past check-ins at this mountain.
    let historicalScore: Double
    /// Boost for pass compatibility (0 or positive).
    let passBoost: Double
    /// Human-readable reasons for the recommendation (e.g. ["12\" fresh", "Your Ikon pass"]).
    let reasons: [String]
}
