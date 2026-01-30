//
//  AuthSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for authentication views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class AuthSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - Unified Auth View Tests

    func testEnhancedUnifiedAuthView_signIn() {
        let view = UnifiedAuthView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEnhancedUnifiedAuthView_signUp() {
        // Would need to trigger signup mode
        let view = UnifiedAuthView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testEnhancedUnifiedAuthView_withError() {
        // Would need to inject error state
        let view = UnifiedAuthView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Forgot Password View Tests

    func testForgotPasswordView() {
        let view = ForgotPasswordView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Change Password View Tests

    func testChangePasswordView() {
        let view = ChangePasswordView()
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Dark Mode Tests

    func testAuthView_darkMode() {
        let view = UnifiedAuthView()
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
