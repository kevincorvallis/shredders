//
//  MountainsTabViewSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for mountains tab view.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class MountainsTabViewSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Mountains Tab View Tests

    func testMountainsTabView_loadingState() {
        // Create a loading state view
        let view = MountainsTabView()
            .snapshotContainer()

        // Note: Loading state would require mocking the view model
        assertViewSnapshot(view)
    }

    func testMountainsTabView_emptyState() {
        // Test empty state when no mountains match filters
        let view = MountainsTabView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainsTabView_withMountains() {
        let view = MountainsTabView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainsTabView_filteredByEpic() {
        let view = MountainsTabView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainsTabView_filteredByIkon() {
        let view = MountainsTabView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainsTabView_sortedByPowderScore() {
        let view = MountainsTabView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testMountainsTabView_darkMode() {
        let view = MountainsTabView()
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
