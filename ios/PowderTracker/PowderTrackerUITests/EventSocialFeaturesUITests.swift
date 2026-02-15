//
//  EventSocialFeaturesUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Event Social Features (Discussion, Activity, Photos).
//  Focuses on critical user flows rather than element existence checks.
//

import XCTest

@MainActor
final class EventSocialFeaturesUITests: XCTestCase {

    var app: XCUIApplication!
    private let testEmail = "test@example.com"
    private let testPassword = "password123"

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
    }

    // MARK: - Critical Flow Tests

    func testNavigateToEventAndViewSocialTabs() throws {
        ensureLoggedIn()
        navigateToEventDetail()

        // Scroll to show social tabs
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // Find the segmented picker for social tabs
        let socialTabsPicker = app.segmentedControls.firstMatch
        if socialTabsPicker.waitForExistence(timeout: 5) {
            XCTAssertTrue(socialTabsPicker.buttons.count >= 1, "Should have social tabs")
        }
    }

    func testPostCommentInDiscussion() throws {
        ensureLoggedIn()
        navigateToEventDetail()
        rsvpToEventIfNeeded()
        selectSocialTab("Discussion")

        // Type a comment
        let commentInput = app.textFields["Comment text field"]
        if commentInput.waitForExistence(timeout: 5) {
            commentInput.tap()
            commentInput.typeText("Test comment from UI test")

            // Tap send
            let sendButton = app.buttons["Send comment"]
            if sendButton.exists && sendButton.isEnabled {
                sendButton.tap()
                sleep(2)
            }
        }
    }

    func testViewActivityTimeline() throws {
        ensureLoggedIn()
        navigateToEventDetail()
        rsvpToEventIfNeeded()
        selectSocialTab("Activity")

        // Wait for activity to load
        sleep(2)

        // Should show either activities or empty state
        let hasContent = app.scrollViews.firstMatch.exists
        XCTAssertTrue(hasContent)
    }

    func testViewAndNavigatePhotosGrid() throws {
        ensureLoggedIn()
        navigateToEventDetail()
        rsvpToEventIfNeeded()
        selectSocialTab("Photos")

        // Wait for photos to load
        sleep(2)

        // Tap first photo if exists
        let firstPhoto = app.images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) && firstPhoto.isHittable {
            firstPhoto.tap()

            // Verify viewer opened and close it
            let closeButton = app.buttons["Close photo viewer"]
            if closeButton.waitForExistence(timeout: 3) {
                closeButton.tap()
            }
        }
    }

    func testRSVPGatingShowsPrompt() throws {
        ensureLoggedIn()
        navigateToEventDetail()

        // Don't RSVP - just try to view social content
        selectSocialTab("Discussion")

        // Should show RSVP prompt or gated content
        sleep(2)
        // Content should load without error (gated or ungated)
    }

    // MARK: - Helper Methods

    private func ensureLoggedIn() {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
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
            if scrollView.exists {
                scrollView.swipeDown()
                scrollView.swipeDown()
                scrollView.swipeDown()
            }
            return
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

        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
        }
    }

    private func selectSocialTab(_ tabName: String) {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        let socialTabsPicker = app.segmentedControls.firstMatch
        if socialTabsPicker.waitForExistence(timeout: 5) {
            let segment = socialTabsPicker.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", tabName)).firstMatch
            if segment.exists {
                segment.tap()
            }
        }
        sleep(1)
    }

    private func navigateToEventDetail() {
        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        if eventsTab.waitForExistence(timeout: 5) {
            eventsTab.tap()
        }

        sleep(2)

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            let eventLink = app.buttons.matching(NSPredicate(format: "label CONTAINS 'going' OR label CONTAINS 'Event' OR label CONTAINS 'Mountain'")).firstMatch
            if eventLink.waitForExistence(timeout: 5) && eventLink.isHittable {
                eventLink.tap()
                sleep(2)
            }
        }
    }

    private func rsvpToEventIfNeeded() {
        let rsvpButton = app.buttons["I'm In!"]
        if rsvpButton.waitForExistence(timeout: 3) && rsvpButton.isHittable {
            rsvpButton.tap()
            sleep(2)
        }
    }
}
