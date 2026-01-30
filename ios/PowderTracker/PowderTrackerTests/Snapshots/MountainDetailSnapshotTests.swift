//
//  MountainDetailSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for mountain detail views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class MountainDetailSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Tabbed Location View Tests

    func testTabbedLocationView_overviewTab() {
        let mountain = Mountain.mock()
        let view = TabbedLocationView(mountain: mountain, selectedTab: 0)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testTabbedLocationView_conditionsTab() {
        let mountain = Mountain.mock()
        let view = TabbedLocationView(mountain: mountain, selectedTab: 1)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testTabbedLocationView_forecastTab() {
        let mountain = Mountain.mock()
        let view = TabbedLocationView(mountain: mountain, selectedTab: 2)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testTabbedLocationView_liftsTab() {
        let mountain = Mountain.mock()
        let view = TabbedLocationView(mountain: mountain, selectedTab: 3)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testTabbedLocationView_safetyTab() {
        let mountain = Mountain.mock()
        let view = TabbedLocationView(mountain: mountain, selectedTab: 4)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testTabbedLocationView_darkMode() {
        let mountain = Mountain.mock()
        let view = TabbedLocationView(mountain: mountain, selectedTab: 0)
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
