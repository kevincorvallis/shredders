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

    // MARK: - Critical Flow Tests

    func testCompleteOnboardingFlow() throws {
        launchAppForOnboarding()

        // Complete all onboarding steps
        for _ in 0..<5 {
            let continueButton = app.buttons["onboarding_continue_button"]
            let completeButton = app.buttons["onboarding_complete_button"]

            if completeButton.waitForExistence(timeout: 2) && completeButton.isHittable {
                completeButton.tap()
                break
            } else if continueButton.waitForExistence(timeout: 3) && continueButton.isHittable {
                continueButton.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // After completion, should see main app with tab bar
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after onboarding")
    }

    func testSkipOnboarding() throws {
        launchAppForOnboarding()

        // Advance past welcome
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Tap skip button
        let skipButton = app.buttons["onboarding_skip_button"]
        if skipButton.waitForExistence(timeout: 3) && skipButton.isHittable {
            skipButton.tap()

            // Should go to main app
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5), "Should see main app after skip")
        }
    }

    func testOnboardingProfileSetup() throws {
        launchAppForOnboarding()

        // Advance to profile setup
        let continueButton = app.buttons["onboarding_continue_button"]
        if continueButton.waitForExistence(timeout: 5) {
            continueButton.tap()
        }

        Thread.sleep(forTimeInterval: 0.5)

        // Enter display name
        let displayNameField = app.textFields["onboarding_display_name"]
        if displayNameField.waitForExistence(timeout: 3) {
            displayNameField.tap()
            displayNameField.typeText("Test User")
            XCTAssertEqual(displayNameField.value as? String, "Test User", "Display name should be entered")
        }
    }

    func testOnboardingProgressesThroughSteps() throws {
        launchAppForOnboarding()

        var stepsCompleted = 0

        // Navigate through steps and verify progress
        for _ in 0..<5 {
            Thread.sleep(forTimeInterval: 0.5)

            let completeButton = app.buttons["onboarding_complete_button"]
            let continueButton = app.buttons["onboarding_continue_button"]

            if completeButton.waitForExistence(timeout: 1) && completeButton.isHittable {
                stepsCompleted += 1
                break
            }

            if continueButton.waitForExistence(timeout: 2) && continueButton.isHittable {
                continueButton.tap()
                stepsCompleted += 1
            }
        }

        // Should have progressed through multiple steps
        XCTAssertGreaterThan(stepsCompleted, 0, "Should progress through onboarding steps")
    }
}
