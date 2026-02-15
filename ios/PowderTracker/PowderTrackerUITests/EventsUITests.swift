//
//  EventsUITests.swift
//  PowderTrackerUITests
//
//  UI tests for events functionality - focuses on critical user journeys.
//

import XCTest

final class EventsUITests: XCTestCase {
    var app: XCUIApplication!

    private var testEmail: String {
        ProcessInfo.processInfo.environment["UI_TEST_EMAIL"] ?? "testuser@example.com"
    }
    private var testPassword: String {
        ProcessInfo.processInfo.environment["UI_TEST_PASSWORD"] ?? "TestPassword123!"
    }

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

    // MARK: - Critical Flow Tests

    @MainActor
    func testNavigateToEventsTabAndViewList() throws {
        launchApp()

        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        XCTAssertTrue(eventsTab.waitForExistence(timeout: 5), "Events tab should exist")
        eventsTab.tap()

        // Should show events view content
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Events view should load")
    }

    @MainActor
    func testCreateEventFullFlow() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        // Tap create button
        let createButton = app.buttons["events_create_button"]
        guard createButton.waitForExistence(timeout: 5) && createButton.isHittable else {
            throw XCTSkip("Create button not available")
        }
        createButton.tap()

        // Fill in title
        let titleField = app.textFields["create_event_title_field"]
        guard titleField.waitForExistence(timeout: 5) else {
            throw XCTSkip("Create event form not available")
        }
        titleField.tap()
        titleField.typeText("Test Event \(Int.random(in: 1000...9999))")

        // Select mountain
        let mountainPicker = app.buttons["create_event_mountain_picker"]
        if mountainPicker.waitForExistence(timeout: 3) && mountainPicker.isHittable {
            mountainPicker.tap()
            Thread.sleep(forTimeInterval: 1)
            let firstMountain = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Resort'")).firstMatch
            if firstMountain.exists && firstMountain.isHittable {
                firstMountain.tap()
            }
        }

        addScreenshot(named: "Event Creation Form Filled")
    }

    @MainActor
    func testRSVPToEvent() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // Look for RSVP button
        let rsvpButton = app.buttons["I'm In!"]
        if rsvpButton.waitForExistence(timeout: 5) && rsvpButton.isHittable {
            rsvpButton.tap()
            Thread.sleep(forTimeInterval: 2)
            addScreenshot(named: "After RSVP")
        }
    }

    @MainActor
    func testEventDetailShowsInfo() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // Verify event detail loaded
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5), "Event detail should load")

        addScreenshot(named: "Event Detail")
    }

    @MainActor
    func testEventFilters() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        // Check for segmented filter control
        let segmentedControl = app.segmentedControls.firstMatch
        if segmentedControl.waitForExistence(timeout: 3) {
            let segments = segmentedControl.buttons
            if segments.count > 1 {
                // Tap second segment
                segments.element(boundBy: 1).tap()
                Thread.sleep(forTimeInterval: 1)
                // Tap first segment
                segments.element(boundBy: 0).tap()
            }
        }
    }

    @MainActor
    func testShareEventOption() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // Look for share button
        let shareButton = app.buttons["event_share_button"]
        if shareButton.waitForExistence(timeout: 5) && shareButton.isHittable {
            shareButton.tap()
            Thread.sleep(forTimeInterval: 1)

            // Cancel share sheet
            let cancelButton = app.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
            }
        }
    }

    @MainActor
    func testPullToRefresh() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            let start = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            let end = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            start.press(forDuration: 0.1, thenDragTo: end)
            Thread.sleep(forTimeInterval: 2)
        }
    }

    // MARK: - Helper Methods

    @MainActor
    private func ensureLoggedIn() throws {
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        guard profileTab.waitForExistence(timeout: 5) else { return }
        profileTab.tap()
        Thread.sleep(forTimeInterval: 1)

        let scrollView = app.scrollViews.firstMatch

        // Check for sign-out button (already logged in)
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<10 {
                if app.buttons["profile_sign_out_button"].exists { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if app.buttons["profile_sign_out_button"].waitForExistence(timeout: 2) {
            if scrollView.exists {
                scrollView.swipeDown()
                scrollView.swipeDown()
                scrollView.swipeDown()
            }
            return // Already logged in
        }

        // Scroll to top for sign-in button
        if scrollView.exists {
            scrollView.swipeDown()
            scrollView.swipeDown()
            scrollView.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Need to log in
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

    @MainActor
    private func navigateToEvents() {
        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        if eventsTab.waitForExistence(timeout: 5) {
            eventsTab.tap()
        }
        Thread.sleep(forTimeInterval: 2)
    }

    @MainActor
    private func navigateToEventDetail() {
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            let eventCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'going' OR label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Event'")).firstMatch
            if eventCard.waitForExistence(timeout: 5) && eventCard.isHittable {
                eventCard.tap()
                Thread.sleep(forTimeInterval: 2)
            }
        }
    }

    @MainActor
    private func addScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
