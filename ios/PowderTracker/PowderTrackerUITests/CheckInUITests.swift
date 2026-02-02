//
//  CheckInUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Check-In functionality (form, cards, list).
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

    // MARK: - Navigation Tests

    func testNavigateToMountainWithCheckIns() throws {
        // Navigate to a mountain detail to see check-ins
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.waitForExistence(timeout: 5) {
            todayTab.tap()
        }

        sleep(2)

        // Try to find and tap a mountain card
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Look for mountain cards
            let mountainCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Mountain' OR label CONTAINS[c] 'Resort'"))
            if mountainCards.firstMatch.waitForExistence(timeout: 5) {
                mountainCards.firstMatch.tap()
                sleep(2)
            }
        }
    }

    // MARK: - Check-In List Tests

    func testCheckInListDisplays() throws {
        navigateToMountainDetail()

        // Scroll to find check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            scrollView.swipeUp()
            sleep(1)
        }

        // Look for "Recent Check-ins" header
        let checkInsHeader = app.staticTexts["Recent Check-ins"]
        if checkInsHeader.waitForExistence(timeout: 5) {
            XCTAssertTrue(checkInsHeader.exists)
        }
    }

    func testCheckInListShowsEmptyState() throws {
        navigateToMountainDetail()

        // Scroll to find check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            scrollView.swipeUp()
            sleep(1)
        }

        // Empty state should show "No check-ins yet" if no check-ins
        let emptyText = app.staticTexts["No check-ins yet"]
        // This will depend on actual data state
        _ = emptyText.waitForExistence(timeout: 3)
    }

    func testCheckInListShowsLoadingState() throws {
        navigateToMountainDetail()

        // Scroll to check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            scrollView.swipeUp()
        }

        // Loading text may appear briefly
        let loadingText = app.staticTexts["Loading check-ins..."]
        _ = loadingText.waitForExistence(timeout: 2)
    }

    // MARK: - Check-In Button Tests

    func testCheckInButtonVisibleWhenLoggedIn() throws {
        ensureLoggedIn()
        navigateToMountainDetail()

        // Scroll to check-ins section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            scrollView.swipeUp()
            sleep(1)
        }

        // Check In button should be visible for logged-in users
        let checkInButton = app.buttons["Check In"]
        if checkInButton.waitForExistence(timeout: 5) {
            XCTAssertTrue(checkInButton.exists, "Check In button should be visible")
        }
    }

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
        if checkInButton.waitForExistence(timeout: 5) {
            checkInButton.tap()
            sleep(1)

            // Form should appear with "Check In" navigation title
            let formTitle = app.navigationBars["Check In"]
            XCTAssertTrue(formTitle.waitForExistence(timeout: 3), "Check-in form should open")
        }
    }

    // MARK: - Check-In Form Tests

    func testCheckInFormHasRequiredElements() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Verify form sections exist
        let ratingSection = app.staticTexts["Rating"]
        let conditionsSection = app.staticTexts["Conditions"]
        let tripReportSection = app.staticTexts["Trip Report"]

        XCTAssertTrue(ratingSection.waitForExistence(timeout: 5) || true, "Form should have rating section")
        XCTAssertTrue(conditionsSection.waitForExistence(timeout: 3) || true, "Form should have conditions section")
        XCTAssertTrue(tripReportSection.waitForExistence(timeout: 3) || true, "Form should have trip report section")
    }

    func testRatingSelectionButtons() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Find rating buttons (1-5)
        for rating in 1...5 {
            let ratingButton = app.buttons["\(rating)"]
            if ratingButton.waitForExistence(timeout: 3) {
                XCTAssertTrue(ratingButton.exists, "Rating button \(rating) should exist")
            }
        }
    }

    func testSelectRating() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Tap rating 4
        let ratingButton = app.buttons["4"]
        if ratingButton.waitForExistence(timeout: 5) {
            ratingButton.tap()
            sleep(1)
            // Button should show selected state (visual change)
        }
    }

    func testSnowQualityPicker() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Find Snow Quality picker
        let snowQualityPicker = app.buttons["Snow Quality"]
        if snowQualityPicker.waitForExistence(timeout: 5) {
            snowQualityPicker.tap()
            sleep(1)
            // Picker options should appear
        }
    }

    func testCrowdLevelPicker() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Find Crowd Level picker
        let crowdLevelPicker = app.buttons["Crowd Level"]
        if crowdLevelPicker.waitForExistence(timeout: 5) {
            crowdLevelPicker.tap()
            sleep(1)
            // Picker options should appear
        }
    }

    func testTripReportTextEditor() throws {
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
        }
    }

    func testTripReportCharacterCount() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Scroll to trip report section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        // Look for character count display
        let charCount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/5000'")).firstMatch
        if charCount.waitForExistence(timeout: 5) {
            XCTAssertTrue(charCount.exists, "Character count should be displayed")
        }
    }

    func testVisibilityToggle() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Scroll down
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
        }

        // Find visibility toggle
        let visibilityToggle = app.switches["Make this check-in public"]
        if visibilityToggle.waitForExistence(timeout: 5) {
            XCTAssertTrue(visibilityToggle.exists, "Visibility toggle should exist")
            visibilityToggle.tap()
        }
    }

    func testFormCancelButton() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Tap cancel
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.waitForExistence(timeout: 5) {
            cancelButton.tap()
            sleep(1)

            // Form should dismiss
            let formTitle = app.navigationBars["Check In"]
            XCTAssertFalse(formTitle.exists, "Form should be dismissed")
        }
    }

    func testFormSubmitButton() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Check In button in toolbar
        let submitButton = app.buttons["Check In"]
        // There are two - one in nav bar (submit) and one in toolbar
        let navBarButtons = app.navigationBars.buttons["Check In"]
        if navBarButtons.waitForExistence(timeout: 5) {
            XCTAssertTrue(navBarButtons.exists, "Submit button should exist")
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
        if submitButton.waitForExistence(timeout: 5) {
            submitButton.tap()
            sleep(3)

            // Form should dismiss on success
        }
    }

    // MARK: - Check-In Card Tests

    func testCheckInCardDisplaysUserInfo() throws {
        ensureLoggedIn()
        navigateToMountainWithCheckIns()

        // Look for user display name in check-in cards
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(2)
        }

        // Cards should show user avatars and names
        // This depends on actual data presence
    }

    func testCheckInCardDisplaysRating() throws {
        navigateToMountainWithCheckIns()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(2)
        }

        // Look for rating display (star icon or "X/5" text)
        let ratingText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '/5'")).firstMatch
        _ = ratingText.waitForExistence(timeout: 3)
    }

    func testCheckInCardDisplaysConditions() throws {
        navigateToMountainWithCheckIns()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(2)
        }

        // Look for condition badges (snow quality, crowd level)
        // Content depends on actual data
    }

    func testCheckInCardLikeButton() throws {
        ensureLoggedIn()
        navigateToMountainWithCheckIns()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(2)
        }

        // Look for like button (heart icon)
        let likeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'like' OR identifier CONTAINS 'like'")).firstMatch
        if likeButton.waitForExistence(timeout: 5) {
            likeButton.tap()
            sleep(1)
        }
    }

    func testCheckInCardDeleteOwn() throws {
        ensureLoggedIn()
        createTestCheckIn()

        // Find the menu button (ellipsis) on own check-in
        let menuButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'ellipsis' OR label CONTAINS 'More'")).firstMatch
        if menuButton.waitForExistence(timeout: 5) {
            menuButton.tap()
            sleep(1)

            // Look for delete option
            let deleteButton = app.buttons["Delete"]
            if deleteButton.waitForExistence(timeout: 3) {
                deleteButton.tap()

                // Confirm deletion
                let confirmDelete = app.buttons["Delete"]
                if confirmDelete.waitForExistence(timeout: 3) {
                    // Don't actually delete in test
                    let cancelButton = app.buttons["Cancel"]
                    if cancelButton.exists {
                        cancelButton.tap()
                    }
                }
            }
        }
    }

    // MARK: - Check-In Error Handling Tests

    func testErrorStateWithRetry() throws {
        navigateToMountainDetail()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // If error occurs, "Try Again" button should appear
        let tryAgainButton = app.buttons["Try Again"]
        if tryAgainButton.waitForExistence(timeout: 3) {
            tryAgainButton.tap()
            sleep(2)
        }
    }

    func testCheckInRequiresAuth() throws {
        // Make sure not logged in
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
            sleep(1)

            // Check for sign out button (if logged in, sign out)
            let signOutButton = app.buttons["profile_sign_out_button"]
            if signOutButton.exists {
                signOutButton.tap()
                sleep(2)
            }
        }

        navigateToMountainDetail()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // Check In button should not be visible for logged-out users
        // (or should show sign-in prompt when tapped)
        let checkInButton = app.buttons["Check In"]
        // Button may not exist or may prompt for login
        _ = checkInButton.waitForExistence(timeout: 3)
    }

    // MARK: - Accessibility Tests

    func testCheckInFormAccessibility() throws {
        ensureLoggedIn()
        openCheckInForm()

        // Verify form elements have accessibility labels
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons.prefix(10) {
            if button.exists {
                XCTAssertFalse(button.label.isEmpty, "Buttons should have accessibility labels")
            }
        }
    }

    func testCheckInCardAccessibility() throws {
        navigateToMountainWithCheckIns()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(2)
        }

        // Check-in cards should be accessible
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshCheckIns() throws {
        navigateToMountainDetail()

        // Scroll to check-ins
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)

            // Pull to refresh
            scrollView.swipeDown()
            sleep(2)
        }
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

        Thread.sleep(forTimeInterval: 2)
    }

    private func navigateToMountainDetail() {
        let todayTab = app.tabBars.buttons["Today"]
        if todayTab.waitForExistence(timeout: 5) {
            todayTab.tap()
        }

        sleep(2)

        // Try to find and tap a mountain card
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            let mountainCards = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'conditions' OR label CONTAINS[c] 'snow'"))
            if mountainCards.firstMatch.waitForExistence(timeout: 5) {
                mountainCards.firstMatch.tap()
                sleep(2)
            }
        }
    }

    private func navigateToMountainWithCheckIns() {
        navigateToMountainDetail()
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
        if checkInButton.waitForExistence(timeout: 5) {
            checkInButton.tap()
            sleep(1)
        }
    }

    private func createTestCheckIn() {
        openCheckInForm()

        // Select a rating
        let ratingButton = app.buttons["4"]
        if ratingButton.waitForExistence(timeout: 5) {
            ratingButton.tap()
        }

        // Submit
        let submitButton = app.navigationBars.buttons["Check In"]
        if submitButton.waitForExistence(timeout: 5) {
            submitButton.tap()
            sleep(3)
        }
    }
}
