//
//  OnboardingSnapshotTests.swift
//  PowderTrackerTests
//
//  Snapshot tests for onboarding views.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import PowderTracker

final class OnboardingSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    // MARK: - PookieBSnow Intro View Tests (New App Intro with Brock)

    func testPookieBSnowIntroView() {
        // Note: This view has heavy animations, snapshot captures initial state
        let view = PookieBSnowIntroView(showIntro: .constant(true))
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testPookieBSnowIntroView_darkMode() {
        let view = PookieBSnowIntroView(showIntro: .constant(true))
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }

    // MARK: - Welcome View Tests

    func testOnboardingWelcomeView() {
        let view = OnboardingWelcomeView(onContinue: {})
            .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Profile Setup Tests

    func testOnboardingProfileSetupView_empty() {
        let profile = OnboardingProfile()
        let view = OnboardingProfileSetupView(
            profile: .constant(profile),
            onContinue: {},
            onSkip: {}
        )
        .snapshotContainer()

        assertViewSnapshot(view)
    }

    func testOnboardingProfileSetupView_filled() {
        var profile = OnboardingProfile()
        profile.displayName = "Ski Enthusiast"
        let view = OnboardingProfileSetupView(
            profile: .constant(profile),
            onContinue: {},
            onSkip: {}
        )
        .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - About You Tests

    func testOnboardingAboutYouView() {
        let profile = OnboardingProfile()
        let view = OnboardingAboutYouView(
            profile: .constant(profile),
            onContinue: {},
            onSkip: {}
        )
        .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Preferences Tests

    func testOnboardingPreferencesView() {
        let profile = OnboardingProfile()
        let view = OnboardingPreferencesView(
            profile: .constant(profile),
            onComplete: {},
            onSkip: {}
        )
        .snapshotContainer()

        assertViewSnapshot(view)
    }

    // MARK: - Progress View Tests

    func testOnboardingProgressView_step1() {
        let view = OnboardingProgressView(currentStep: 1, totalSteps: 4)
            .componentSnapshot(width: 200)

        assertComponentSnapshot(view)
    }

    func testOnboardingProgressView_step3() {
        let view = OnboardingProgressView(currentStep: 3, totalSteps: 4)
            .componentSnapshot(width: 200)

        assertComponentSnapshot(view)
    }

    // MARK: - Dark Mode Tests

    func testOnboarding_darkMode() {
        let view = OnboardingWelcomeView(onContinue: {})
            .snapshotContainer()

        assertDarkModeSnapshot(view)
    }
}
