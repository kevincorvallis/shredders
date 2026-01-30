//
//  EventDiscussionViewModel.swift
//  PowderTracker
//
//  ViewModel for event discussion/comments with RSVP gating support.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class EventDiscussionViewModel {

    // MARK: - State

    var comments: [EventComment] = []
    var commentCount: Int = 0
    var isGated: Bool = true
    var gatedMessage: String?

    var isLoading: Bool = false
    var isPostingComment: Bool = false
    var errorMessage: String?

    var newCommentText: String = ""
    var replyingTo: EventComment?

    // MARK: - Private

    private let eventId: String
    private let eventService = EventService.shared

    // MARK: - Initialization

    init(eventId: String) {
        self.eventId = eventId
    }

    // MARK: - Public Methods

    /// Load comments for the event
    func loadComments() async {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await eventService.fetchComments(eventId: eventId)
            comments = response.comments
            commentCount = response.commentCount
            isGated = response.gated
            gatedMessage = response.message
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Post a new comment with optimistic update
    func postComment() async {
        let content = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        guard !isPostingComment else { return }

        isPostingComment = true
        errorMessage = nil

        // Store the parent ID before clearing
        let parentId = replyingTo?.id

        // Optimistic update: Create a temporary comment
        let tempId = UUID().uuidString
        let tempComment = createOptimisticComment(
            id: tempId,
            content: content,
            parentId: parentId
        )

        // Add to UI immediately
        if let parentId = parentId {
            // Add as reply
            if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                var parent = comments[parentIndex]
                var replies = parent.replies ?? []
                replies.append(tempComment)
                parent.replies = replies
                comments[parentIndex] = parent
            }
        } else {
            // Add as top-level comment
            comments.append(tempComment)
        }

        // Clear input
        newCommentText = ""
        replyingTo = nil

        // Haptic feedback
        HapticFeedback.light.trigger()

        do {
            // Actually post to server
            let postedComment = try await eventService.postComment(
                eventId: eventId,
                content: content,
                parentId: parentId
            )

            // Replace temp comment with real one
            if let parentId = parentId {
                if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                    var parent = comments[parentIndex]
                    var replies = parent.replies ?? []
                    if let tempIndex = replies.firstIndex(where: { $0.id == tempId }) {
                        replies[tempIndex] = postedComment
                    }
                    parent.replies = replies
                    comments[parentIndex] = parent
                }
            } else {
                if let tempIndex = comments.firstIndex(where: { $0.id == tempId }) {
                    comments[tempIndex] = postedComment
                }
            }

            commentCount += 1
            HapticFeedback.success.trigger()
        } catch {
            // Remove optimistic comment on failure
            if let parentId = parentId {
                if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                    var parent = comments[parentIndex]
                    var replies = parent.replies ?? []
                    replies.removeAll { $0.id == tempId }
                    parent.replies = replies
                    comments[parentIndex] = parent
                }
            } else {
                comments.removeAll { $0.id == tempId }
            }

            errorMessage = error.localizedDescription
            HapticFeedback.error.trigger()
        }

        isPostingComment = false
    }

    /// Delete a comment
    func deleteComment(_ comment: EventComment) async {
        // Optimistically remove from UI
        let originalComments = comments

        if let parentId = comment.parentId {
            // Remove from replies
            if let parentIndex = comments.firstIndex(where: { $0.id == parentId }) {
                var parent = comments[parentIndex]
                var replies = parent.replies ?? []
                replies.removeAll { $0.id == comment.id }
                parent.replies = replies
                comments[parentIndex] = parent
            }
        } else {
            // Remove top-level comment (and its replies)
            comments.removeAll { $0.id == comment.id }
        }

        commentCount = max(0, commentCount - 1)
        HapticFeedback.light.trigger()

        do {
            try await eventService.deleteComment(eventId: eventId, commentId: comment.id)
            HapticFeedback.success.trigger()
        } catch {
            // Restore on failure
            comments = originalComments
            commentCount += 1
            errorMessage = error.localizedDescription
            HapticFeedback.error.trigger()
        }
    }

    /// Start replying to a comment
    func startReply(to comment: EventComment) {
        replyingTo = comment
        HapticFeedback.selection.trigger()
    }

    /// Cancel reply
    func cancelReply() {
        replyingTo = nil
    }

    /// Refresh comments
    func refresh() async {
        await loadComments()
    }

    // MARK: - Computed Properties

    var isEmpty: Bool {
        comments.isEmpty && !isLoading
    }

    var canPost: Bool {
        !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isPostingComment
    }

    var isReplying: Bool {
        replyingTo != nil
    }

    var replyPlaceholder: String {
        if let replyingTo = replyingTo {
            return "Reply to \(replyingTo.user.displayNameOrUsername)..."
        }
        return "Add a comment..."
    }

    // MARK: - Private Helpers

    private func createOptimisticComment(id: String, content: String, parentId: String?) -> EventComment {
        // Get current user info (simplified - in production, get from AuthService)
        let currentUser = EventCommentUser(
            id: "temp",
            username: "You",
            displayName: nil,
            avatarUrl: nil
        )

        let now = ISO8601DateFormatter().string(from: Date())

        return EventComment(
            id: id,
            eventId: eventId,
            userId: currentUser.id,
            content: content,
            parentId: parentId,
            createdAt: now,
            updatedAt: now,
            user: currentUser,
            replies: nil
        )
    }
}
