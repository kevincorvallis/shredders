import XCTest
@testable import PowderTracker

final class ModelTests: XCTestCase {

    // MARK: - MountainConditions Tests

    func testMountainConditions_MockData_ShouldBeValid() {
        // Given/When
        let mock = MountainConditions.mock

        // Then
        XCTAssertEqual(mock.mountain.id, "baker")
        XCTAssertNotNil(mock.snowDepth)
        XCTAssertNotNil(mock.temperature)
        XCTAssertNotNil(mock.wind)
        XCTAssertTrue(mock.snowfall24h >= 0)
    }

    func testMountainConditions_Codable() throws {
        // Given
        let mock = MountainConditions.mock

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(mock)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MountainConditions.self, from: data)

        // Then
        XCTAssertEqual(decoded.mountain.id, mock.mountain.id)
        XCTAssertEqual(decoded.snowDepth, mock.snowDepth)
        XCTAssertEqual(decoded.temperature, mock.temperature)
    }

    // MARK: - MountainPowderScore Tests

    func testMountainPowderScore_MockData_ShouldBeValid() {
        // Given/When
        let mock = MountainPowderScore.mock

        // Then
        XCTAssertEqual(mock.mountain.id, "baker")
        XCTAssertTrue(mock.score >= 0 && mock.score <= 10)
        XCTAssertFalse(mock.factors.isEmpty)
        XCTAssertNotNil(mock.verdict)
        XCTAssertFalse(mock.verdict?.isEmpty ?? true)
    }

    func testMountainPowderScore_Codable() throws {
        // Given
        let mock = MountainPowderScore.mock

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(mock)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MountainPowderScore.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, mock.id)
        XCTAssertEqual(decoded.score, mock.score)
        XCTAssertEqual(decoded.factors.count, mock.factors.count)
    }

    func testPowderScoreFactor_Identifiable() {
        // Given
        let factor = MountainPowderScore.ScoreFactor(
            name: "Fresh Snow",
            value: 8.0,
            weight: 0.35,
            contribution: 2.8,
            description: "8\" in last 24 hours"
        )

        // Then
        XCTAssertEqual(factor.id, "Fresh Snow")
    }

    // MARK: - WeatherAlert Tests

    func testWeatherAlert_Identifiable() {
        // Given
        let alert = WeatherAlert(
            id: "test-123",
            event: "Winter Weather Advisory",
            headline: "Heavy snow expected",
            severity: "Moderate",
            urgency: "Expected",
            certainty: "Likely",
            onset: "2025-01-01T00:00:00Z",
            expires: "2025-01-02T00:00:00Z",
            description: "Heavy snow expected in the mountains",
            instruction: "Use caution while traveling",
            areaDesc: "Cascade Mountains"
        )

        // Then
        XCTAssertEqual(alert.id, "test-123")
        XCTAssertFalse(alert.event.isEmpty)
    }

    func testWeatherAlert_Codable() throws {
        // Given
        let alert = WeatherAlert(
            id: "test-123",
            event: "Winter Weather Advisory",
            headline: "Heavy snow expected",
            severity: "Moderate",
            urgency: "Expected",
            certainty: "Likely",
            onset: "2025-01-01T00:00:00Z",
            expires: "2025-01-02T00:00:00Z",
            description: "Heavy snow",
            instruction: "Be careful",
            areaDesc: "Mountains"
        )

        // When
        let encoder = JSONEncoder()
        let data = try encoder.encode(alert)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherAlert.self, from: data)

        // Then
        XCTAssertEqual(decoded.id, alert.id)
        XCTAssertEqual(decoded.event, alert.event)
    }

    // MARK: - ForecastDay Tests

    func testForecastDay_RequiredFields() {
        // Given
        let forecast = ForecastDay(
            date: "2025-01-01",
            dayOfWeek: "Mon",
            high: 35,
            low: 25,
            snowfall: 5,
            precipProbability: 80,
            precipType: "snow",
            wind: ForecastDay.ForecastWind(speed: 10, gust: 15),
            conditions: "Snow",
            icon: "snow"
        )

        // Then
        XCTAssertEqual(forecast.dayOfWeek, "Mon")
        XCTAssertEqual(forecast.snowfall, 5)
        XCTAssertTrue(forecast.high >= forecast.low)
        XCTAssertEqual(forecast.iconEmoji, "❄️")
    }

    // MARK: - APIError Tests

    func testAPIError_InvalidURL_ShouldHaveDescription() {
        // Given
        let error = APIError.invalidURL

        // Then
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }

    func testAPIError_ServerError_ShouldIncludeStatusCode() {
        // Given
        let error = APIError.serverError(404)

        // Then
        XCTAssertEqual(error.errorDescription, "Server error: 404")
    }

    func testAPIError_NetworkError_ShouldIncludeUnderlyingError() {
        // Given
        let underlyingError = NSError(domain: "test", code: 123, userInfo: nil)
        let error = APIError.networkError(underlyingError)

        // Then
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription?.contains("Network error") ?? false)
    }

    // MARK: - Mountain Tests

    func testMountain_MockData() {
        // Given
        let mountain = Mountain.mock

        // Then
        XCTAssertEqual(mountain.id, "baker")
        XCTAssertEqual(mountain.name, "Mt. Baker")
        XCTAssertEqual(mountain.shortName, "Baker")
        XCTAssertEqual(mountain.region, "washington")
        XCTAssertTrue(mountain.hasSnotel)
        XCTAssertEqual(mountain.webcamCount, 3)
        XCTAssertNotNil(mountain.logo)
        XCTAssertNotNil(mountain.status)
        XCTAssertEqual(mountain.passType, .independent)
        XCTAssertEqual(mountain.elevation.base, 3500)
        XCTAssertEqual(mountain.elevation.summit, 5089)
        XCTAssertEqual(mountain.elevation.verticalDrop, 1589)
    }

    func testMountain_Hashable() {
        // Given
        let mountain1 = Mountain.mock
        let mountain2 = Mountain.mock

        // Then
        XCTAssertEqual(mountain1, mountain2)
        XCTAssertEqual(mountain1.hashValue, mountain2.hashValue)
    }

    func testMountain_MockList() {
        // Given
        let mountains = Mountain.mockMountains

        // Then
        XCTAssertEqual(mountains.count, 3)
        XCTAssertTrue(mountains.allSatisfy { !$0.name.isEmpty })
        XCTAssertTrue(mountains.allSatisfy { !$0.id.isEmpty })
    }

    // MARK: - HistoryDataPoint Tests

    func testHistoryDataPoint_Identifiable() {
        // Given
        let dataPoint = HistoryDataPoint(
            date: "2025-01-01",
            snowDepth: 100,
            snowfall: 5,
            temperature: 28
        )

        // Then
        XCTAssertEqual(dataPoint.id, "2025-01-01")
        XCTAssertTrue(dataPoint.snowDepth >= 0)
    }

    func testHistoryDataPoint_MockHistory() {
        // Given/When
        let history = HistoryDataPoint.mockHistory(days: 7)

        // Then
        XCTAssertEqual(history.count, 7)
        XCTAssertTrue(history.allSatisfy { $0.snowDepth >= 0 })
    }

    // MARK: - PowderDay Tests

    func testPowderDay_Structure() {
        // Given
        let day = PowderDay(
            date: "2025-01-01",
            dayOfWeek: "Mon",
            predictedPowderScore: 7,
            confidence: 0.85,
            verdict: .send,
            bestWindow: "Morning",
            crowdRisk: .medium,
            travelNotes: ["Good conditions"],
            forecastSnapshot: ForecastSnapshot(
                snowfall: 8,
                high: 32,
                low: 25,
                windSpeed: 10,
                precipProbability: 80,
                precipType: "snow",
                conditions: "Snow"
            )
        )

        // Then
        XCTAssertEqual(day.predictedPowderScore, 7)
        XCTAssertTrue(day.confidence > 0 && day.confidence <= 1.0)
        XCTAssertEqual(day.verdict, .send)
        XCTAssertEqual(day.id, "2025-01-01")
    }

    func testPowderVerdict_DisplayValues() {
        XCTAssertEqual(PowderVerdict.send.displayName, "SEND")
        XCTAssertEqual(PowderVerdict.maybe.displayName, "MAYBE")
        XCTAssertEqual(PowderVerdict.wait.displayName, "WAIT")
        XCTAssertEqual(PowderVerdict.send.emoji, "🚀")
    }

    // MARK: - TripAdviceResponse Tests

    func testTripAdvice_RiskLevels() {
        // Given
        let advice = TripAdviceResponse(
            generated: "2025-01-01T00:00:00Z",
            crowd: .medium,
            trafficRisk: .low,
            roadRisk: .medium,
            headline: "Test headline",
            notes: ["Note 1"],
            suggestedDepartures: []
        )

        // Then
        XCTAssertEqual(advice.crowd, .medium)
        XCTAssertEqual(advice.trafficRisk, .low)
        XCTAssertEqual(advice.roadRisk, .medium)
    }

    func testRiskLevel_Properties() {
        XCTAssertEqual(RiskLevel.low.displayName, "Low")
        XCTAssertEqual(RiskLevel.medium.displayName, "Medium")
        XCTAssertEqual(RiskLevel.high.displayName, "High")
        XCTAssertEqual(RiskLevel.low.color, "green")
        XCTAssertEqual(RiskLevel.medium.color, "amber")
        XCTAssertEqual(RiskLevel.high.color, "red")
    }

    // MARK: - RoadsResponse Tests

    func testRoadsResponse_SupportedStates() {
        // Given
        let roadsWashington = RoadsResponse(
            mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
            supported: true,
            configured: true,
            provider: "WSDOT",
            passes: [],
            message: nil
        )

        let roadsUnsupported = RoadsResponse(
            mountain: MountainInfo(id: "other", name: "Other Mountain", shortName: "Other"),
            supported: false,
            configured: false,
            provider: nil,
            passes: [],
            message: "Not supported"
        )

        // Then
        XCTAssertTrue(roadsWashington.supported)
        XCTAssertEqual(roadsWashington.provider, "WSDOT")
        XCTAssertFalse(roadsUnsupported.supported)
        XCTAssertNotNil(roadsUnsupported.message)
    }

    // MARK: - JSON Parsing Integration Tests

    func testJSONParsing_ValidConditionsResponse() throws {
        // Given
        let json = """
        {
            "mountain": {"id": "baker", "name": "Mt. Baker", "shortName": "Baker"},
            "snowDepth": 100,
            "snowWaterEquivalent": 40.5,
            "snowfall24h": 5,
            "snowfall48h": 10,
            "snowfall7d": 20,
            "temperature": 28,
            "conditions": "Snow",
            "wind": {"speed": 15, "direction": "SW"},
            "lastUpdated": "2025-01-01",
            "dataSources": {
                "snotel": {"available": true, "stationName": "Wells Creek"},
                "noaa": {"available": true, "gridOffice": "SEW"}
            }
        }
        """

        // When
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let result = try decoder.decode(MountainConditions.self, from: data)

        // Then
        XCTAssertEqual(result.mountain.id, "baker")
        XCTAssertEqual(result.snowDepth, 100)
        XCTAssertEqual(result.temperature, 28)
    }
}
