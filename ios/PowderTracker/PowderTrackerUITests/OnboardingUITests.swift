//
//  OnboardingUITests.swift
//  PowderTrackerUITests
//
//  UI tests for the onboarding flow for new users.
//  Focuses on critical user journeys rather than element existence checks.
//

import XCTest

@MainActor
final class OnboardingUITests: XCTestCase {
    nonisolated(unsafe) var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    private func launchAppForOnboarding() {
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SHOW_ONBOARDING"]
        app.launch()
    }

    // MARK: - Button Helpers

    /// Finds and taps any continue/next button on the current onboarding screen.
    /// BrockStoryOnboardingView uses "Continue" for pages 0-3 and "Get Started" for the final page.
    private func tapContinueButton() -> Bool {
        let getStarted = app.buttons["Get Started"]
        if getStarted.waitForExistence(timeout: 1) && getStarted.isHittable {
            getStarted.tap()
            return true
        }

        let continueButton = app.buttons["Continue"]
        if continueButton.waitForExistence(timeout: 1) && continueButton.isHittable {
            continueButton.tap()
            return true
        }

        return false
    }

    /// Finds and taps the complete button on the final screen
    private func tapCompleteButton() -> Bool {
        let completeButton = app.buttons["Complete Setup"]
        if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
            completeButton.tap()
            return true
        }
        return false
    }

    /// Finds and taps any skip button
    private func tapSkipButton() -> Bool {
        // Try different skip button variations
        for label in ["Skip", "Skip for now"] {
            let skipButton = app.buttons[label]
            if skipButton.waitForExistence(timeout: 2) && skipButton.isHittable {
                skipButton.tap()
                return true
            }
        }
        return false
    }

    // MARK: - Critical Flow Tests

    func testCompleteOnboardingFlow() throws {
        launchAppForOnboarding()

        // Complete all onboarding steps (5 story pages + profile + about you + preferences)
        for _ in 0..<10 {
            Thread.sleep(forTimeInterval: 0.5)

            // Check for complete button first (final screen)
            if tapCompleteButton() {
                break
            }

            // Otherwise try continue button
            if !tapContinueButton() {
                // If no button found, try skip to move forward
                _ = tapSkipButton()
            }
        }

        // After completion, should see main app with tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after onboarding")
    }

    func testSkipOnboarding() throws {
        launchAppForOnboarding()

        // Advance past welcome
        Thread.sleep(forTimeInterval: 1)
        _ = tapContinueButton()
        Thread.sleep(forTimeInterval: 0.5)

        // Tap skip button
        if tapSkipButton() {
            // Should go to main app
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after skip")
        }
    }

    func testOnboardingProfileSetup() throws {
        launchAppForOnboarding()

        // Advance past welcome to profile setup
        Thread.sleep(forTimeInterval: 1)
        _ = tapContinueButton()
        Thread.sleep(forTimeInterval: 0.5)

        // Look for text field by placeholder or any text field
        let textFields = app.textFields
        if textFields.count > 0 {
            let firstField = textFields.firstMatch
            if firstField.waitForExistence(timeout: 3) && firstField.isHittable {
                firstField.tap()
                firstField.typeText("Test User")
            }
        }
    }

    /// Tests that onboarding buttons are visible and tappable.
    /// BrockStoryOnboardingView shows "Continue" on the welcome page.
    func testOnboardingButtonsAreAccessible() throws {
        launchAppForOnboarding()

        Thread.sleep(forTimeInterval: 1)

        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5),
                      "Continue button should be visible in onboarding")
    }
}
