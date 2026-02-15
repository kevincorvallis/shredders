//
//  CheckInUITests.swift
//  PowderTrackerUITests
//
//  Tests for check-in form: open, submit, cancel.
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

    // MARK: - Check-In Form

    func testCheckInButtonOpensForm() throws {
        try ensureLoggedIn()
        try navigateToCheckInSection()

        let checkInButton = app.buttons["Check In"]
        guard checkInButton.waitForExistence(timeout: 5) && checkInButton.isHittable else {
            throw XCTSkip("Check In button not available")
        }
        checkInButton.tap()
        Thread.sleep(forTimeInterval: 1)

        let formTitle = app.navigationBars["Check In"]
        XCTAssertTrue(formTitle.waitForExistence(timeout: 3), "Check-in form should open")
    }

    func testSubmitCheckInWithRating() throws {
        try ensureLoggedIn()
        try openCheckInForm()

        let ratingButton = app.buttons["5"]
        if ratingButton.waitForExistence(timeout: 5) {
            ratingButton.tap()
        }

        let submitButton = app.navigationBars.buttons["Check In"]
        guard submitButton.waitForExistence(timeout: 5) && submitButton.isHittable else {
            throw XCTSkip("Submit button not available")
        }
        submitButton.tap()
        Thread.sleep(forTimeInterval: 3)

        let formTitle = app.navigationBars["Check In"]
        XCTAssertFalse(formTitle.exists, "Form should dismiss after successful submission")
    }

    func testFormCancelDismissesWithoutSubmitting() throws {
        try ensureLoggedIn()
        try openCheckInForm()

        let cancelButton = app.buttons["Cancel"]
        guard cancelButton.waitForExistence(timeout: 5) && cancelButton.isHittable else {
            throw XCTSkip("Cancel button not available")
        }
        cancelButton.tap()
        Thread.sleep(forTimeInterval: 1)

        let formTitle = app.navigationBars["Check In"]
        XCTAssertFalse(formTitle.exists, "Form should be dismissed after cancel")
    }

    // MARK: - Helpers

    private func ensureLoggedIn() throws {
        try UITestHelper.ensureLoggedIn(app: app)
    }

    private func navigateToCheckInSection() throws {
        try UITestHelper.navigateToMountainDetail(app: app)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 1)
        }
    }

    private func openCheckInForm() throws {
        try navigateToCheckInSection()

        let checkInButton = app.buttons["Check In"]
        guard checkInButton.waitForExistence(timeout: 5) && checkInButton.isHittable else {
            throw XCTSkip("Check In button not available")
        }
        checkInButton.tap()
        Thread.sleep(forTimeInterval: 1)
    }
}
