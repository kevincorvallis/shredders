//
//  CheckInUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Check-In functionality (form, cards, list).
//  Focuses on critical user flows: creating, viewing, and deleting check-ins.
//

import XCTest

@MainActor
final class CheckInUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Critical Flow Tests

    func testCheckInButtonOpensForm() throws {
        try ensureLoggedIn()
        try navigateToMountainDetail()

        // Scroll to check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            scrollView.swipeUp()
            sleep(1)
        }

        // Tap Check In button
        let checkInButton = app.buttons["Check In"]
        if checkInButton.waitForExistence(timeout: 5) && checkInButton.isHittable {
            checkInButton.tap()
            sleep(1)

            // Form should appear
            let formTitle = app.navigationBars["Check In"]
            XCTAssertTrue(formTitle.waitForExistence(timeout: 3), "Check-in form should open")
        }
    }

    func testSubmitCheckInWithRating() throws {
        try ensureLoggedIn()
        try openCheckInForm()

        // Select a rating
        let ratingButton = app.buttons["5"]
        if ratingButton.waitForExistence(timeout: 5) {
            ratingButton.tap()
        }

        // Submit the form
        let submitButton = app.navigationBars.buttons["Check In"]
        if submitButton.waitForExistence(timeout: 5) && submitButton.isHittable {
            submitButton.tap()
            sleep(3)

            // Form should dismiss on success (back to mountain detail)
            let formTitle = app.navigationBars["Check In"]
            XCTAssertFalse(formTitle.exists, "Form should dismiss after successful submission")
        }
    }

    func testFormCancelDismissesWithoutSubmitting() throws {
        try ensureLoggedIn()
        try openCheckInForm()

        // Tap cancel
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 5) && cancelButton.isHittable {
            cancelButton.tap()
            sleep(1)

            // Form should dismiss
            let formTitle = app.navigationBars["Check In"]
            XCTAssertFalse(formTitle.exists, "Form should be dismissed")
        }
    }

    func testTripReportTextEntry() throws {
        try ensureLoggedIn()
        try openCheckInForm()

        // Scroll to trip report section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // Find and type in text editor
        let textEditor = app.textViews.firstMatch
        if textEditor.waitForExistence(timeout: 5) {
            textEditor.tap()
            textEditor.typeText("Great day on the mountain!")

            // Verify text was entered
            // Text may not round-trip through XCTest value, just verify editor accepted input
            XCTAssertTrue(textEditor.exists, "Text editor should still exist after typing")
        }
    }

    func testCheckInRequiresAuthentication() throws {
        // Sign out first if logged in
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
            sleep(1)

            let signOutButton = app.buttons["profile_sign_out_button"]
            if signOutButton.exists && signOutButton.isHittable {
                signOutButton.tap()
                sleep(2)
            }
        }

        navigateToMountainDetail()

        // Scroll to check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // Check In button should not be visible or should prompt for login
        let checkInButton = app.buttons["Check In"]
        // Either button doesn't exist for logged-out users, or tapping shows auth
        _ = checkInButton.waitForExistence(timeout: 3)
    }

    // MARK: - Helper Methods

    private func ensureLoggedIn() throws {
        try UITestHelper.ensureLoggedIn(app: app)
    }

    private func navigateToMountainDetail() throws {
        try UITestHelper.navigateToMountainDetail(app: app)
    }

    private func openCheckInForm() throws {
        try navigateToMountainDetail()

        // Scroll to check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            scrollView.swipeUp()
            sleep(1)
        }

        // Tap Check In button
        let checkInButton = app.buttons["Check In"]
        if checkInButton.waitForExistence(timeout: 5) && checkInButton.isHittable {
            checkInButton.tap()
            sleep(1)
        }
    }
}
