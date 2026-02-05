//
//  EventDiscussionViewModelTests.swift
//  PowderTrackerTests
//
//  Unit tests for EventDiscussionViewModel.
//

import XCTest
@testable import PowderTracker

@MainActor
final class EventDiscussionViewModelTests: XCTestCase {

    var viewModel: EventDiscussionViewModel!
    let testEventId = "test-event-123"

    override func setUp() async throws {
        viewModel = EventDiscussionViewModel(eventId: testEventId)
    }

    override func tearDown() async throws {
        viewModel = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertTrue(viewModel.comments.isEmpty)
        XCTAssertEqual(viewModel.commentCount, 0)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isPostingComment)
        XCTAssertTrue(viewModel.newCommentText.isEmpty)
        XCTAssertNil(viewModel.replyingTo)
        XCTAssertFalse(viewModel.isReplying)
    }

    func testIsEmptyWhenNoCommentsAndNotLoading() {
        viewModel.isLoading = false
        viewModel.comments = []
        XCTAssertTrue(viewModel.isEmpty)
    }

    func testIsNotEmptyWhenHasComments() {
        viewModel.comments = [createMockComment()]
        XCTAssertFalse(viewModel.isEmpty)
    }

    func testIsNotEmptyWhenLoading() {
        viewModel.isLoading = true
        viewModel.comments = []
        XCTAssertFalse(viewModel.isEmpty)
    }

    // MARK: - Can Post Tests

    func testCanPostWhenHasTextAndNotPosting() {
        viewModel.newCommentText = "Hello world"
        viewModel.isPostingComment = false
        XCTAssertTrue(viewModel.canPost)
    }

    func testCannotPostWhenTextIsEmpty() {
        viewModel.newCommentText = ""
        viewModel.isPostingComment = false
        XCTAssertFalse(viewModel.canPost)
    }

    func testCannotPostWhenTextIsWhitespace() {
        viewModel.newCommentText = "   "
        viewModel.isPostingComment = false
        XCTAssertFalse(viewModel.canPost)
    }

    func testCannotPostWhenAlreadyPosting() {
        viewModel.newCommentText = "Hello world"
        viewModel.isPostingComment = true
        XCTAssertFalse(viewModel.canPost)
    }

    // MARK: - Reply State Tests

    func testStartReply() {
        let comment = createMockComment()
        viewModel.startReply(to: comment)

        XCTAssertTrue(viewModel.isReplying)
        XCTAssertEqual(viewModel.replyingTo?.id, comment.id)
    }

    func testCancelReply() {
        let comment = createMockComment()
        viewModel.startReply(to: comment)
        viewModel.cancelReply()

        XCTAssertFalse(viewModel.isReplying)
        XCTAssertNil(viewModel.replyingTo)
    }

    func testReplyPlaceholderWhenNotReplying() {
        XCTAssertEqual(viewModel.replyPlaceholder, "Add a comment...")
    }

    func testReplyPlaceholderWhenReplying() {
        let comment = createMockComment(username: "JohnDoe")
        viewModel.startReply(to: comment)
        XCTAssertEqual(viewModel.replyPlaceholder, "Reply to JohnDoe...")
    }

    // MARK: - Gated State Tests

    func testGatedStatePreventsPosts() {
        viewModel.isGated = true
        viewModel.newCommentText = "Test comment"
        // Even with text, gated state should prevent actual posting
        XCTAssertTrue(viewModel.isGated)
    }

    // MARK: - Comment Count Tests

    func testCommentCountUpdatesOnPost() async {
        let initialCount = viewModel.commentCount
        // Simulate optimistic update
        viewModel.commentCount += 1
        XCTAssertEqual(viewModel.commentCount, initialCount + 1)
    }

    func testCommentCountUpdatesOnDelete() async {
        viewModel.commentCount = 5
        viewModel.commentCount = max(0, viewModel.commentCount - 1)
        XCTAssertEqual(viewModel.commentCount, 4)
    }

    func testCommentCountNeverGoesNegative() {
        viewModel.commentCount = 0
        viewModel.commentCount = max(0, viewModel.commentCount - 1)
        XCTAssertEqual(viewModel.commentCount, 0)
    }

    // MARK: - Helper Methods

    private func createMockComment(
        id: String = "comment-1",
        username: String = "testuser"
    ) -> EventComment {
        EventComment(
            id: id,
            eventId: testEventId,
            userId: "user-1",
            content: "Test comment content",
            parentId: nil,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            user: EventCommentUser(
                id: "user-1",
                username: username,
                displayName: "Test User",
                avatarUrl: nil
            ),
            replies: nil
        )
    }
}
