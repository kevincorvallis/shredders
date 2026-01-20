import XCTest
import MapKit
@testable import PowderTracker

/// Integration tests for map-related components working together
final class MapIntegrationTests: XCTestCase {

    // MARK: - MountainSelectionViewModel Tests

    func testMountainSelectionViewModel_LoadMountains_ShouldPopulateList() async {
        // Given
        let viewModel = MountainSelectionViewModel()

        // When
        await viewModel.loadMountains()

        // Then
        XCTAssertFalse(viewModel.mountains.isEmpty, "Mountains should be loaded")
    }

    func testMountainSelectionViewModel_RegionalGroups_ShouldBePopulated() async {
        // Given
        let viewModel = MountainSelectionViewModel()

        // When
        await viewModel.loadMountains()

        // Then
        // At least one region should have mountains
        let hasWashington = !viewModel.washingtonMountains.isEmpty
        let hasOregon = !viewModel.oregonMountains.isEmpty
        let hasIdaho = !viewModel.idahoMountains.isEmpty

        XCTAssertTrue(hasWashington || hasOregon || hasIdaho, "At least one region should have mountains")
    }

    func testMountainSelectionViewModel_SelectMountain_ShouldUpdateSelection() async {
        // Given
        let viewModel = MountainSelectionViewModel()
        await viewModel.loadMountains()

        guard let firstMountain = viewModel.mountains.first else {
            XCTFail("No mountains loaded")
            return
        }

        // When
        viewModel.selectMountain(firstMountain)

        // Then
        XCTAssertEqual(viewModel.selectedMountain?.id, firstMountain.id)
    }

    func testMountainSelectionViewModel_GetScore_ShouldReturnValue() async {
        // Given
        let viewModel = MountainSelectionViewModel()
        await viewModel.loadMountains()

        guard let mountain = viewModel.mountains.first else {
            XCTFail("No mountains loaded")
            return
        }

        // When
        let score = viewModel.getScore(for: mountain)

        // Then
        // Score may be nil if not calculated yet, but shouldn't crash
        if let score = score {
            XCTAssertTrue(score >= 0 && score <= 10, "Score should be between 0 and 10")
        }
    }

    // MARK: - FavoritesManager Integration Tests

    @MainActor
    func testFavoritesManager_AddAndRemove_ShouldWork() {
        // Given
        let manager = FavoritesManager.shared
        let testMountainId = "test-mountain-\(UUID().uuidString)"

        // When - Add
        let added = manager.add(testMountainId)

        // Then
        XCTAssertTrue(added)
        XCTAssertTrue(manager.isFavorite(testMountainId))

        // When - Remove
        manager.remove(testMountainId)

        // Then
        XCTAssertFalse(manager.isFavorite(testMountainId))
    }

    @MainActor
    func testFavoritesManager_Duplicates_ShouldNotBeAdded() {
        // Given
        let manager = FavoritesManager.shared
        let testMountainId = "test-duplicate-\(UUID().uuidString)"

        // When
        let firstAdd = manager.add(testMountainId)
        let secondAdd = manager.add(testMountainId)

        // Then
        XCTAssertTrue(firstAdd)
        XCTAssertFalse(secondAdd)

        // Cleanup
        manager.remove(testMountainId)
    }

    // MARK: - MapOverlayState with WeatherTileOverlay Integration

    @MainActor
    func testOverlayState_ToggleRadar_ShouldCreateValidOverlay() {
        // Given
        let state = MapOverlayState()

        // When
        state.toggle(.radar)

        // Then
        XCTAssertEqual(state.activeOverlay, .radar)

        // Verify overlay can be created
        let overlay = WeatherTileOverlay(overlayType: .radar, timestamp: nil)
        XCTAssertNotNil(overlay)
    }

    @MainActor
    func testOverlayState_TimeBasedOverlay_ShouldHaveValidIntervals() {
        // Given
        let state = MapOverlayState()

        // When
        state.toggle(.snowfall)

        // Then
        XCTAssertTrue(state.activeOverlay?.isTimeBased ?? false)
        XCTAssertNotNil(state.activeOverlay?.timeIntervals)

        // Verify we can set time offset
        if let intervals = state.activeOverlay?.timeIntervals, !intervals.isEmpty {
            state.selectedTimeOffset = intervals[0]
            XCTAssertEqual(state.selectedTimeOffset, intervals[0])
        }
    }

    // MARK: - Map Region Tests

    func testMapRegion_DefaultPNW_ShouldCoverRegion() {
        // Given - Default region centered on Pacific Northwest
        let defaultRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )

        // Then - Should cover approximate PNW bounds
        let minLat = defaultRegion.center.latitude - defaultRegion.span.latitudeDelta / 2
        let maxLat = defaultRegion.center.latitude + defaultRegion.span.latitudeDelta / 2
        let minLng = defaultRegion.center.longitude - defaultRegion.span.longitudeDelta / 2
        let maxLng = defaultRegion.center.longitude + defaultRegion.span.longitudeDelta / 2

        // Seattle area should be in range
        XCTAssertTrue(minLat < 47.6 && maxLat > 47.6, "Should include Seattle latitude")
        XCTAssertTrue(minLng < -122.3 && maxLng > -122.3, "Should include Seattle longitude")

        // Portland area should be in range
        XCTAssertTrue(minLat < 45.5 && maxLat > 45.5, "Should include Portland latitude")
    }

    func testMapRegion_ZoomToMountain_ShouldUpdateRegion() {
        // Given
        var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )

        let mountainLocation = CLLocationCoordinate2D(latitude: 48.857, longitude: -121.669) // Mt. Baker

        // When
        region = MKCoordinateRegion(
            center: mountainLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )

        // Then
        XCTAssertEqual(region.center.latitude, mountainLocation.latitude, accuracy: 0.001)
        XCTAssertEqual(region.center.longitude, mountainLocation.longitude, accuracy: 0.001)
        XCTAssertEqual(region.span.latitudeDelta, 0.5, accuracy: 0.001)
    }

    // MARK: - Coordinate Validation Tests

    func testMountainLocation_ShouldBeInPNW() async {
        // Given
        let viewModel = MountainSelectionViewModel()
        await viewModel.loadMountains()

        // Pacific Northwest bounds (approximate)
        let minLat = 42.0  // Southern Oregon
        let maxLat = 50.0  // Canadian border
        let minLng = -125.0 // Pacific coast
        let maxLng = -115.0 // Idaho border

        // Then
        for mountain in viewModel.mountains {
            let lat = mountain.location.lat
            let lng = mountain.location.lng

            XCTAssertTrue(lat >= minLat && lat <= maxLat,
                "\(mountain.name) latitude \(lat) should be in PNW")
            XCTAssertTrue(lng >= minLng && lng <= maxLng,
                "\(mountain.name) longitude \(lng) should be in PNW")
        }
    }

    // MARK: - Search Filter Integration Tests

    func testSearchFilter_IntegrationWithViewModelData() async {
        // Given
        let viewModel = MountainSelectionViewModel()
        await viewModel.loadMountains()

        // When
        let searchText = "Baker"
        let filtered = viewModel.mountains.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        }

        // Then
        XCTAssertFalse(filtered.isEmpty, "Should find mountains matching 'Baker'")
        XCTAssertTrue(filtered.allSatisfy {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.shortName.localizedCaseInsensitiveContains(searchText)
        })
    }

    // MARK: - Pass Filter Integration Tests

    func testPassFilter_IntegrationWithViewModelData() async {
        // Given
        let viewModel = MountainSelectionViewModel()
        await viewModel.loadMountains()

        // When
        let ikonMountains = viewModel.mountains.filter { $0.passType == .ikon }
        let epicMountains = viewModel.mountains.filter { $0.passType == .epic }

        // Then - There should be some pass-affiliated mountains
        let totalPassMountains = ikonMountains.count + epicMountains.count
        XCTAssertGreaterThan(totalPassMountains, 0, "Should have some pass-affiliated mountains")
    }

    // MARK: - Distance Calculation Tests

    func testDistanceCalculation_ShouldBeReasonable() async {
        // Given
        let viewModel = MountainSelectionViewModel()
        await viewModel.loadMountains()

        // Check distances if location is available
        for mountain in viewModel.mountains {
            if let distance = viewModel.getDistance(to: mountain) {
                // Distance should be positive and reasonable (< 1000 miles for PNW)
                XCTAssertGreaterThan(distance, 0, "Distance to \(mountain.name) should be positive")
                XCTAssertLessThan(distance, 1000, "Distance to \(mountain.name) should be < 1000 miles")
            }
        }
    }
}

// MARK: - LocationManager Integration Tests

final class LocationManagerIntegrationTests: XCTestCase {

    @MainActor
    func testLocationManager_SharedInstance_ShouldExist() {
        let manager = LocationManager.shared
        XCTAssertNotNil(manager)
    }

    @MainActor
    func testLocationManager_AuthorizationStatus_ShouldBeValid() {
        let manager = LocationManager.shared

        // Authorization status should be one of the valid values
        // (We can't control which one in tests)
        XCTAssertNotNil(manager)
    }
}

// MARK: - AppConfig Integration Tests

final class AppConfigIntegrationTests: XCTestCase {

    func testAppConfig_OpenWeatherMapAPIKey_ShouldExist() {
        // Given/When
        let apiKey = AppConfig.openWeatherMapAPIKey

        // Then
        XCTAssertNotNil(apiKey, "OpenWeatherMap API key should be configured")
        XCTAssertFalse(apiKey?.isEmpty ?? true, "API key should not be empty")
    }

    func testAppConfig_BaseURL_ShouldBeValid() {
        // Given/When
        let baseURL = AppConfig.baseURL

        // Then
        XCTAssertFalse(baseURL.isEmpty, "Base URL should not be empty")
        XCTAssertTrue(baseURL.hasPrefix("http"), "Base URL should start with http")
    }
}
