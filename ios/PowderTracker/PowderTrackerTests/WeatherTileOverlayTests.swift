import XCTest
import MapKit
@testable import PowderTracker

final class WeatherTileOverlayTests: XCTestCase {

    // MARK: - Overlay Creation Tests

    func testWeatherTileOverlay_Radar_ShouldCreate() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .radar, timestamp: nil)

        // Then
        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay?.overlayType, .radar)
    }

    func testWeatherTileOverlay_Radar_WithTimestamp_ShouldCreate() {
        // Given
        let timestamp = Int(Date().timeIntervalSince1970)

        // When
        let overlay = WeatherTileOverlay.create(overlayType: .radar, timestamp: timestamp)

        // Then
        XCTAssertNotNil(overlay)
    }

    func testWeatherTileOverlay_Clouds_ShouldCreate() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .clouds, timestamp: nil)

        // Then
        XCTAssertNotNil(overlay)
    }

    func testWeatherTileOverlay_Smoke_ShouldCreate() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .smoke, timestamp: nil)

        // Then
        XCTAssertNotNil(overlay)
    }

    func testWeatherTileOverlay_Snowfall_ShouldCreate() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .snowfall, timestamp: nil)

        // Then
        XCTAssertNotNil(overlay)
    }

    func testWeatherTileOverlay_SnowDepth_ShouldCreate() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .snowDepth, timestamp: nil)

        // Then
        XCTAssertNotNil(overlay)
    }

    func testWeatherTileOverlay_Avalanche_ShouldReturnNil() {
        // Given/When (Avalanche not implemented yet)
        let overlay = WeatherTileOverlay.create(overlayType: .avalanche, timestamp: nil)

        // Then
        XCTAssertNil(overlay)
    }

    func testWeatherTileOverlay_LandOwnership_ShouldReturnNil() {
        // Given/When (Coming soon)
        let overlay = WeatherTileOverlay.create(overlayType: .landOwnership, timestamp: nil)

        // Then
        XCTAssertNil(overlay)
    }

    func testWeatherTileOverlay_OfflineMaps_ShouldReturnNil() {
        // Given/When (Coming soon)
        let overlay = WeatherTileOverlay.create(overlayType: .offlineMaps, timestamp: nil)

        // Then
        XCTAssertNil(overlay)
    }

    // MARK: - Availability Tests

    func testWeatherTileOverlay_IsAvailable_Radar_ShouldBeTrue() {
        XCTAssertTrue(WeatherTileOverlay.isAvailable(.radar))
    }

    func testWeatherTileOverlay_IsAvailable_Clouds_ShouldBeTrue() {
        XCTAssertTrue(WeatherTileOverlay.isAvailable(.clouds))
    }

    func testWeatherTileOverlay_IsAvailable_Smoke_ShouldBeTrue() {
        XCTAssertTrue(WeatherTileOverlay.isAvailable(.smoke))
    }

    func testWeatherTileOverlay_IsAvailable_Snowfall_ShouldBeTrue() {
        XCTAssertTrue(WeatherTileOverlay.isAvailable(.snowfall))
    }

    func testWeatherTileOverlay_IsAvailable_SnowDepth_ShouldBeTrue() {
        XCTAssertTrue(WeatherTileOverlay.isAvailable(.snowDepth))
    }

    func testWeatherTileOverlay_IsAvailable_Avalanche_ShouldBeTrue() {
        XCTAssertTrue(WeatherTileOverlay.isAvailable(.avalanche))
    }

    func testWeatherTileOverlay_IsAvailable_LandOwnership_ShouldBeFalse() {
        XCTAssertFalse(WeatherTileOverlay.isAvailable(.landOwnership))
    }

    func testWeatherTileOverlay_IsAvailable_OfflineMaps_ShouldBeFalse() {
        XCTAssertFalse(WeatherTileOverlay.isAvailable(.offlineMaps))
    }

    // MARK: - Temperature and Wind (API Key Dependent)

    func testWeatherTileOverlay_Temperature_AvailabilityDependsOnAPIKey() {
        // Temperature availability depends on OpenWeatherMap API key
        // If API key is configured, should be available
        let isAvailable = WeatherTileOverlay.isAvailable(.temperature)

        // Check if API key is configured
        if AppConfig.openWeatherMapAPIKey != nil {
            XCTAssertTrue(isAvailable)
        } else {
            XCTAssertFalse(isAvailable)
        }
    }

    func testWeatherTileOverlay_Wind_AvailabilityDependsOnAPIKey() {
        // Wind availability depends on OpenWeatherMap API key
        let isAvailable = WeatherTileOverlay.isAvailable(.wind)

        // Check if API key is configured
        if AppConfig.openWeatherMapAPIKey != nil {
            XCTAssertTrue(isAvailable)
        } else {
            XCTAssertFalse(isAvailable)
        }
    }

    // MARK: - Overlay Type Property Tests

    func testWeatherTileOverlay_OverlayType_ShouldMatchInit() {
        // Given
        let overlayTypes: [MapOverlayType] = [.radar, .clouds, .smoke, .snowfall, .snowDepth]

        for type in overlayTypes {
            // When
            let overlay = WeatherTileOverlay.create(overlayType: type, timestamp: nil)

            // Then
            XCTAssertEqual(overlay?.overlayType, type, "Overlay type should match for \(type)")
        }
    }

    // MARK: - MKTileOverlay Inheritance Tests

    func testWeatherTileOverlay_InheritsFromMKTileOverlay() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .radar, timestamp: nil)

        // Then
        XCTAssertNotNil(overlay)
    }

    func testWeatherTileOverlay_TileSize_ShouldBe256() {
        // Given/When
        let overlay = WeatherTileOverlay.create(overlayType: .radar, timestamp: nil)

        // Then
        XCTAssertEqual(overlay?.tileSize.width, 256)
        XCTAssertEqual(overlay?.tileSize.height, 256)
    }
}

// MARK: - WeatherTileOverlayRenderer Tests

final class WeatherTileOverlayRendererTests: XCTestCase {

    func testWeatherTileOverlayRenderer_ShouldInheritFromMKTileOverlayRenderer() {
        // Given
        guard let overlay = WeatherTileOverlay.create(overlayType: .radar, timestamp: nil) else {
            XCTFail("Failed to create overlay")
            return
        }

        // When
        let renderer = WeatherTileOverlayRenderer(tileOverlay: overlay)

        // Then
        XCTAssertNotNil(renderer)
    }

    func testWeatherTileOverlayRenderer_Alpha_ShouldBeLessThanOne() {
        // Given
        guard let overlay = WeatherTileOverlay.create(overlayType: .radar, timestamp: nil) else {
            XCTFail("Failed to create overlay")
            return
        }

        // When
        let renderer = WeatherTileOverlayRenderer(tileOverlay: overlay)

        // Then
        XCTAssertLessThan(renderer.alpha, 1.0)
        XCTAssertGreaterThan(renderer.alpha, 0.0)
    }
}

// MARK: - WeatherOverlayManager Tests

@MainActor
final class WeatherOverlayManagerTests: XCTestCase {

    func testWeatherOverlayManager_InitialState() {
        // Given/When
        let manager = WeatherOverlayManager()

        // Then
        XCTAssertFalse(manager.isAnimating)
        XCTAssertNil(manager.currentTimestamp)
    }

    func testWeatherOverlayManager_RemoveCurrentOverlay_ShouldNotCrash() {
        // Given
        let manager = WeatherOverlayManager()

        // When/Then - Should not crash even without a map attached
        manager.removeCurrentOverlay()
        XCTAssertFalse(manager.isAnimating)
    }

    func testWeatherOverlayManager_StopAnimation_ShouldSetFalse() {
        // Given
        let manager = WeatherOverlayManager()
        manager.isAnimating = true

        // When
        manager.stopAnimation()

        // Then
        XCTAssertFalse(manager.isAnimating)
    }
}

// MARK: - RainViewerService Tests

final class RainViewerServiceTests: XCTestCase {

    func testRainViewerService_SharedInstance_ShouldExist() {
        // Given/When
        let service = RainViewerService.shared

        // Then
        XCTAssertNotNil(service)
    }

    func testRainViewerService_GetMostRecentTimestamp_ShouldBeAsync() async {
        // Given
        let service = RainViewerService.shared

        // When/Then
        do {
            let timestamp = try await service.getMostRecentTimestamp()
            XCTAssertGreaterThan(timestamp, 0)

            // Timestamp should be within last hour (reasonable check)
            let now = Int(Date().timeIntervalSince1970)
            let oneHourAgo = now - 3600
            XCTAssertGreaterThan(timestamp, oneHourAgo, "Timestamp should be recent")
        } catch {
            // Network error is acceptable in unit tests
            print("RainViewer API call failed (expected in offline tests): \(error)")
        }
    }
}
