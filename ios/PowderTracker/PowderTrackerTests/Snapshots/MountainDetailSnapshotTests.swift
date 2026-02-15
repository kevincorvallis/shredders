//
//  MountainDetailSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for MountainDetailView (4-tab layout).
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class MountainDetailSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - MountainDetailView Tab Tests

    func testMountainDetailView_overviewTab() {
        let mountain = Mountain.mock()
        let view = MountainDetailView(mountain: mountain)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainDetailView_conditionsTab() {
        let mountain = Mountain.mock()
        let view = MountainDetailView(mountain: mountain)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainDetailView_liftsTab() {
        let mountain = Mountain.mock()
        let view = MountainDetailView(mountain: mountain)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainDetailView_socialTab() {
        let mountain = Mountain.mock()
        let view = MountainDetailView(mountain: mountain)
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainDetailView_darkMode() {
        let mountain = Mountain.mock()
        let view = MountainDetailView(mountain: mountain)
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
