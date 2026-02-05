import XCTest
@testable import PowderTracker

@MainActor
final class SentimentAnalyzerTests: XCTestCase {

    // MARK: - Basic Analysis Tests

    func testAnalyze_PositiveText_ShouldReturnPositive() {
        // Given
        let text = "Amazing powder day! Best skiing of the season, absolutely loved it!"

        // When
        let result = SentimentAnalyzer.shared.analyze(text)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, .positive)
        XCTAssertGreaterThan(result?.score ?? -1, 0)
    }

    func testAnalyze_NegativeText_ShouldReturnNegative() {
        // Given
        let text = "Terrible conditions. Icy, overcrowded, long lift lines. Worst day ever."

        // When
        let result = SentimentAnalyzer.shared.analyze(text)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, .negative)
        XCTAssertLessThan(result?.score ?? 1, 0)
    }

    func testAnalyze_ShortText_ShouldReturnNil() {
        // Given
        let text = "OK"

        // When
        let result = SentimentAnalyzer.shared.analyze(text)

        // Then - text under 5 chars returns nil
        XCTAssertNil(result)
    }

    func testAnalyze_EmptyText_ShouldReturnNil() {
        // Given
        let text = ""

        // When
        let result = SentimentAnalyzer.shared.analyze(text)

        // Then
        XCTAssertNil(result)
    }

    func testAnalyze_WhitespaceOnly_ShouldReturnNil() {
        // Given
        let text = "   \n  "

        // When
        let result = SentimentAnalyzer.shared.analyze(text)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Score Range Tests

    func testAnalyze_ScoreInValidRange() {
        // Given
        let texts = [
            "Great powder day, really enjoyed the fresh snow!",
            "Average conditions, nothing special",
            "Awful icy conditions, very dangerous"
        ]

        for text in texts {
            // When
            let result = SentimentAnalyzer.shared.analyze(text)

            // Then
            if let result {
                XCTAssertGreaterThanOrEqual(result.score, -1.0, "Score should be >= -1.0 for: \(text)")
                XCTAssertLessThanOrEqual(result.score, 1.0, "Score should be <= 1.0 for: \(text)")
            }
        }
    }

    // MARK: - SentimentResult Tests

    func testSentimentResult_PositiveThreshold() {
        let result = SentimentResult(score: 0.5)
        XCTAssertEqual(result.label, .positive)
    }

    func testSentimentResult_NegativeThreshold() {
        let result = SentimentResult(score: -0.5)
        XCTAssertEqual(result.label, .negative)
    }

    func testSentimentResult_NeutralThreshold() {
        let result = SentimentResult(score: 0.05)
        XCTAssertEqual(result.label, .neutral)
    }

    func testSentimentResult_BoundaryPositive() {
        // Score of exactly 0.1 is neutral (needs to be > 0.1 for positive)
        let result = SentimentResult(score: 0.1)
        XCTAssertEqual(result.label, .neutral)
    }

    func testSentimentResult_BoundaryNegative() {
        // Score of exactly -0.1 is neutral (needs to be < -0.1 for negative)
        let result = SentimentResult(score: -0.1)
        XCTAssertEqual(result.label, .neutral)
    }

    // MARK: - SentimentLabel Tests

    func testSentimentLabel_Icons() {
        XCTAssertEqual(SentimentLabel.positive.icon, "face.smiling")
        XCTAssertEqual(SentimentLabel.neutral.icon, "face.dashed")
        XCTAssertEqual(SentimentLabel.negative.icon, "cloud.rain")
    }

    func testSentimentLabel_DisplayNames() {
        XCTAssertEqual(SentimentLabel.positive.displayName, "Positive")
        XCTAssertEqual(SentimentLabel.neutral.displayName, "Neutral")
        XCTAssertEqual(SentimentLabel.negative.displayName, "Negative")
    }

    // MARK: - CommunityVibe Tests

    func testCommunityVibe_Summary() {
        // Given
        let vibe = CommunityVibe(
            averageScore: 0.5,
            totalAnalyzed: 10,
            positiveCount: 7,
            negativeCount: 1,
            neutralCount: 2
        )

        // Then
        XCTAssertEqual(vibe.label, .positive)
        XCTAssertEqual(vibe.summary, "70% positive from 10 reports")
    }

    func testCommunityVibe_NegativeAverage() {
        // Given
        let vibe = CommunityVibe(
            averageScore: -0.3,
            totalAnalyzed: 5,
            positiveCount: 1,
            negativeCount: 3,
            neutralCount: 1
        )

        // Then
        XCTAssertEqual(vibe.label, .negative)
        XCTAssertEqual(vibe.summary, "20% positive from 5 reports")
    }

    func testCommunityVibe_NeutralAverage() {
        // Given
        let vibe = CommunityVibe(
            averageScore: 0.0,
            totalAnalyzed: 4,
            positiveCount: 2,
            negativeCount: 2,
            neutralCount: 0
        )

        // Then
        XCTAssertEqual(vibe.label, .neutral)
        XCTAssertEqual(vibe.summary, "50% positive from 4 reports")
    }

    // MARK: - CheckIn Integration Tests

    @MainActor
    func testAnalyzeCheckIn_WithTripReport() {
        // Given
        let checkIn = CheckIn(
            id: "test-1",
            userId: "user-1",
            mountainId: "baker",
            checkInTime: Date(),
            checkOutTime: nil,
            tripReport: "Incredible day! Best powder of the year, couldn't be happier!",
            rating: 5,
            snowQuality: "powder",
            crowdLevel: "light",
            weatherConditions: nil,
            likesCount: 0,
            commentsCount: 0,
            isPublic: true,
            user: nil
        )

        // When
        let result = SentimentAnalyzer.shared.analyzeCheckIn(checkIn)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.label, .positive)
    }

    @MainActor
    func testAnalyzeCheckIn_WithoutTripReport_ShouldReturnNil() {
        // Given
        let checkIn = CheckIn(
            id: "test-2",
            userId: "user-1",
            mountainId: "baker",
            checkInTime: Date(),
            checkOutTime: nil,
            tripReport: nil,
            rating: 3,
            snowQuality: nil,
            crowdLevel: nil,
            weatherConditions: nil,
            likesCount: 0,
            commentsCount: 0,
            isPublic: true,
            user: nil
        )

        // When
        let result = SentimentAnalyzer.shared.analyzeCheckIn(checkIn)

        // Then
        XCTAssertNil(result)
    }

    @MainActor
    func testAnalyzeCheckIn_CachesResult() {
        // Given
        let checkIn = CheckIn(
            id: "cache-test",
            userId: "user-1",
            mountainId: "baker",
            checkInTime: Date(),
            checkOutTime: nil,
            tripReport: "Super fun day on the mountain, loved the fresh snow!",
            rating: 4,
            snowQuality: "powder",
            crowdLevel: "moderate",
            weatherConditions: nil,
            likesCount: 0,
            commentsCount: 0,
            isPublic: true,
            user: nil
        )

        // When
        let result1 = SentimentAnalyzer.shared.analyzeCheckIn(checkIn)
        let result2 = SentimentAnalyzer.shared.analyzeCheckIn(checkIn)

        // Then - should return same result (cached)
        XCTAssertEqual(result1, result2)
    }

    @MainActor
    func testCommunityVibe_WithMixedCheckIns() {
        // Given
        let checkIns = [
            makeCheckIn(id: "1", report: "Amazing powder! Best day ever, so much fun!"),
            makeCheckIn(id: "2", report: "Great conditions, really enjoyed the fresh tracks!"),
            makeCheckIn(id: "3", report: nil),
            makeCheckIn(id: "4", report: "Horrible icy conditions, dangerous and overcrowded"),
            makeCheckIn(id: "5", report: "Pretty good day overall, nice and sunny")
        ]

        // When
        let vibe = SentimentAnalyzer.shared.communityVibe(for: checkIns)

        // Then
        XCTAssertNotNil(vibe)
        // Should have analyzed 4 (one has nil trip report)
        XCTAssertEqual(vibe?.totalAnalyzed, 4)
        XCTAssertEqual(
            (vibe?.positiveCount ?? 0) + (vibe?.negativeCount ?? 0) + (vibe?.neutralCount ?? 0),
            vibe?.totalAnalyzed ?? -1
        )
    }

    @MainActor
    func testCommunityVibe_EmptyCheckIns_ShouldReturnNil() {
        // When
        let vibe = SentimentAnalyzer.shared.communityVibe(for: [])

        // Then
        XCTAssertNil(vibe)
    }

    @MainActor
    func testClearCache() {
        // Given
        let checkIn = makeCheckIn(id: "clear-test", report: "Great day skiing!")
        _ = SentimentAnalyzer.shared.analyzeCheckIn(checkIn)

        // When
        SentimentAnalyzer.shared.clearCache()

        // Then - should still work after clearing (just re-analyzes)
        let result = SentimentAnalyzer.shared.analyzeCheckIn(checkIn)
        XCTAssertNotNil(result)
    }

    // MARK: - Helpers

    private func makeCheckIn(id: String, report: String?) -> CheckIn {
        CheckIn(
            id: id,
            userId: "user-1",
            mountainId: "baker",
            checkInTime: Date(),
            checkOutTime: nil,
            tripReport: report,
            rating: nil,
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
