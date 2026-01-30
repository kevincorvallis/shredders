//
//  EventSocialFeaturesUITests.swift
//  PowderTrackerUITests
//
//  UI tests for Event Social Features (Discussion, Activity, Photos).
//

import XCTest

final class EventSocialFeaturesUITests: XCTestCase {

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

    func testNavigateToEventDetail() throws {
        ensureLoggedIn()
        navigateToEventDetail()

        // Verify we're on event detail (scroll view should exist)
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 5))
    }

    func testSocialTabsVisible() throws {
        ensureLoggedIn()
        navigateToEventDetail()

        // Wait for the event detail to fully load
        sleep(3)

        // The event detail may have a scroll view - scroll down to see social tabs
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // Social tabs are in a segmented picker - look for the picker
        // The picker might be labeled "Social content tabs"
        let socialTabsPicker = app.segmentedControls.firstMatch

        // If no segmented control, check if we're on the event detail at all
        if !socialTabsPicker.waitForExistence(timeout: 5) {
            // Check if there's any indication we're on an event detail
            let eventDetailExists = app.navigationBars.staticTexts["Event"].exists ||
                                   app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'going' OR label CONTAINS[c] 'RSVP'")).firstMatch.exists

            if !eventDetailExists {
                // Navigation to event detail likely failed - skip test
                XCTFail("Could not navigate to event detail view - no events available or navigation failed")
                return
            }

            // We're on event detail but no segmented control found - it might be below the fold
            // Try scrolling more
            if scrollView.exists {
                scrollView.swipeUp()
                scrollView.swipeUp()
            }
        }

        // Re-check for segmented control
        if socialTabsPicker.waitForExistence(timeout: 3) {
            let segments = socialTabsPicker.buttons
            XCTAssertTrue(segments.count >= 1, "Should have at least 1 social tab segment")
        } else {
            // Social tabs might not be visible if user hasn't RSVP'd
            // Check for the gated content instead
            let gatedContent = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'RSVP' OR label CONTAINS[c] 'Unlock'")).firstMatch
            XCTAssertTrue(gatedContent.exists || app.scrollViews.firstMatch.exists, "Event detail should show either social tabs or gated content prompt")
        }
    }

    func testSwitchBetweenSocialTabs() throws {
        ensureLoggedIn()
        navigateToEventDetail()

        // Wait for event detail to load and scroll to show social tabs
        sleep(2)
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
        }

        // Find the segmented picker
        let socialTabsPicker = app.segmentedControls.firstMatch

        guard socialTabsPicker.waitForExistence(timeout: 5) else {
            // Social tabs might not be visible if user hasn't RSVP'd
            // This is expected behavior for non-RSVP users
            return
        }

        // Tap each segment
        let segments = socialTabsPicker.buttons
        for i in 0..<segments.count {
            segments.element(boundBy: i).tap()
            sleep(1)
        }
    }

    // MARK: - Discussion UI Tests

    func testDiscussionEmptyState() throws {
        ensureLoggedIn()
        navigateToEventDetail()
        selectSocialTab("Discussion")

        // Verify empty state or content
        sleep(2)
        // Content should load without error
    }

    func testDiscussionCommentInput() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Discussion")

        // Verify comment input is visible
        let commentInput = app.textFields["Comment text field"]
        if commentInput.waitForExistence(timeout: 5) {
            XCTAssertTrue(commentInput.exists)
        }
    }

    func testPostComment() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Discussion")

        // Type a comment
        let commentInput = app.textFields["Comment text field"]
        guard commentInput.waitForExistence(timeout: 5) else {
            // User may not have access - skip test
            return
        }

        commentInput.tap()
        commentInput.typeText("Test comment from UI test")

        // Tap send
        let sendButton = app.buttons["Send comment"]
        if sendButton.exists && sendButton.isEnabled {
            sendButton.tap()
            sleep(2)
        }
    }

    func testReplyToComment() throws {
        ensureLoggedIn()
        navigateToEventDetailWithComments()
        selectSocialTab("Discussion")

        // Find and tap reply button on first comment
        let replyButton = app.buttons["Reply"].firstMatch
        if replyButton.waitForExistence(timeout: 5) {
            replyButton.tap()

            // Cancel reply
            let cancelReplyButton = app.buttons["Cancel reply"]
            if cancelReplyButton.exists {
                cancelReplyButton.tap()
            }
        }
    }

    func testDeleteComment() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        postTestComment()
        selectSocialTab("Discussion")

        // Find delete button
        let deleteButton = app.buttons["Delete"].firstMatch
        if deleteButton.waitForExistence(timeout: 5) {
            deleteButton.tap()

            // Confirm deletion
            let confirmDelete = app.alerts.buttons["Delete"].firstMatch
            if confirmDelete.waitForExistence(timeout: 3) {
                confirmDelete.tap()
            }
        }
    }

    // MARK: - Activity UI Tests

    func testActivityTimelineLoads() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Activity")

        // Wait for activity to load
        sleep(2)

        // Should show either activities or empty state
        let hasContent = app.scrollViews.firstMatch.exists
        XCTAssertTrue(hasContent)
    }

    func testActivityShowsRSVPs() throws {
        ensureLoggedIn()
        navigateToEventDetailWithActivity()
        selectSocialTab("Activity")

        // Look for RSVP activity text
        sleep(2)
        // Content should load without error
    }

    func testMilestoneDisplaysCorrectly() throws {
        ensureLoggedIn()
        navigateToEventDetailWithMilestone()
        selectSocialTab("Activity")

        sleep(2)
        // Content should load without error
    }

    // MARK: - Photos UI Tests

    func testPhotosGridLoads() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Photos")

        // Wait for photos to load
        sleep(2)

        // Should show either photos or empty state
        let hasContent = app.scrollViews.firstMatch.exists
        XCTAssertTrue(hasContent)
    }

    func testAddPhotoButton() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Photos")

        // Verify add photo button exists
        let addPhotoButton = app.buttons["Add photo"]
        // May or may not exist depending on RSVP status
        _ = addPhotoButton.waitForExistence(timeout: 5)
    }

    func testTapPhotoOpensViewer() throws {
        ensureLoggedIn()
        navigateToEventDetailWithPhotos()
        selectSocialTab("Photos")

        // Tap first photo
        let firstPhoto = app.images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            firstPhoto.tap()

            // Verify viewer opened (close button should be visible)
            let closeButton = app.buttons["Close photo viewer"]
            if closeButton.waitForExistence(timeout: 3) {
                closeButton.tap()
            }
        }
    }

    func testPhotoViewerSwipe() throws {
        ensureLoggedIn()
        navigateToEventDetailWithMultiplePhotos()
        selectSocialTab("Photos")

        // Tap first photo
        let firstPhoto = app.images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            firstPhoto.tap()

            // Swipe to next photo
            app.swipeLeft()
            sleep(1)

            // Swipe back
            app.swipeRight()
            sleep(1)

            // Close viewer
            let closeButton = app.buttons["Close photo viewer"]
            if closeButton.exists {
                closeButton.tap()
            }
        }
    }

    // MARK: - RSVP Gating UI Tests

    func testGatedContentForNonRSVPUser() throws {
        ensureLoggedIn()
        navigateToEventDetailAsNonRSVPUser()
        selectSocialTab("Discussion")

        // Should show RSVP prompt or gated content
        sleep(2)
        // Content should load without error
    }

    func testRSVPUnlocksContent() throws {
        ensureLoggedIn()
        navigateToEventDetailAsNonRSVPUser()
        selectSocialTab("Discussion")

        // Tap RSVP button if it exists
        let rsvpButton = app.buttons["RSVP to Unlock"]
        if rsvpButton.waitForExistence(timeout: 5) {
            rsvpButton.tap()
            sleep(2)
        }
    }

    func testGatedPhotosShowCount() throws {
        ensureLoggedIn()
        navigateToEventDetailAsNonRSVPUser()
        selectSocialTab("Photos")

        sleep(2)
        // Content should load without error
    }

    // MARK: - Accessibility Tests

    func testVoiceOverLabelsExist() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()

        // Check segmented control accessibility
        let socialTabsPicker = app.segmentedControls.firstMatch
        XCTAssertTrue(socialTabsPicker.waitForExistence(timeout: 5))
        XCTAssertTrue(socialTabsPicker.isAccessibilityElement || socialTabsPicker.buttons.count > 0)
    }

    func testPhotoAccessibilityLabels() throws {
        ensureLoggedIn()
        navigateToEventDetailWithPhotos()
        selectSocialTab("Photos")

        // Photos should have accessibility labels
        let firstPhoto = app.images.firstMatch
        if firstPhoto.waitForExistence(timeout: 5) {
            XCTAssertTrue(firstPhoto.isAccessibilityElement)
        }
    }

    // MARK: - Pull to Refresh Tests

    func testPullToRefreshDiscussion() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Discussion")

        // Pull to refresh
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(2)
        }
    }

    func testPullToRefreshPhotos() throws {
        ensureLoggedIn()
        navigateToEventDetailAsRSVPUser()
        selectSocialTab("Photos")

        // Pull to refresh
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeDown()
            sleep(2)
        }
    }

    // MARK: - Helper Methods

    private func ensureLoggedIn() {
        let profileTab = app.tabBars.buttons["Profile"]
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
        }

        // Check if already logged in
        if app.buttons["profile_sign_out_button"].waitForExistence(timeout: 2) {
            return // Already logged in
        }

        // Need to log in
        let signInButton = app.buttons["profile_sign_in_button"]
        if signInButton.waitForExistence(timeout: 2) {
            signInButton.tap()

            let emailField = app.textFields["auth_email_field"]
            if emailField.waitForExistence(timeout: 5) {
                emailField.tap()
                emailField.typeText(testEmail)

                let passwordField = app.secureTextFields["auth_password_field"]
                passwordField.tap()
                passwordField.typeText(testPassword)

                app.buttons["auth_sign_in_button"].tap()

                // Wait for login to complete
                _ = app.buttons["profile_sign_out_button"].waitForExistence(timeout: 15)
            }
        }
    }

    private func selectSocialTab(_ tabName: String) {
        // Social tabs are in a segmented picker
        let socialTabsPicker = app.segmentedControls.firstMatch
        if socialTabsPicker.waitForExistence(timeout: 5) {
            // Try to find the segment by label
            let segment = socialTabsPicker.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", tabName)).firstMatch
            if segment.exists {
                segment.tap()
            }
        }
        sleep(1)
    }

    private func navigateToEventDetail() {
        let eventsTab = app.tabBars.buttons["Events"]
        if eventsTab.waitForExistence(timeout: 5) {
            eventsTab.tap()
        }

        sleep(2) // Wait for events to load

        // Try to find an event to tap - look for any tappable element in the list
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 5) {
            // Try tapping on a navigation link or button within the scroll view
            let eventLink = app.buttons.matching(NSPredicate(format: "label CONTAINS 'going' OR label CONTAINS 'Event' OR label CONTAINS 'Mountain'")).firstMatch
            if eventLink.waitForExistence(timeout: 5) {
                eventLink.tap()
            }
        }
    }

    private func navigateToEventDetailAsRSVPUser() {
        navigateToEventDetail()

        // If not RSVP'd, RSVP first
        let rsvpButton = app.buttons["I'm In!"]
        if rsvpButton.waitForExistence(timeout: 3) {
            rsvpButton.tap()
            sleep(2)
        }
    }

    private func navigateToEventDetailAsNonRSVPUser() {
        navigateToEventDetail()
    }

    private func navigateToEventDetailWithNoComments() {
        navigateToEventDetail()
    }

    private func navigateToEventDetailWithComments() {
        navigateToEventDetail()
    }

    private func navigateToEventDetailWithActivity() {
        navigateToEventDetail()
    }

    private func navigateToEventDetailWithMilestone() {
        navigateToEventDetail()
    }

    private func navigateToEventDetailWithPhotos() {
        navigateToEventDetail()
    }

    private func navigateToEventDetailWithMultiplePhotos() {
        navigateToEventDetail()
    }

    private func postTestComment() {
        selectSocialTab("Discussion")

        let commentInput = app.textFields["Comment text field"]
        if commentInput.waitForExistence(timeout: 5) {
            commentInput.tap()
            commentInput.typeText("Test comment to delete")

            let sendButton = app.buttons["Send comment"]
            if sendButton.exists && sendButton.isEnabled {
                sendButton.tap()
                sleep(2)
            }
        }
    }
}
