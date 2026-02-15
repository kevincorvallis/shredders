//
//  EventSocialFlowUITests.swift
//  PowderTrackerUITests
//
//  UI tests for the complete RSVP and social features flow:
//  - RSVP to event
//  - Verify Discussion/Activity/Photos tabs unlock
//  - Leave a comment in Discussion
//  - View Activity feed
//

import XCTest

final class EventSocialFlowUITests: XCTestCase {
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

    // MARK: - Complete RSVP and Social Flow Test

    /// Tests the complete flow: RSVP -> Discussion unlocks -> Leave comment
    @MainActor
    func testCompleteRSVPAndDiscussionFlow() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()

        addScreenshot(named: "01_Events_List")

        // Navigate to first event
        try navigateToEventDetail()

        addScreenshot(named: "02_Event_Detail_Before_RSVP")

        // Check if we need to RSVP (look for "I'm In!" button)
        let goingButton = app.buttons["event_detail_going_button"]
        let rsvpStatusView = app.otherElements["event_detail_rsvp_status"]

        if goingButton.waitForExistence(timeout: 3) && goingButton.isHittable {
            // User hasn't RSVP'd yet - tap "I'm In!"
            goingButton.tap()
            Thread.sleep(forTimeInterval: 2)

            addScreenshot(named: "03_After_RSVP")

            // Verify RSVP status changed (should now show "You're going!" message)
            let statusText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] \"You're going\" OR label CONTAINS[c] \"You're a maybe\"")).firstMatch
            XCTAssertTrue(statusText.waitForExistence(timeout: 5), "RSVP status should update after RSVPing")
        } else if rsvpStatusView.exists {
            // User already RSVP'd
            print("User already has RSVP'd to this event")
        }

        // Now test the Discussion tab
        try testDiscussionTab()

        // Test the Activity tab
        try testActivityTab()

        // Test the Photos tab
        try testPhotosTab()
    }

    /// Tests RSVPing and then changing the RSVP status
    @MainActor
    func testChangeRSVPStatus() throws {
        launchApp()
        try ensureLoggedIn()
        navigateToEvents()
        try navigateToEventDetail()

        // If user has RSVP'd, test changing status
        let changeButton = app.buttons["Change"]
        if changeButton.waitForExistence(timeout: 3) && changeButton.isHittable {
            changeButton.tap()
            Thread.sleep(forTimeInterval: 1)

            addScreenshot(named: "RSVP_Change_Sheet")

            // Look for the RSVP sheet and tap a different status
            let maybeOption = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Maybe'")).firstMatch
            if maybeOption.waitForExistence(timeout: 3) && maybeOption.isHittable {
                maybeOption.tap()
            }

            // Look for confirm button
            let confirmButton = app.buttons["Confirm"]
            if confirmButton.waitForExistence(timeout: 3) && confirmButton.isHittable {
                confirmButton.tap()
                Thread.sleep(forTimeInterval: 2)
            }

            addScreenshot(named: "After_RSVP_Change")
        }
    }

    /// Tests that Discussion tab shows content after RSVP
    @MainActor
    func testDiscussionTab() throws {
        // Scroll to social tabs section
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Find and tap Discussion tab
        let discussionTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Discussion'")).firstMatch
        guard discussionTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Discussion tab not found")
        }
        discussionTab.tap()
        Thread.sleep(forTimeInterval: 1)

        addScreenshot(named: "04_Discussion_Tab")

        // Check if discussion content is visible (not gated)
        let gatedMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'RSVP to'")).firstMatch
        if gatedMessage.exists {
            XCTFail("Discussion should be unlocked after RSVP, but showing gated message")
        }

        // Try to leave a comment
        try leaveComment()
    }

    /// Tests that Activity tab shows content after RSVP
    @MainActor
    func testActivityTab() throws {
        // Find and tap Activity tab
        let activityTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Activity'")).firstMatch
        guard activityTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Activity tab not found")
        }
        activityTab.tap()
        Thread.sleep(forTimeInterval: 1)

        addScreenshot(named: "05_Activity_Tab")

        // Check if activity content is visible (not gated)
        let gatedMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'RSVP to see activity'")).firstMatch
        XCTAssertFalse(gatedMessage.exists, "Activity should be unlocked after RSVP")
    }

    /// Tests that Photos tab shows content after RSVP
    @MainActor
    func testPhotosTab() throws {
        // Find and tap Photos tab
        let photosTab = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Photos'")).firstMatch
        guard photosTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("Photos tab not found")
        }
        photosTab.tap()
        Thread.sleep(forTimeInterval: 1)

        addScreenshot(named: "06_Photos_Tab")

        // Check if photos content is visible (not gated)
        let gatedMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'RSVP to view'")).firstMatch
        XCTAssertFalse(gatedMessage.exists, "Photos should be unlocked after RSVP")
    }

    /// Tests leaving a comment in the Discussion
    @MainActor
    func leaveComment() throws {
        // Look for comment input field or "Add comment" button
        let commentField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'comment' OR placeholderValue CONTAINS[c] 'message'")).firstMatch
        let addCommentButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Add' OR label CONTAINS[c] 'Comment' OR label CONTAINS[c] 'Write'")).firstMatch

        if commentField.waitForExistence(timeout: 3) && commentField.isHittable {
            commentField.tap()
            Thread.sleep(forTimeInterval: 0.5)

            let testComment = "Test comment from UI test \(Int.random(in: 1000...9999))"
            commentField.typeText(testComment)

            addScreenshot(named: "07_Comment_Typed")

            // Find and tap send/post button
            let sendButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Send' OR label CONTAINS[c] 'Post' OR identifier CONTAINS 'send'")).firstMatch
            if sendButton.waitForExistence(timeout: 3) && sendButton.isHittable {
                sendButton.tap()
                Thread.sleep(forTimeInterval: 2)

                addScreenshot(named: "08_Comment_Posted")

                // Verify comment appears in the list
                let postedComment = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Test comment from UI test'")).firstMatch
                XCTAssertTrue(postedComment.waitForExistence(timeout: 5), "Posted comment should appear in discussion")
            }
        } else if addCommentButton.waitForExistence(timeout: 3) && addCommentButton.isHittable {
            addCommentButton.tap()
            Thread.sleep(forTimeInterval: 1)
            // Recursively try again after tapping the button
            try leaveComment()
        } else {
            print("Comment input not found - discussion may be empty or loading")
            addScreenshot(named: "07_Discussion_No_Input")
        }
    }

    // MARK: - Helper Methods

    @MainActor
    private func ensureLoggedIn() throws {
        try UITestHelper.ensureLoggedIn(app: app)
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
