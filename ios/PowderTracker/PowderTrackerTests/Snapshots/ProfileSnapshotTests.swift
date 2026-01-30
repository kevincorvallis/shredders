//
//  ProfileSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for profile views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class ProfileSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Profile Settings View Tests

    func testProfileSettingsView_fullProfile() {
        let view = ProfileSettingsView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testProfileSettingsView_minimalProfile() {
        let view = ProfileSettingsView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Skiing Preferences View Tests

    func testSkiingPreferencesView_allSelected() {
        let view = SkiingPreferencesView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testSkiingPreferencesView_empty() {
        let view = SkiingPreferencesView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Account Settings View Tests

    func testAccountSettingsView() {
        let view = AccountSettingsView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Dark Mode Tests

    func testProfileSettingsView_darkMode() {
        let view = ProfileSettingsView()
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
