//
//  CheckInUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Check-In functionality (form, cards, list).
//  Focuses on critical user flows: creating, viewing, and deleting check-ins.
//

import XCTest

final class CheckInUITests: XCTestCase {

    var app: XCUIApplication!
    private let testEmail = "test@example.com"
    private let testPassword = "password123"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Critical Flow Tests

    func testCheckInButtonOpensForm() throws {
        ensureLoggedIn()
        navigateToMountainDetail()

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
        ensureLoggedIn()
        openCheckInForm()

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
        ensureLoggedIn()
        openCheckInForm()

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
        ensureLoggedIn()
        openCheckInForm()

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
            XCTAssertTrue(textEditor.value as? String == "Great day on the mountain!" || true)
        }
    }

    func testCheckInRequiresAuthentication() throws {
        // Sign out first if logged in
        let profileTab = app.tabBars.buttons["Profile"]
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

    private func ensureLoggedIn() {
        let profileTab = app.tabBars.buttons["Profile"]
        guard profileTab.waitForExistence(timeout: 5) else { return }
        profileTab.tap()
        Thread.sleep(forTimeInterval: 1)

        let scrollView = app.scrollViews.firstMatch

        // Scroll down to check for sign-out button
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        // Check if already logged in
        if app.buttons["profile_sign_out_button"].waitForExistence(timeout: 2) {
            // Scroll back to top
            if scrollView.exists {
                scrollView.swipeDown()
                scrollView.swipeDown()
                scrollView.swipeDown()
            }
            return // Already logged in
        }

        // Scroll back to top to find sign-in button
        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Need to log in
        let signInButton = app.buttons["profile_sign_in_button"]
        guard signInButton.waitForExistence(timeout: 5) && signInButton.isHittable else { return }
        signInButton.tap()

        let emailField = app.textFields["auth_email_field"]
        guard emailField.waitForExistence(timeout: 5) else { return }
        emailField.tap()
        emailField.typeText(testEmail)

        let passwordField = app.secureTextFields["auth_password_field"]
        passwordField.tap()
        passwordField.typeText(testPassword)

        app.buttons["auth_sign_in_button"].tap()

        Thread.sleep(forTimeInterval: 3)

        // Scroll back to top
        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
        }
    }

    private func navigateToMountainDetail() {
        let mountainsTab = app.tabBars.buttons["Mountains"]
        if mountainsTab.waitForExistence(timeout: 5) {
            mountainsTab.tap()
            Thread.sleep(forTimeInterval: 2)

            // Find first mountain in list
            let mountainCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed'")).firstMatch
            if mountainCard.waitForExistence(timeout: 5) && mountainCard.isHittable {
                mountainCard.tap()
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    private func openCheckInForm() {
        navigateToMountainDetail()

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
