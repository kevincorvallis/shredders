import XCTest
@testable import PowderTracker

@MainActor
final class MapOverlayStateTests: XCTestCase {

    // MARK: - Initial State Tests

    func testMapOverlayState_InitialState_ShouldBeEmpty() {
        // Given/When
        let state = MapOverlayState()

        // Then
        XCTAssertNil(state.activeOverlay)
        XCTAssertEqual(state.selectedTimeOffset, 0)
        XCTAssertFalse(state.isAnimating)
    }

    // MARK: - Toggle Tests

    func testMapOverlayState_Toggle_ShouldActivateOverlay() {
        // Given
        let state = MapOverlayState()

        // When
        state.toggle(.radar)

        // Then
        XCTAssertEqual(state.activeOverlay, .radar)
        XCTAssertEqual(state.selectedTimeOffset, 0)
    }

    func testMapOverlayState_ToggleSameOverlay_ShouldDeactivate() {
        // Given
        let state = MapOverlayState()
        state.toggle(.radar)

        // When
        state.toggle(.radar)

        // Then
        XCTAssertNil(state.activeOverlay)
    }

    func testMapOverlayState_ToggleDifferentOverlay_ShouldSwitch() {
        // Given
        let state = MapOverlayState()
        state.toggle(.radar)

        // When
        state.toggle(.clouds)

        // Then
        XCTAssertEqual(state.activeOverlay, .clouds)
    }

    func testMapOverlayState_Toggle_ShouldResetTimeOffset() {
        // Given
        let state = MapOverlayState()
        state.toggle(.snowfall)
        state.selectedTimeOffset = 3600 // 1 hour

        // When
        state.toggle(.radar)

        // Then
        XCTAssertEqual(state.selectedTimeOffset, 0)
    }

    // MARK: - Clear Tests

    func testMapOverlayState_Clear_ShouldResetAllState() {
        // Given
        let state = MapOverlayState()
        state.toggle(.radar)
        state.selectedTimeOffset = 7200
        state.isAnimating = true

        // When
        state.clear()

        // Then
        XCTAssertNil(state.activeOverlay)
        XCTAssertEqual(state.selectedTimeOffset, 0)
        XCTAssertFalse(state.isAnimating)
    }

    // MARK: - Time Offset Tests

    func testMapOverlayState_TimeOffset_ShouldPersistForTimeBased() {
        // Given
        let state = MapOverlayState()
        state.toggle(.snowfall)

        // When
        state.selectedTimeOffset = 21600 // 6 hours

        // Then
        XCTAssertEqual(state.selectedTimeOffset, 21600)
        XCTAssertEqual(state.activeOverlay, .snowfall)
    }

    // MARK: - Animation Tests

    func testMapOverlayState_Animation_ShouldToggle() {
        // Given
        let state = MapOverlayState()
        state.toggle(.radar)

        // When
        state.isAnimating = true

        // Then
        XCTAssertTrue(state.isAnimating)

        // When
        state.isAnimating = false

        // Then
        XCTAssertFalse(state.isAnimating)
    }
}

// MARK: - MapOverlayType Tests

final class MapOverlayTypeTests: XCTestCase {

    // MARK: - Display Name Tests

    func testMapOverlayType_DisplayName_ShouldBeShort() {
        XCTAssertEqual(MapOverlayType.snowfall.displayName, "Snowfall")
        XCTAssertEqual(MapOverlayType.snowDepth.displayName, "Depth")
        XCTAssertEqual(MapOverlayType.radar.displayName, "Radar")
        XCTAssertEqual(MapOverlayType.clouds.displayName, "Clouds")
        XCTAssertEqual(MapOverlayType.temperature.displayName, "Temp")
        XCTAssertEqual(MapOverlayType.wind.displayName, "Wind")
        XCTAssertEqual(MapOverlayType.avalanche.displayName, "Avalanche")
        XCTAssertEqual(MapOverlayType.smoke.displayName, "Smoke")
    }

    func testMapOverlayType_FullName_ShouldBeDescriptive() {
        XCTAssertEqual(MapOverlayType.snowfall.fullName, "Snowfall Forecast")
        XCTAssertEqual(MapOverlayType.radar.fullName, "Radar / Precipitation")
        XCTAssertEqual(MapOverlayType.smoke.fullName, "Smoke / Air Quality")
    }

    // MARK: - Category Tests

    func testMapOverlayType_Category_WeatherOverlays() {
        let weatherOverlays: [MapOverlayType] = [.snowfall, .snowDepth, .radar, .clouds, .temperature, .wind]

        for overlay in weatherOverlays {
            XCTAssertEqual(overlay.category, .weather, "\(overlay) should be weather category")
        }
    }

    func testMapOverlayType_Category_SafetyOverlays() {
        let safetyOverlays: [MapOverlayType] = [.avalanche, .smoke]

        for overlay in safetyOverlays {
            XCTAssertEqual(overlay.category, .safety, "\(overlay) should be safety category")
        }
    }

    func testMapOverlayType_Category_OtherOverlays() {
        let otherOverlays: [MapOverlayType] = [.landOwnership, .offlineMaps]

        for overlay in otherOverlays {
            XCTAssertEqual(overlay.category, .other, "\(overlay) should be other category")
        }
    }

    // MARK: - Time-Based Tests

    func testMapOverlayType_IsTimeBased_ShouldBeCorrect() {
        // Time-based overlays
        XCTAssertTrue(MapOverlayType.snowfall.isTimeBased)
        XCTAssertTrue(MapOverlayType.radar.isTimeBased)

        // Non time-based overlays
        XCTAssertFalse(MapOverlayType.clouds.isTimeBased)
        XCTAssertFalse(MapOverlayType.temperature.isTimeBased)
        XCTAssertFalse(MapOverlayType.wind.isTimeBased)
        XCTAssertFalse(MapOverlayType.avalanche.isTimeBased)
        XCTAssertFalse(MapOverlayType.smoke.isTimeBased)
    }

    func testMapOverlayType_TimeIntervals_ShouldExistForTimeBased() {
        // Snowfall intervals
        let snowfallIntervals = MapOverlayType.snowfall.timeIntervals
        XCTAssertNotNil(snowfallIntervals)
        XCTAssertEqual(snowfallIntervals?.count, 6) // 3h, 6h, 12h, 24h, 48h, 72h

        // Radar intervals
        let radarIntervals = MapOverlayType.radar.timeIntervals
        XCTAssertNotNil(radarIntervals)
        XCTAssertEqual(radarIntervals?.count, 7) // 0-6 hours

        // Non time-based should be nil
        XCTAssertNil(MapOverlayType.clouds.timeIntervals)
        XCTAssertNil(MapOverlayType.temperature.timeIntervals)
    }

    // MARK: - Coming Soon Tests

    func testMapOverlayType_IsComingSoon_ShouldBeCorrect() {
        // Coming soon overlays
        XCTAssertTrue(MapOverlayType.landOwnership.isComingSoon)
        XCTAssertTrue(MapOverlayType.offlineMaps.isComingSoon)

        // Available overlays
        XCTAssertFalse(MapOverlayType.radar.isComingSoon)
        XCTAssertFalse(MapOverlayType.clouds.isComingSoon)
        XCTAssertFalse(MapOverlayType.snowfall.isComingSoon)
        XCTAssertFalse(MapOverlayType.avalanche.isComingSoon)
    }

    // MARK: - Icon Tests

    func testMapOverlayType_Icons_ShouldNotBeEmpty() {
        for overlay in MapOverlayType.allCases {
            XCTAssertFalse(overlay.icon.isEmpty, "\(overlay) icon should not be empty")
            XCTAssertFalse(overlay.systemIcon.isEmpty, "\(overlay) systemIcon should not be empty")
        }
    }

    // MARK: - Legend Tests

    func testMapOverlayType_Legend_ShouldExistForRelevantTypes() {
        // Should have legends
        XCTAssertNotNil(MapOverlayType.snowfall.legend)
        XCTAssertNotNil(MapOverlayType.snowDepth.legend)
        XCTAssertNotNil(MapOverlayType.avalanche.legend)
        XCTAssertNotNil(MapOverlayType.temperature.legend)

        // Legend items should not be empty
        if let snowfallLegend = MapOverlayType.snowfall.legend {
            XCTAssertFalse(snowfallLegend.items.isEmpty)
            XCTAssertFalse(snowfallLegend.title.isEmpty)
        }
    }

    // MARK: - Identifiable Tests

    func testMapOverlayType_Identifiable_ShouldUseRawValue() {
        for overlay in MapOverlayType.allCases {
            XCTAssertEqual(overlay.id, overlay.rawValue)
        }
    }

    // MARK: - CaseIterable Tests

    func testMapOverlayType_AllCases_ShouldContainAllOverlays() {
        XCTAssertEqual(MapOverlayType.allCases.count, 10)
        XCTAssertTrue(MapOverlayType.allCases.contains(.snowfall))
        XCTAssertTrue(MapOverlayType.allCases.contains(.radar))
        XCTAssertTrue(MapOverlayType.allCases.contains(.avalanche))
        XCTAssertTrue(MapOverlayType.allCases.contains(.offlineMaps))
    }
}

// MARK: - OverlayCategory Tests

final class OverlayCategoryTests: XCTestCase {

    func testOverlayCategory_Overlays_ShouldReturnCorrectOverlays() {
        // Weather category
        let weatherOverlays = OverlayCategory.weather.overlays
        XCTAssertTrue(weatherOverlays.contains(.snowfall))
        XCTAssertTrue(weatherOverlays.contains(.radar))
        XCTAssertTrue(weatherOverlays.contains(.clouds))
        XCTAssertFalse(weatherOverlays.contains(.avalanche))

        // Safety category
        let safetyOverlays = OverlayCategory.safety.overlays
        XCTAssertTrue(safetyOverlays.contains(.avalanche))
        XCTAssertTrue(safetyOverlays.contains(.smoke))
        XCTAssertFalse(safetyOverlays.contains(.radar))

        // Other category
        let otherOverlays = OverlayCategory.other.overlays
        XCTAssertTrue(otherOverlays.contains(.landOwnership))
        XCTAssertTrue(otherOverlays.contains(.offlineMaps))
    }

    func testOverlayCategory_AllCases_ShouldCoverAllOverlays() {
        var allOverlaysFromCategories: Set<MapOverlayType> = []

        for category in OverlayCategory.allCases {
            for overlay in category.overlays {
                allOverlaysFromCategories.insert(overlay)
            }
        }

        XCTAssertEqual(allOverlaysFromCategories.count, MapOverlayType.allCases.count)
    }
}
