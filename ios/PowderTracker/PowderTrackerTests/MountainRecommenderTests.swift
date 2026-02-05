import XCTest
@testable import PowderTracker

@MainActor
final class MountainRecommenderTests: XCTestCase {

    private var recommender: MountainRecommender!

    override func setUp() async throws {
        recommender = MountainRecommender.shared
        recommender.resetWeights()
    }

    // MARK: - Default Weights

    func testDefaultWeights_SumToOne() {
        let sum = recommender.weights.reduce(0, +)
        XCTAssertEqual(sum, 1.0, accuracy: 0.001, "Default weights should sum to 1.0")
    }

    func testDefaultWeights_Count() {
        XCTAssertEqual(recommender.weights.count, 5, "Should have 5 weight components")
    }

    func testDefaultWeights_ConditionsIsLargest() {
        XCTAssertEqual(recommender.weights[0], 0.35, accuracy: 0.001)
        XCTAssertTrue(recommender.weights[0] > recommender.weights[1])
        XCTAssertTrue(recommender.weights[0] > recommender.weights[2])
    }

    // MARK: - Terrain Match

    func testTerrainMatch_ExpertTreeSkier_BoostTreeMountains() {
        // Baker is known for trees+backcountry
        let score = recommender.terrainMatchScore(
            mountainId: "baker",
            userProfile: makeProfile(terrain: [.trees, .backcountry])
        )

        // Baker has [trees, backcountry, groomers] — 2 of 2 match = 100%
        XCTAssertEqual(score, 10.0, accuracy: 0.01,
                       "Expert tree skier should get perfect match with Baker")
    }

    func testTerrainMatch_ParkRider_LowMatchForTreeMountain() {
        // Baker doesn't have park terrain
        let score = recommender.terrainMatchScore(
            mountainId: "baker",
            userProfile: makeProfile(terrain: [.park])
        )

        // Baker has [trees, backcountry, groomers] — 0 of 1 match = 0%
        XCTAssertEqual(score, 0.0, accuracy: 0.01,
                       "Park rider should get no match with Baker")
    }

    func testTerrainMatch_NoProfile_ReturnsNeutral() {
        let score = recommender.terrainMatchScore(
            mountainId: "baker",
            userProfile: nil
        )

        XCTAssertEqual(score, 5.0, "No profile should return neutral score")
    }

    func testTerrainMatch_EmptyPreferences_ReturnsNeutral() {
        let score = recommender.terrainMatchScore(
            mountainId: "baker",
            userProfile: makeProfile(terrain: [])
        )

        XCTAssertEqual(score, 5.0, "Empty terrain preferences should return neutral score")
    }

    func testTerrainMatch_UnknownMountain_ReturnsNeutral() {
        let score = recommender.terrainMatchScore(
            mountainId: "unknown-mountain",
            userProfile: makeProfile(terrain: [.trees])
        )

        XCTAssertEqual(score, 5.0, "Unknown mountain should return neutral score")
    }

    // MARK: - Pass Boost

    func testPassBoost_IkonUser_IkonMountain() {
        let mountain = Mountain.mock(id: "crystal", name: "Crystal", shortName: "Crystal", passType: .ikon)
        let score = recommender.passBoostScore(
            mountain: mountain,
            userProfile: makeProfile(passType: .ikon)
        )

        XCTAssertEqual(score, 10.0, "Ikon user at Ikon mountain should get full boost")
    }

    func testPassBoost_EpicUser_IkonMountain() {
        let mountain = Mountain.mock(id: "crystal", name: "Crystal", shortName: "Crystal", passType: .ikon)
        let score = recommender.passBoostScore(
            mountain: mountain,
            userProfile: makeProfile(passType: .epic)
        )

        XCTAssertEqual(score, 0.0, "Epic user at Ikon mountain should get no boost")
    }

    func testPassBoost_NoProfile_ReturnsZero() {
        let mountain = Mountain.mock(id: "crystal", name: "Crystal", shortName: "Crystal", passType: .ikon)
        let score = recommender.passBoostScore(mountain: mountain, userProfile: nil)

        XCTAssertEqual(score, 0.0, "No profile should get no pass boost")
    }

    func testPassBoost_MountainNoPass_ReturnsZero() {
        let mountain = Mountain.mock(id: "baker", name: "Baker", shortName: "Baker", passType: nil)
        let score = recommender.passBoostScore(
            mountain: mountain,
            userProfile: makeProfile(passType: .ikon)
        )

        XCTAssertEqual(score, 0.0, "Mountain with no pass should get no boost")
    }

    // MARK: - Historical Score

    func testHistoricalScore_HighRatings_HighScore() {
        let checkIns = [
            makeCheckIn(mountainId: "baker", rating: 5),
            makeCheckIn(mountainId: "baker", rating: 4),
            makeCheckIn(mountainId: "baker", rating: 5),
        ]

        let score = recommender.historicalScore(mountainId: "baker", checkIns: checkIns)

        // Average = (5+4+5)/3 ≈ 4.67, × 2 ≈ 9.33
        XCTAssertGreaterThan(score, 8.0, "High past ratings should produce high historical score")
    }

    func testHistoricalScore_LowRatings_LowScore() {
        let checkIns = [
            makeCheckIn(mountainId: "baker", rating: 1),
            makeCheckIn(mountainId: "baker", rating: 2),
        ]

        let score = recommender.historicalScore(mountainId: "baker", checkIns: checkIns)

        // Average = 1.5, × 2 = 3.0
        XCTAssertLessThan(score, 4.0, "Low past ratings should produce low historical score")
    }

    func testHistoricalScore_NoHistory_ReturnsNeutral() {
        let score = recommender.historicalScore(mountainId: "baker", checkIns: [])

        XCTAssertEqual(score, 5.0, "No check-in history should return neutral score")
    }

    func testHistoricalScore_OnlyOtherMountains_ReturnsNeutral() {
        let checkIns = [
            makeCheckIn(mountainId: "crystal", rating: 5),
            makeCheckIn(mountainId: "stevens", rating: 4),
        ]

        let score = recommender.historicalScore(mountainId: "baker", checkIns: checkIns)

        XCTAssertEqual(score, 5.0, "Check-ins at other mountains should not affect Baker's score")
    }

    func testHistoricalScore_CheckInsWithoutRating_Ignored() {
        let checkIns = [
            makeCheckIn(mountainId: "baker", rating: nil),
            makeCheckIn(mountainId: "baker", rating: 5),
        ]

        let score = recommender.historicalScore(mountainId: "baker", checkIns: checkIns)

        // Only the one rated check-in: 5 × 2 = 10.0
        XCTAssertEqual(score, 10.0, accuracy: 0.01)
    }

    // MARK: - Similar Users

    func testSimilarUsersScore_ReturnsNeutralBaseline() {
        let score = recommender.similarUsersScore()
        XCTAssertEqual(score, 5.0, "Similar users score should return neutral baseline (future feature)")
    }

    // MARK: - Weight Learning

    func testLearnFromCheckIn_PositiveError_BumpsWeights() {
        let originalWeights = recommender.weights

        let prevScore = RecommendationScore(
            mountain: Mountain.mock(id: "baker"),
            totalScore: 5.0,
            conditionsScore: 8.0,
            terrainMatchScore: 7.0,
            historicalScore: 5.0,
            passBoost: 0.0,
            reasons: []
        )

        // User rates 5/5 = 10.0 (normalized), model predicted 5.0 → error = +5.0
        recommender.learnFromCheckIn(
            mountainId: "baker",
            rating: 5,
            previousScore: prevScore
        )

        // Weights should have shifted — conditions weight (strongest factor) should increase
        XCTAssertNotEqual(recommender.weights, originalWeights, "Weights should change after learning")

        // Sum should still be ~1.0
        let sum = recommender.weights.reduce(0, +)
        XCTAssertEqual(sum, 1.0, accuracy: 0.01, "Weights should stay normalized after learning")
    }

    func testLearnFromCheckIn_NoPreviousScore_NoChange() {
        let originalWeights = recommender.weights

        recommender.learnFromCheckIn(
            mountainId: "baker",
            rating: 5,
            previousScore: nil
        )

        XCTAssertEqual(recommender.weights, originalWeights, "No previous score should not change weights")
    }

    func testResetWeights_RestoresDefaults() {
        // Modify weights via learning
        let prevScore = RecommendationScore(
            mountain: Mountain.mock(id: "baker"),
            totalScore: 5.0,
            conditionsScore: 8.0,
            terrainMatchScore: 7.0,
            historicalScore: 5.0,
            passBoost: 0.0,
            reasons: []
        )
        recommender.learnFromCheckIn(mountainId: "baker", rating: 5, previousScore: prevScore)

        // Reset
        recommender.resetWeights()

        XCTAssertEqual(recommender.weights[0], 0.35, accuracy: 0.001)
        XCTAssertEqual(recommender.weights[1], 0.25, accuracy: 0.001)
        XCTAssertEqual(recommender.weights[2], 0.20, accuracy: 0.001)
        XCTAssertEqual(recommender.weights[3], 0.10, accuracy: 0.001)
        XCTAssertEqual(recommender.weights[4], 0.10, accuracy: 0.001)
    }

    // MARK: - Mountain Terrain Tags

    func testMountainTerrainTags_BakerHasTrees() {
        let tags = MountainRecommender.mountainTerrainTags["baker"]
        XCTAssertNotNil(tags)
        XCTAssertTrue(tags!.contains(.trees))
        XCTAssertTrue(tags!.contains(.backcountry))
    }

    func testMountainTerrainTags_StevensHasPark() {
        let tags = MountainRecommender.mountainTerrainTags["stevens"]
        XCTAssertNotNil(tags)
        XCTAssertTrue(tags!.contains(.park))
    }

    // MARK: - Helpers

    private func makeProfile(
        terrain: [TerrainType] = [],
        passType: SeasonPassType = .none,
        experienceLevel: ExperienceLevel = .intermediate
    ) -> UserProfile {
        UserProfile(
            id: "test-user",
            authUserId: "auth-test",
            username: "testuser",
            email: "test@test.com",
            displayName: "Test User",
            bio: nil,
            avatarUrl: nil,
            homeMountainId: nil,
            createdAt: Date(),
            updatedAt: Date(),
            lastLoginAt: nil,
            isActive: true,
            hasCompletedOnboarding: true,
            ridingStyle: "skier",
            experienceLevel: experienceLevel.rawValue,
            preferredTerrain: terrain.map(\.rawValue),
            seasonPassType: passType.rawValue,
            onboardingCompletedAt: nil,
            onboardingSkippedAt: nil
        )
    }

    private func makeCheckIn(mountainId: String, rating: Int?) -> CheckIn {
        CheckIn(
            id: UUID().uuidString,
            userId: "test-user",
            mountainId: mountainId,
            checkInTime: Date(),
            checkOutTime: nil,
            tripReport: nil,
            rating: rating,
            snowQuality: nil,
            crowdLevel: nil,
            weatherConditions: nil,
            likesCount: 0,
            commentsCount: 0,
            isPublic: true,
            user: nil
        )
    }
}
