//
//  EventActivityViewModelTests.swift
//  PowderTrackerTests
//
//  Unit tests for EventActivityViewModel.
//

import XCTest
@testable import PowderTracker

@MainActor
final class EventActivityViewModelTests: XCTestCase {

    var viewModel: EventActivityViewModel!
    let testEventId = "test-event-123"

    override func setUp() async throws {
        viewModel = EventActivityViewModel(eventId: testEventId)
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.activities.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isLoadingMore)
        XCTAssertFalse(viewModel.hasMore)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testIsEmptyWhenNoActivitiesAndNotLoading() {
        viewModel.isLoading = false
        viewModel.activities = []
        XCTAssertTrue(viewModel.isEmpty)
    }

    func testIsNotEmptyWhenHasActivities() {
        viewModel.activities = [createMockActivity()]
        XCTAssertFalse(viewModel.isEmpty)
    }

    func testIsNotEmptyWhenLoading() {
        viewModel.isLoading = true
        viewModel.activities = []
        XCTAssertFalse(viewModel.isEmpty)
    }

    // MARK: - Gated State Tests

    func testGatedStateInitiallyTrue() {
        XCTAssertTrue(viewModel.isGated)
    }

    func testGatedMessageWhenGated() {
        viewModel.isGated = true
        viewModel.gatedMessage = "RSVP to see activity"
        XCTAssertEqual(viewModel.gatedMessage, "RSVP to see activity")
    }

    // MARK: - Pagination Tests

    func testHasMoreInitiallyFalse() {
        XCTAssertFalse(viewModel.hasMore)
    }

    func testLoadMoreGuardWhenAlreadyLoading() async {
        viewModel.isLoadingMore = true
        viewModel.hasMore = true

        // loadMoreIfNeeded should return early if already loading
        let activity = createMockActivity()
        viewModel.activities = [activity]
        await viewModel.loadMoreIfNeeded(currentItem: activity)

        // Should still be in loading state (no change)
        XCTAssertTrue(viewModel.isLoadingMore)
    }

    func testLoadMoreGuardWhenNoMore() async {
        viewModel.isLoadingMore = false
        viewModel.hasMore = false

        let activity = createMockActivity()
        viewModel.activities = [activity]
        await viewModel.loadMoreIfNeeded(currentItem: activity)

        // Should not trigger loading
        XCTAssertFalse(viewModel.isLoadingMore)
    }

    // MARK: - Activity Type Tests

    func testActivityTypeRSVP() {
        let activity = createMockActivity(type: .rsvpGoing)
        XCTAssertEqual(activity.activityType, .rsvpGoing)
        XCTAssertFalse(activity.isMilestone)
    }

    func testActivityTypeMilestone() {
        let activity = createMockActivity(type: .milestoneReached)
        XCTAssertEqual(activity.activityType, .milestoneReached)
        XCTAssertTrue(activity.isMilestone)
    }

    func testActivityTypeComment() {
        let activity = createMockActivity(type: .commentPosted)
        XCTAssertEqual(activity.activityType, .commentPosted)
        XCTAssertFalse(activity.isMilestone)
    }

    // MARK: - Activity Display Tests

    func testRSVPGoingDisplayText() {
        let activity = createMockActivity(type: .rsvpGoing, username: "JohnDoe")
        XCTAssertTrue(activity.displayText.contains("JohnDoe"))
        XCTAssertTrue(activity.displayText.lowercased().contains("going"))
    }

    // MARK: - Icon Tests

    func testRSVPGoingIcon() {
        let activity = createMockActivity(type: .rsvpGoing)
        XCTAssertEqual(activity.icon, "checkmark.circle.fill")
    }

    func testRSVPMaybeIcon() {
        let activity = createMockActivity(type: .rsvpMaybe)
        XCTAssertEqual(activity.icon, "questionmark.circle.fill")
    }

    func testCommentIcon() {
        let activity = createMockActivity(type: .commentPosted)
        XCTAssertEqual(activity.icon, "bubble.left.fill")
    }

    func testMilestoneIcon() {
        let activity = createMockActivity(type: .milestoneReached)
        XCTAssertEqual(activity.icon, "star.fill")
    }

    // MARK: - Helper Methods

    private func createMockActivity(
        id: String = "activity-1",
        type: ActivityType = .rsvpGoing,
        username: String = "testuser",
        milestone: Int? = nil
    ) -> EventActivity {
        // ActivityMetadata has a custom init(from:) so we create via JSON decoding
        let metadata = decodeMetadata(milestone: milestone)

        return EventActivity(
            id: id,
            eventId: testEventId,
            userId: "user-1",
            activityType: type,
            metadata: metadata,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            user: ActivityUser(
                id: "user-1",
                username: username,
                displayName: username,
                avatarUrl: nil
            )
        )
    }

    private func decodeMetadata(milestone: Int? = nil) -> ActivityMetadata {
        var json: [String: Any] = [:]
        if let milestone = milestone {
            json["milestone"] = milestone
            json["label"] = "\(milestone) attendees!"
        }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(ActivityMetadata.self, from: data)
    }
}
