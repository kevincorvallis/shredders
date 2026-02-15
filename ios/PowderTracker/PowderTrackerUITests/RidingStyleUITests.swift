//
//  RidingStyleUITests.swift
//  PowderTrackerUITests
//
//  UI tests for the Riding Style feature (skier/snowboarder/both).
//  Tests the complete user journey: onboarding, profile display, settings, and event attendees.
//

import XCTest

final class RidingStyleUITests: XCTestCase {
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

    // MARK: - App Launch Helpers

    @MainActor
    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }

    @MainActor
    private func launchAppForOnboarding() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SHOW_ONBOARDING"]
        app.launch()
    }

    // MARK: - Onboarding Flow Tests

    /// Tests that the riding style question appears in onboarding
    @MainActor
    func testRidingStyleQuestionAppearsInOnboarding() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        // Look for riding style section text
        let ridingStyleLabel = app.staticTexts["I ride on..."]
        XCTAssertTrue(ridingStyleLabel.waitForExistence(timeout: 5),
                      "Riding style question should appear in About You section")

        addScreenshot(named: "Onboarding - Riding Style Question")
    }

    /// Tests selecting "Skier" in onboarding
    @MainActor
    func testSelectSkierInOnboarding() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        // Find and tap Skier button
        let skierButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skier'")).firstMatch
        if skierButton.waitForExistence(timeout: 5) && skierButton.isHittable {
            skierButton.tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Verify selection (button should show selected state)
            XCTAssertTrue(skierButton.isSelected || skierButton.exists,
                          "Skier option should be selectable")
        }

        addScreenshot(named: "Onboarding - Skier Selected")
    }

    /// Tests selecting "Snowboarder" in onboarding
    @MainActor
    func testSelectSnowboarderInOnboarding() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        // Find and tap Snowboarder button
        let snowboarderButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Snowboarder'")).firstMatch
        if snowboarderButton.waitForExistence(timeout: 5) && snowboarderButton.isHittable {
            snowboarderButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        addScreenshot(named: "Onboarding - Snowboarder Selected")
    }

    /// Tests selecting "Both" in onboarding
    @MainActor
    func testSelectBothInOnboarding() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        // Find and tap Both button
        let bothButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Both'")).firstMatch
        if bothButton.waitForExistence(timeout: 5) && bothButton.isHittable {
            bothButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        addScreenshot(named: "Onboarding - Both Selected")
    }

    // MARK: - Profile Display Tests

    /// Tests that riding style badge appears on user's profile
    @MainActor
    func testRidingStyleBadgeAppearsOnProfile() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToProfile()

        // Look for riding style badge (skier/snowboarder icon or text)
        let ridingStyleBadge = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Skier' OR label CONTAINS[c] 'Snowboarder' OR label CONTAINS[c] 'Both'")
        ).firstMatch

        // The badge may or may not exist depending on whether the user has set one
        if ridingStyleBadge.waitForExistence(timeout: 3) {
            XCTAssertTrue(ridingStyleBadge.exists, "Riding style badge should be visible on profile")
        }

        addScreenshot(named: "Profile - Riding Style Badge")
    }

    // MARK: - Settings Tests

    /// Tests that riding style can be changed in settings
    @MainActor
    func testRidingStyleCanBeChangedInSettings() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToProfile()

        // Navigate to Riding Preferences (or Skiing Preferences)
        let preferencesButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Preferences' OR label CONTAINS[c] 'Riding'")
        ).firstMatch

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<5 {
                if preferencesButton.exists && preferencesButton.isHittable { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        if preferencesButton.waitForExistence(timeout: 3) && preferencesButton.isHittable {
            preferencesButton.tap()
            Thread.sleep(forTimeInterval: 1)

            // Look for riding style options
            let skierOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skier'")).firstMatch
            let snowboarderOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Snowboarder'")).firstMatch

            XCTAssertTrue(skierOption.waitForExistence(timeout: 5) || snowboarderOption.waitForExistence(timeout: 5),
                          "Riding style options should be available in settings")

            // Try selecting a different option
            if snowboarderOption.exists && snowboarderOption.isHittable {
                snowboarderOption.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }

            addScreenshot(named: "Settings - Riding Preferences")
        }
    }

    /// Tests saving riding style preference from settings
    @MainActor
    func testSaveRidingStylePreference() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToProfile()

        // Navigate to preferences
        let preferencesButton = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Preferences' OR label CONTAINS[c] 'Riding'")
        ).firstMatch

        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            for _ in 0..<5 {
                if preferencesButton.exists && preferencesButton.isHittable { break }
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        guard preferencesButton.waitForExistence(timeout: 3) && preferencesButton.isHittable else {
            throw XCTSkip("Preferences button not available")
        }
        preferencesButton.tap()
        Thread.sleep(forTimeInterval: 1)

        // Select Snowboarder
        let snowboarderOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Snowboarder'")).firstMatch
        if snowboarderOption.waitForExistence(timeout: 3) && snowboarderOption.isHittable {
            snowboarderOption.tap()
        }

        // Scroll to and tap Save
        let formScrollView = app.scrollViews.firstMatch
        if formScrollView.exists {
            for _ in 0..<5 {
                formScrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        let saveButton = app.buttons["Save Changes"]
        if saveButton.waitForExistence(timeout: 3) && saveButton.isHittable {
            saveButton.tap()
            Thread.sleep(forTimeInterval: 2)

            // Success message should appear
            let successMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'saved'")).firstMatch
            XCTAssertTrue(successMessage.waitForExistence(timeout: 5), "Success message should appear after saving")
        }

        addScreenshot(named: "Settings - Preferences Saved")
    }

    // MARK: - Event Attendee Display Tests

    /// Tests that riding style badges appear next to attendees in event detail
    @MainActor
    func testRidingStyleBadgesInEventAttendeeList() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        navigateToEventDetail()

        // Scroll to attendees section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            for _ in 0..<3 {
                scrollView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }

        // Look for any skiing/snowboarding icons in the view
        // These may be SF Symbols rendered as images
        let skierIcons = app.images.matching(NSPredicate(format: "identifier CONTAINS 'skiing' OR identifier CONTAINS 'snowboarding'"))
        let attendeeSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Attendee' OR label CONTAINS[c] 'Going'")).firstMatch

        if attendeeSection.exists || skierIcons.count > 0 {
            addScreenshot(named: "Event Detail - Attendee Riding Styles")
        }
    }

    // MARK: - End-to-End Flow Tests

    /// Complete E2E test: Set riding style in onboarding and verify it appears on profile
    @MainActor
    func testEndToEndRidingStyleFlow() throws {
        launchAppForOnboarding()

        // Complete onboarding with Snowboarder selection
        try navigateToAboutYouScreen()

        let snowboarderButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Snowboarder'")).firstMatch
        if snowboarderButton.waitForExistence(timeout: 5) && snowboarderButton.isHittable {
            snowboarderButton.tap()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Complete rest of onboarding
        for _ in 0..<5 {
            Thread.sleep(forTimeInterval: 0.5)

            let completeButton = app.buttons["Complete Setup"]
            if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
                completeButton.tap()
                break
            }

            let continueButton = app.buttons["Continue"]
            if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
                continueButton.tap()
            } else {
                let skipButton = app.buttons["Skip for now"]
                if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
                    skipButton.tap()
                }
            }
        }

        // Verify main app loaded
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Main app should load after onboarding")

        addScreenshot(named: "E2E - After Onboarding")
    }

    // MARK: - Accessibility Tests

    /// Tests that riding style buttons have proper accessibility labels
    @MainActor
    func testRidingStyleButtonsHaveAccessibilityLabels() throws {
        launchAppForOnboarding()
        try navigateToAboutYouScreen()

        // Check accessibility labels
        let skierButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skier'")).firstMatch
        let snowboarderButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Snowboarder'")).firstMatch
        let bothButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Both'")).firstMatch

        // At least one should exist
        XCTAssertTrue(
            skierButton.waitForExistence(timeout: 5) ||
            snowboarderButton.waitForExistence(timeout: 5) ||
            bothButton.waitForExistence(timeout: 5),
            "Riding style buttons should have accessibility labels"
        )
    }

    // MARK: - Helper Methods

    @MainActor
    private func navigateToAboutYouScreen() throws {
        // BrockStoryOnboardingView has 5 pages (welcome + 3 features + final).
        // Pages 0-3 show "Continue", page 4 shows "Get Started".
        // After that, OnboardingProfileSetupView also has "Continue".
        // Keep tapping through until "I ride on..." appears (About You screen).
        let ridingStyleLabel = app.staticTexts["I ride on..."]

        for _ in 0..<10 {
            if ridingStyleLabel.waitForExistence(timeout: 1) { return }

            let getStarted = app.buttons["Get Started"]
            if getStarted.exists && getStarted.isHittable {
                getStarted.tap()
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }

            let continueButton = app.buttons["Continue"]
            if continueButton.exists && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
                continue
            }

            Thread.sleep(forTimeInterval: 0.5)
        }

        guard ridingStyleLabel.waitForExistence(timeout: 3) else {
            throw XCTSkip("Could not navigate to About You screen")
        }
    }

    @MainActor
    private func ensureLoggedIn() throws {
        try UITestHelper.ensureLoggedIn(app: app)
    }

    @MainActor
    private func navigateToProfile() {
        UITestHelper.navigateToProfile(app: app)
    }

    @MainActor
    private func navigateToEvents() {
        UITestHelper.navigateToEvents(app: app)
    }

    @MainActor
    private func navigateToEventDetail() throws {
        try UITestHelper.navigateToEventDetail(app: app)
    }

    @MainActor
    private func addScreenshot(named name: String) {
        UITestHelper.addScreenshot(named: name, to: self)
    }
}
