//
//  ProfileUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Profile/Settings functionality - focuses on critical user flows.
//

import XCTest

final class ProfileUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    @MainActor
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    @MainActor
    private func navigateToProfile() {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        XCTAssertTrue(profileTab.waitForExistence(timeout: 5), "Profile tab should exist")
        profileTab.tap()
    }

    // MARK: - Critical Flow Tests

    @MainActor
    func testProfileTabLoadsContent() throws {
        launchApp()
        navigateToProfile()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Profile view should load")
    }

    @MainActor
    func testSignInButtonOpensAuthSheet() throws {
        launchApp()
        navigateToProfile()

        let signInButton = app.buttons["profile_sign_in_button"]
        if signInButton.waitForExistence(timeout: 3) && signInButton.isHittable {
            signInButton.tap()

            let emailField = app.textFields["auth_email_field"]
            XCTAssertTrue(emailField.waitForExistence(timeout: 5), "Auth sheet should open")
        }
    }

    @MainActor
    func testSignOutFlow() throws {
        launchApp()
        navigateToProfile()

        // Scroll to find sign out button
        let scrollView = app.scrollViews.firstMatch
        let signOutButton = app.buttons["profile_sign_out_button"]

        if scrollView.exists {
            for _ in 0..<10 {
                if signOutButton.exists && signOutButton.isHittable { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if signOutButton.waitForExistence(timeout: 3) && signOutButton.isHittable {
            signOutButton.tap()

            // Handle confirmation dialog
            let confirmSheet = app.sheets.firstMatch
            if confirmSheet.waitForExistence(timeout: 2) {
                let confirmButton = confirmSheet.buttons["Sign Out"]
                if confirmButton.exists {
                    confirmButton.tap()
                }
            }

            // After sign out, sign in button should appear
            if scrollView.exists {
                scrollView.swipeDown()
                scrollView.swipeDown()
            }
            let signInButton = app.buttons["profile_sign_in_button"]
            XCTAssertTrue(signInButton.waitForExistence(timeout: 5), "Sign in button should appear after logout")
        }
    }

    @MainActor
    func testEditProfileOpens() throws {
        launchApp()
        navigateToProfile()

        let editButton = app.buttons["profile_edit_button"]
        if editButton.waitForExistence(timeout: 3) && editButton.isHittable {
            editButton.tap()
            Thread.sleep(forTimeInterval: 1)

            // Should be in edit mode - cancel or back button available
            let cancelButton = app.buttons["Cancel"]
            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(cancelButton.exists || backButton.exists, "Should be in edit mode")
        }
    }

    @MainActor
    func testProfileScrolling() throws {
        launchApp()
        navigateToProfile()

        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Profile should be scrollable")

        scrollView.swipeUp()
        scrollView.swipeUp()
        scrollView.swipeDown()
        scrollView.swipeDown()
    }

    @MainActor
    func testSettingsToggleInteraction() throws {
        launchApp()
        navigateToProfile()

        // Look for any toggle in settings
        let notificationToggle = app.switches["profile_notifications_toggle"]
        if notificationToggle.waitForExistence(timeout: 3) && notificationToggle.isHittable {
            let initialValue = notificationToggle.value as? String
            notificationToggle.tap()
            Thread.sleep(forTimeInterval: 0.5)
            let newValue = notificationToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Toggle value should change")
        }
    }
}
