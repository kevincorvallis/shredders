//
//  MountainCardSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for mountain card components.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class MountainCardSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Set to true to record new snapshots
        // isRecording = true
    }

    // MARK: - Enhanced Mountain Card Tests

    func testEnhancedMountainCard_normalState() {
        let mountain = Mountain.mock()
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_favorited() {
        let mountain = Mountain.mock()
        let view = EnhancedMountainCard(mountain: mountain, isFavorite: true)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_lowPowderScore() {
        let mountain = Mountain.mock(percentOpen: 25)
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_mediumPowderScore() {
        let mountain = Mountain.mock(percentOpen: 55)
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_highPowderScore() {
        let mountain = Mountain.mock(percentOpen: 95)
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_epicPass() {
        let mountain = Mountain.mockEpicPass()
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_ikonPass() {
        let mountain = Mountain.mockIkonPass()
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertComponentSnapshot(view)
    }

    func testEnhancedMountainCard_darkMode() {
        let mountain = Mountain.mock()
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertDarkModeSnapshot(view)
    }

    func testEnhancedMountainCard_smallDevice() {
        let mountain = Mountain.mock()
        let view = EnhancedMountainCard(mountain: mountain)
            .snapshotContainer()

        assertViewSnapshot(view, device: .iPhoneSE)
    }

    func testEnhancedMountainCard_accessibilityXXL() {
        let mountain = Mountain.mock()
        let view = EnhancedMountainCard(mountain: mountain)
            .componentSnapshot()

        assertAccessibilitySnapshot(view)
    }
}
