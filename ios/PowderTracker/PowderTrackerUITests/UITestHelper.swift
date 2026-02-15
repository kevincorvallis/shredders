//
//  UITestHelper.swift
//  PowderTrackerUITests
//
//  Shared helpers for UI tests to eliminate duplication.
//

import XCTest

enum UITestHelper {

    /// Ensures the user is logged in via Profile tab.
    /// Checks for sign-out button (already logged in), otherwise signs in.
    @MainActor
    static func ensureLoggedIn(
        app: XCUIApplication,
        email: String = ProcessInfo.processInfo.environment["UI_TEST_EMAIL"] ?? "testuser@example.com",
        password: String = ProcessInfo.processInfo.environment["UI_TEST_PASSWORD"] ?? "TestPassword123!"
    ) throws {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        guard profileTab.waitForExistence(timeout: 5) else { return }
        profileTab.tap()
        Thread.sleep(forTimeInterval: 1)

        let scrollView = app.scrollViews.firstMatch

        // Scroll to find sign-out button (indicates already logged in)
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if app.buttons["profile_sign_out_button"].waitForExistence(timeout: 2) {
            scrollToTop(scrollView: scrollView)
            return // Already logged in
        }

        // Not logged in — scroll to top and sign in
        scrollToTop(scrollView: scrollView)

        let signInButton = app.buttons["profile_sign_in_button"]
        guard signInButton.waitForExistence(timeout: 5) && signInButton.isHittable else {
            throw XCTSkip("Sign in button not available")
        }
        signInButton.tap()

        let emailField = app.textFields["auth_email_field"]
        guard emailField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Auth form not available")
        }
        emailField.tap()
        emailField.typeText(email)

        let passwordField = app.secureTextFields["auth_password_field"]
        passwordField.tap()
        passwordField.typeText(password)

        app.buttons["auth_sign_in_button"].tap()
        Thread.sleep(forTimeInterval: 3)

        scrollToTop(scrollView: scrollView)
    }

    /// Navigate to the Profile tab.
    @MainActor
    static func navigateToProfile(app: XCUIApplication) {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
        }
        Thread.sleep(forTimeInterval: 1)
    }

    /// Navigate to the Events tab.
    @MainActor
    static func navigateToEvents(app: XCUIApplication) {
        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        if eventsTab.waitForExistence(timeout: 5) {
            eventsTab.tap()
        }
        Thread.sleep(forTimeInterval: 2)
    }

    /// Navigate into the first available event detail.
    @MainActor
    static func navigateToEventDetail(app: XCUIApplication) throws {
        let scrollView = app.scrollViews.firstMatch
        guard scrollView.waitForExistence(timeout: 5) else {
            throw XCTSkip("Events list not loaded")
        }

        let eventCard = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'going' OR label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Event'")
        ).firstMatch

        guard eventCard.waitForExistence(timeout: 5) && eventCard.isHittable else {
            throw XCTSkip("No events available to test")
        }

        eventCard.tap()
        Thread.sleep(forTimeInterval: 2)
    }

    /// Navigate to a mountain detail from the Mountains tab.
    @MainActor
    static func navigateToMountainDetail(app: XCUIApplication) throws {
        let mountainsTab = app.tabBars.buttons["Mountains"].firstMatch
        guard mountainsTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Mountains tab not available")
        }
        mountainsTab.tap()
        Thread.sleep(forTimeInterval: 2)

        let mountainCard = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed'")
        ).firstMatch
        guard mountainCard.waitForExistence(timeout: 5) && mountainCard.isHittable else {
            throw XCTSkip("No mountain cards available")
        }
        mountainCard.tap()
        Thread.sleep(forTimeInterval: 2)
    }

    /// Take and attach a screenshot.
    @MainActor
    static func addScreenshot(named name: String, to testCase: XCTestCase) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)
    }

    // MARK: - Private

    @MainActor
    private static func scrollToTop(scrollView: XCUIElement) {
        guard scrollView.exists else { return }
        scrollView.swipeDown()
        scrollView.swipeDown()
        scrollView.swipeDown()
    }
}
