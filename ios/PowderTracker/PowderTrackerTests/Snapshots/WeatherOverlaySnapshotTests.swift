//
//  WeatherOverlaySnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for weather overlay views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class WeatherOverlaySnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Overlay Picker Tests

    func testOverlayPickerSheet_collapsed() {
        let view = OverlayPickerSheet(selectedOverlay: .constant(.radar), isPresented: .constant(true))
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testOverlayPickerSheet_expanded() {
        let view = OverlayPickerSheet(selectedOverlay: .constant(.radar), isPresented: .constant(true))
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Map Legend Tests

    func testMapLegendView_radar() {
        let view = MapLegendView(overlayType: .radar)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testMapLegendView_temperature() {
        let view = MapLegendView(overlayType: .temperature)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testMapLegendView_wind() {
        let view = MapLegendView(overlayType: .wind)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testMapLegendView_snow() {
        let view = MapLegendView(overlayType: .snow)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }
}
