import XCTest
@testable import PowderTracker

final class ForecastCalibratorTests: XCTestCase {

    // MARK: - CalibrationModel Tests

    func testCalibrationModel_NoObservations_DefaultsToIdentity() {
        // Given
        var model = CalibrationModel()

        // When
        model.recalculate()

        // Then
        XCTAssertEqual(model.slope, 1.0)
        XCTAssertEqual(model.intercept, 0.0)
        XCTAssertEqual(model.rSquared, 0.0)
    }

    func testCalibrationModel_PerfectCorrelation() {
        // Given - actual always equals forecast
        var model = CalibrationModel()
        model.observations = [
            CalibrationObservation(forecast: 2, actual: 2),
            CalibrationObservation(forecast: 4, actual: 4),
            CalibrationObservation(forecast: 6, actual: 6),
            CalibrationObservation(forecast: 8, actual: 8),
            CalibrationObservation(forecast: 10, actual: 10),
        ]

        // When
        model.recalculate()

        // Then
        XCTAssertEqual(model.slope, 1.0, accuracy: 0.01)
        XCTAssertEqual(model.intercept, 0.0, accuracy: 0.01)
        XCTAssertEqual(model.rSquared, 1.0, accuracy: 0.01)
        XCTAssertEqual(model.biasDirection, .accurate)
    }

    func testCalibrationModel_ConsistentOverestimate() {
        // Given - forecast always 2" more than actual
        var model = CalibrationModel()
        model.observations = [
            CalibrationObservation(forecast: 4, actual: 2),
            CalibrationObservation(forecast: 6, actual: 4),
            CalibrationObservation(forecast: 8, actual: 6),
            CalibrationObservation(forecast: 10, actual: 8),
            CalibrationObservation(forecast: 12, actual: 10),
        ]

        // When
        model.recalculate()

        // Then
        XCTAssertEqual(model.slope, 1.0, accuracy: 0.01)
        XCTAssertEqual(model.intercept, -2.0, accuracy: 0.01)
        XCTAssertLessThan(model.averageBias, -0.5, "Should detect overestimate")
        XCTAssertEqual(model.biasDirection, .overestimates)
    }

    func testCalibrationModel_ConsistentUnderestimate() {
        // Given - forecast always 3" less than actual
        var model = CalibrationModel()
        model.observations = [
            CalibrationObservation(forecast: 2, actual: 5),
            CalibrationObservation(forecast: 4, actual: 7),
            CalibrationObservation(forecast: 6, actual: 9),
            CalibrationObservation(forecast: 8, actual: 11),
            CalibrationObservation(forecast: 10, actual: 13),
        ]

        // When
        model.recalculate()

        // Then
        XCTAssertEqual(model.slope, 1.0, accuracy: 0.01)
        XCTAssertEqual(model.intercept, 3.0, accuracy: 0.01)
        XCTAssertGreaterThan(model.averageBias, 0.5, "Should detect underestimate")
        XCTAssertEqual(model.biasDirection, .underestimates)
    }

    func testCalibrationModel_ScalingBias() {
        // Given - actual is consistently 1.5x forecast
        var model = CalibrationModel()
        model.observations = [
            CalibrationObservation(forecast: 2, actual: 3),
            CalibrationObservation(forecast: 4, actual: 6),
            CalibrationObservation(forecast: 6, actual: 9),
            CalibrationObservation(forecast: 8, actual: 12),
            CalibrationObservation(forecast: 10, actual: 15),
        ]

        // When
        model.recalculate()

        // Then
        XCTAssertEqual(model.slope, 1.5, accuracy: 0.01)
        XCTAssertEqual(model.intercept, 0.0, accuracy: 0.01)
        XCTAssertGreaterThan(model.rSquared, 0.99)
    }

    func testCalibrationModel_Confidence_Low_FewObservations() {
        // Given
        var model = CalibrationModel()
        model.observations = [
            CalibrationObservation(forecast: 2, actual: 3),
            CalibrationObservation(forecast: 4, actual: 5),
        ]
        model.recalculate()

        // Then
        XCTAssertEqual(model.confidence, .low)
    }

    func testCalibrationModel_Confidence_High_ManyGoodObservations() {
        // Given - 30 highly correlated observations
        var model = CalibrationModel()
        model.observations = (1...30).map { i in
            CalibrationObservation(forecast: Double(i), actual: Double(i) * 1.1)
        }
        model.recalculate()

        // Then
        XCTAssertEqual(model.confidence, .high)
        XCTAssertGreaterThan(model.rSquared, 0.7)
    }

    // MARK: - CalibratedForecast Tests

    func testCalibratedForecast_PositiveAdjustment() {
        let forecast = CalibratedForecast(
            rawSnowfall: 5,
            correctedSnowfall: 7,
            biasDirection: .underestimates,
            confidence: .medium,
            observationCount: 20
        )

        XCTAssertEqual(forecast.adjustment, 2)
        XCTAssertEqual(forecast.adjustmentLabel, "+2\"")
    }

    func testCalibratedForecast_NegativeAdjustment() {
        let forecast = CalibratedForecast(
            rawSnowfall: 8,
            correctedSnowfall: 6,
            biasDirection: .overestimates,
            confidence: .medium,
            observationCount: 20
        )

        XCTAssertEqual(forecast.adjustment, -2)
        XCTAssertEqual(forecast.adjustmentLabel, "-2\"")
    }

    func testCalibratedForecast_NoAdjustment() {
        let forecast = CalibratedForecast(
            rawSnowfall: 5,
            correctedSnowfall: 5,
            biasDirection: .accurate,
            confidence: .high,
            observationCount: 50
        )

        XCTAssertEqual(forecast.adjustment, 0)
        XCTAssertEqual(forecast.adjustmentLabel, "±0\"")
    }

    // MARK: - BiasDirection Tests

    func testBiasDirection_Values() {
        XCTAssertEqual(BiasDirection.overestimates.rawValue, "overestimates")
        XCTAssertEqual(BiasDirection.underestimates.rawValue, "underestimates")
        XCTAssertEqual(BiasDirection.accurate.rawValue, "accurate")
    }

    // MARK: - CalibrationConfidence Tests

    func testCalibrationConfidence_DisplayNames() {
        XCTAssertEqual(CalibrationConfidence.low.displayName, "Low")
        XCTAssertEqual(CalibrationConfidence.medium.displayName, "Medium")
        XCTAssertEqual(CalibrationConfidence.high.displayName, "High")
    }

    // MARK: - ForecastCalibrator Integration Tests

    @MainActor
    func testCalibrate_InsufficientData_ReturnsNil() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        // Record fewer than 5 observations
        calibrator.recordObservation(mountainId: "test-mtn", forecastSnowfall: 5, actualSnowfall: 4)
        calibrator.recordObservation(mountainId: "test-mtn", forecastSnowfall: 3, actualSnowfall: 2)

        // When
        let result = calibrator.calibrate(mountainId: "test-mtn", forecastSnowfall: 6)

        // Then
        XCTAssertNil(result, "Should return nil with fewer than 5 observations")

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testCalibrate_WithSufficientData_ReturnsCorrected() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        // Record 10 observations where forecast overestimates by ~2
        for i in 1...10 {
            calibrator.recordObservation(
                mountainId: "calibrate-test",
                forecastSnowfall: i * 2,
                actualSnowfall: i * 2 - 2
            )
        }

        // When
        let result = calibrator.calibrate(mountainId: "calibrate-test", forecastSnowfall: 10)

        // Then
        XCTAssertNotNil(result)
        XCTAssertLessThan(result!.correctedSnowfall, 10, "Should correct downward for overestimating forecast")
        XCTAssertEqual(result!.biasDirection, .overestimates)

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testBiasSummary_InsufficientData_ReturnsNil() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        // When
        let summary = calibrator.biasSummary(for: "unknown-mountain")

        // Then
        XCTAssertNil(summary)
    }

    @MainActor
    func testBiasSummary_Overestimate() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        for _ in 0..<10 {
            calibrator.recordObservation(mountainId: "over-mtn", forecastSnowfall: 10, actualSnowfall: 7)
        }

        // When
        let summary = calibrator.biasSummary(for: "over-mtn")

        // Then
        XCTAssertNotNil(summary)
        XCTAssertTrue(summary!.contains("overestimate"))

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testBiasSummary_Underestimate() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        for _ in 0..<10 {
            calibrator.recordObservation(mountainId: "under-mtn", forecastSnowfall: 5, actualSnowfall: 9)
        }

        // When
        let summary = calibrator.biasSummary(for: "under-mtn")

        // Then
        XCTAssertNotNil(summary)
        XCTAssertTrue(summary!.contains("underestimate"))

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testClearAll_RemovesAllData() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.recordObservation(mountainId: "clear-test", forecastSnowfall: 5, actualSnowfall: 5)

        // When
        calibrator.clearAll()

        // Then
        XCTAssertTrue(calibrator.models.isEmpty)
    }

    @MainActor
    func testIngestHistoryVsForecast_MatchingDates() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        let history = (1...7).map { i in
            HistoryDataPoint(
                date: "2025-01-0\(i)",
                snowDepth: 100 + i * 5,
                snowfall: i + 1,
                temperature: 28
            )
        }

        let forecast = (1...7).map { i in
            ForecastDay(
                date: "2025-01-0\(i)",
                dayOfWeek: "Day\(i)",
                high: 32,
                low: 25,
                snowfall: i,
                precipProbability: 80,
                precipType: "snow",
                wind: ForecastDay.ForecastWind(speed: 10, gust: 15),
                conditions: "Snow",
                icon: "snow"
            )
        }

        // When
        calibrator.ingestHistoryVsForecast(
            mountainId: "ingest-test",
            history: history,
            forecast: forecast
        )

        // Then
        let model = calibrator.models["ingest-test"]
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.observations.count, 7)

        // Forecast underestimates (actual = forecast + 1)
        XCTAssertEqual(model?.biasDirection, .underestimates)

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testIngestHistoryVsForecast_NoMatchingDates() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        let history = [
            HistoryDataPoint(date: "2025-01-01", snowDepth: 100, snowfall: 5, temperature: 28)
        ]

        let forecast = [
            ForecastDay(
                date: "2025-02-01",
                dayOfWeek: "Sat",
                high: 32,
                low: 25,
                snowfall: 5,
                precipProbability: 80,
                precipType: "snow",
                wind: ForecastDay.ForecastWind(speed: 10, gust: 15),
                conditions: "Snow",
                icon: "snow"
            )
        ]

        // When
        calibrator.ingestHistoryVsForecast(
            mountainId: "no-match-test",
            history: history,
            forecast: forecast
        )

        // Then - no observations recorded since dates don't overlap
        XCTAssertNil(calibrator.models["no-match-test"])

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testMaxObservationsLimit() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        // When - record 100 observations (max is 90)
        for i in 1...100 {
            calibrator.recordObservation(
                mountainId: "limit-test",
                forecastSnowfall: i,
                actualSnowfall: i
            )
        }

        // Then
        let model = calibrator.models["limit-test"]
        XCTAssertNotNil(model)
        XCTAssertLessThanOrEqual(model!.observations.count, 90)

        // Cleanup
        calibrator.clearAll()
    }

    @MainActor
    func testCalibratedForecast_NeverNegative() {
        // Given
        let calibrator = ForecastCalibrator.shared
        calibrator.clearAll()

        // Record observations where actual is always 0 (forecast vastly overestimates)
        for _ in 0..<10 {
            calibrator.recordObservation(mountainId: "zero-test", forecastSnowfall: 10, actualSnowfall: 0)
        }

        // When
        let result = calibrator.calibrate(mountainId: "zero-test", forecastSnowfall: 5)

        // Then
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result!.correctedSnowfall, 0, "Corrected snowfall should never be negative")

        // Cleanup
        calibrator.clearAll()
    }
}
