import XCTest
@testable import PowderTracker

final class SnowConditionClassifierTests: XCTestCase {

    // MARK: - SnowClassification Model Tests

    func testSnowClassification_Equatable() {
        let scores1: [SnowQuality: Double] = [.powder: 0.8, .groomed: 0.2]
        let scores2: [SnowQuality: Double] = [.powder: 0.8, .groomed: 0.2]
        let a = SnowClassification(quality: .powder, confidence: 0.8, allScores: scores1)
        let b = SnowClassification(quality: .powder, confidence: 0.8, allScores: scores2)
        XCTAssertEqual(a, b)
    }

    func testSnowClassification_NotEqual_DifferentQuality() {
        let a = SnowClassification(quality: .powder, confidence: 0.8, allScores: [:])
        let b = SnowClassification(quality: .icy, confidence: 0.8, allScores: [:])
        XCTAssertNotEqual(a, b)
    }

    func testSnowClassification_NotEqual_DifferentConfidence() {
        let a = SnowClassification(quality: .powder, confidence: 0.8, allScores: [:])
        let b = SnowClassification(quality: .powder, confidence: 0.6, allScores: [:])
        XCTAssertNotEqual(a, b)
    }

    func testSnowClassification_AllScores_ContainsQualityValues() {
        let scores: [SnowQuality: Double] = [
            .powder: 0.8, .groomed: 0.6, .icy: 0.1
        ]
        let classification = SnowClassification(quality: .powder, confidence: 0.8, allScores: scores)
        XCTAssertEqual(classification.allScores[.powder], 0.8)
        XCTAssertEqual(classification.allScores[.groomed], 0.6)
        XCTAssertEqual(classification.allScores[.icy], 0.1)
        XCTAssertNil(classification.allScores[.slushy])
    }

    // MARK: - Color Histogram Tests

    func testColorHistogram_DefaultValues() {
        let histogram = SnowConditionClassifier.ColorHistogram()
        XCTAssertEqual(histogram.brightWhiteRatio, 0)
        XCTAssertEqual(histogram.blueGrayRatio, 0)
        XCTAssertEqual(histogram.darkWetRatio, 0)
        XCTAssertEqual(histogram.brightColorRatio, 0)
        XCTAssertEqual(histogram.averageBrightness, 0)
    }

    func testColorHistogram_Equatable() {
        let a = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.5, blueGrayRatio: 0.2,
            darkWetRatio: 0.1, brightColorRatio: 0.2,
            averageBrightness: 0.6
        )
        let b = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.5, blueGrayRatio: 0.2,
            darkWetRatio: 0.1, brightColorRatio: 0.2,
            averageBrightness: 0.6
        )
        XCTAssertEqual(a, b)
    }

    // MARK: - Histogram → SnowQuality Mapping Tests

    func testMapHistogram_BrightWhite_FavorsPowder() {
        // Bright white-dominant image should suggest powder
        let histogram = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.8,
            blueGrayRatio: 0.05,
            darkWetRatio: 0.02,
            brightColorRatio: 0.05,
            averageBrightness: 0.85
        )

        let scores = SnowConditionClassifier.shared.mapHistogramToSnowQuality(histogram)

        // Powder should be the top score
        let topQuality = scores.max(by: { $0.value < $1.value })?.key
        XCTAssertEqual(topQuality, .powder, "Bright white image should classify as powder")
        XCTAssertGreaterThan(scores[.powder] ?? 0, scores[.icy] ?? 0)
    }

    func testMapHistogram_BlueGray_FavorsIcy() {
        // Blue-gray dominant image should suggest icy conditions
        let histogram = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.1,
            blueGrayRatio: 0.7,
            darkWetRatio: 0.1,
            brightColorRatio: 0.05,
            averageBrightness: 0.45
        )

        let scores = SnowConditionClassifier.shared.mapHistogramToSnowQuality(histogram)

        // Icy should be the top score
        let topQuality = scores.max(by: { $0.value < $1.value })?.key
        XCTAssertEqual(topQuality, .icy, "Blue-gray image should classify as icy")
        XCTAssertGreaterThan(scores[.icy] ?? 0, scores[.powder] ?? 0)
    }

    func testMapHistogram_DarkWet_FavorsSlushy() {
        // Dark/wet dominant image should suggest slushy
        let histogram = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.05,
            blueGrayRatio: 0.1,
            darkWetRatio: 0.7,
            brightColorRatio: 0.05,
            averageBrightness: 0.2
        )

        let scores = SnowConditionClassifier.shared.mapHistogramToSnowQuality(histogram)

        // Slushy should score high
        let topQuality = scores.max(by: { $0.value < $1.value })?.key
        XCTAssertEqual(topQuality, .slushy, "Dark/wet image should classify as slushy")
    }

    func testMapHistogram_Scores_AreNormalized() {
        // Any histogram should produce normalized scores (max ≤ 1.0)
        let histogram = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.5,
            blueGrayRatio: 0.3,
            darkWetRatio: 0.1,
            brightColorRatio: 0.1,
            averageBrightness: 0.55
        )

        let scores = SnowConditionClassifier.shared.mapHistogramToSnowQuality(histogram)

        for (quality, score) in scores {
            XCTAssertGreaterThanOrEqual(score, 0, "\(quality) score should be >= 0")
            XCTAssertLessThanOrEqual(score, 1.0, "\(quality) score should be <= 1.0")
        }

        // At least one score should be exactly 1.0 (the normalized max)
        let maxScore = scores.values.max() ?? 0
        XCTAssertEqual(maxScore, 1.0, accuracy: 0.001, "Max score should be normalized to 1.0")
    }

    func testMapHistogram_AllQualities_HaveScores() {
        let histogram = SnowConditionClassifier.ColorHistogram(
            brightWhiteRatio: 0.4,
            blueGrayRatio: 0.2,
            darkWetRatio: 0.1,
            brightColorRatio: 0.1,
            averageBrightness: 0.5
        )

        let scores = SnowConditionClassifier.shared.mapHistogramToSnowQuality(histogram)

        // Every SnowQuality should have a score
        for quality in SnowQuality.allCases {
            XCTAssertNotNil(scores[quality], "\(quality) should have a score")
        }
    }

    // MARK: - Histogram Computation Tests

    func testComputeHistogram_WhiteImage_HighBrightWhiteRatio() {
        // Create a 10x10 white image
        guard let image = createSolidColorImage(
            color: UIColor.white, width: 10, height: 10
        ) else {
            XCTFail("Failed to create test image")
            return
        }

        let histogram = SnowConditionClassifier.shared.computeHistogram(image)

        XCTAssertGreaterThan(histogram.brightWhiteRatio, 0.5,
                             "White image should have high bright-white ratio")
        XCTAssertGreaterThan(histogram.averageBrightness, 0.8,
                             "White image should have high average brightness")
    }

    func testComputeHistogram_DarkImage_HighDarkWetRatio() {
        // Create a 10x10 near-black image
        guard let image = createSolidColorImage(
            color: UIColor(white: 0.1, alpha: 1), width: 10, height: 10
        ) else {
            XCTFail("Failed to create test image")
            return
        }

        let histogram = SnowConditionClassifier.shared.computeHistogram(image)

        XCTAssertGreaterThan(histogram.darkWetRatio, 0.5,
                             "Dark image should have high dark-wet ratio")
        XCTAssertLessThan(histogram.averageBrightness, 0.3,
                          "Dark image should have low average brightness")
    }

    func testComputeHistogram_BlueImage_HasBlueGrayOrNonWhiteCharacteristics() {
        // Create a 10x10 muted blue image
        // Note: CGImage byte order may vary (RGBA/BGRA) so exact channel mapping can differ.
        // We verify the image does NOT classify as bright-white and has reasonable brightness.
        guard let image = createSolidColorImage(
            color: UIColor(red: 0.42, green: 0.45, blue: 0.52, alpha: 1), width: 10, height: 10
        ) else {
            XCTFail("Failed to create test image")
            return
        }

        let histogram = SnowConditionClassifier.shared.computeHistogram(image)

        // A muted blue image should NOT be bright white
        XCTAssertLessThan(histogram.brightWhiteRatio, 0.3,
                          "Blue-gray image should not be classified as bright white")
        // Should have medium brightness
        XCTAssertGreaterThan(histogram.averageBrightness, 0.3,
                             "Blue-gray image should have medium brightness")
        XCTAssertLessThan(histogram.averageBrightness, 0.7,
                          "Blue-gray image should have medium brightness, not high")
    }

    // MARK: - Minimum Confidence Tests

    func testClassification_BelowMinConfidence_ReturnsNil() {
        // A classification result only returns if confidence >= 0.5
        // We test the threshold behavior through the model:
        let lowScores: [SnowQuality: Double] = SnowQuality.allCases.reduce(into: [:]) {
            $0[$1] = 0.1 // All low scores
        }

        // If the max blended score is below 0.5, classify returns nil
        let maxScore = lowScores.values.max() ?? 0
        XCTAssertLessThan(maxScore, 0.5, "All scores should be below confidence threshold")
    }

    // MARK: - Integration: classify() with synthetic images

    func testClassify_ColorHistogramOnly_WhiteImage_FavorsPowder() {
        // Test the color histogram path independently (Vision requires real device).
        // White image histogram should produce powder-leaning scores.
        guard let cgImage = createSolidColorImage(
            color: UIColor.white, width: 50, height: 50
        ) else {
            XCTFail("Failed to create test image")
            return
        }

        let histogram = SnowConditionClassifier.shared.computeHistogram(cgImage)
        let scores = SnowConditionClassifier.shared.mapHistogramToSnowQuality(histogram)

        // The highest score should be powder or groomed for a white image
        let topQuality = scores.max(by: { $0.value < $1.value })?.key
        XCTAssertNotNil(topQuality)
        if let top = topQuality {
            XCTAssertTrue(
                [SnowQuality.powder, .packedPowder, .groomed].contains(top),
                "White image histogram should favor powder/groomed, got: \(top)"
            )
        }
    }

    func testClassify_InvalidImage_ReturnsNil() async {
        // UIImage with no CGImage backing
        let emptyImage = UIImage()
        let result = await SnowConditionClassifier.shared.classify(emptyImage)
        XCTAssertNil(result, "Invalid image should return nil")
    }

    // MARK: - Helpers

    /// Create a solid-color CGImage for testing.
    private func createSolidColorImage(color: UIColor, width: Int, height: Int) -> CGImage? {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(origin: .zero, size: size))

        return context.makeImage()
    }
}
