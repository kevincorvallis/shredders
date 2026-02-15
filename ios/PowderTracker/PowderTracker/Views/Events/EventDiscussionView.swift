//
//  EventDiscussionView.swift
//  PowderTracker
//
//  Discussion/comments view for events with threading support.
//

import SwiftUI
import NukeUI

struct EventDiscussionView: View {
    let eventId: String
    let isHost: Bool
    @State private var viewModel: EventDiscussionViewModel

    init(eventId: String, isHost: Bool = false) {
        self.eventId = eventId
        self.isHost = isHost
        self._viewModel = State(initialValue: EventDiscussionViewModel(eventId: eventId))
    }

    /// Host overrides API gating — the host should never be locked out of their own discussion
    private var effectivelyGated: Bool {
        if isHost { return false }
        return viewModel.isGated
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && !viewModel.hasLoaded {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if effectivelyGated {
                gatedView
            } else if viewModel.isEmpty {
                emptyView
            } else {
                commentsList
            }

            // Comment input (only if not gated)
            if !effectivelyGated && viewModel.hasLoaded {
                commentInputBar
            }
        }
        .task {
            await viewModel.loadComments()
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: .spacingM) {
            ProgressView()
            Text("Loading discussion...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: .spacingM) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("Couldn't load discussion")
                .font(.headline)
                .foregroundStyle(.primary)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await viewModel.loadComments() }
            } label: {
                Text("Try Again")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Gated View (RSVP Required)

    private var gatedView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: .spacingS) {
                Text("\(viewModel.commentCount) comments")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(viewModel.gatedMessage ?? "RSVP to join the conversation")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(
            // Blurred background effect
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: .spacingL) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary.opacity(0.5))

            VStack(spacing: .spacingS) {
                Text("No comments yet")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(isHost ? "Kick off the conversation as the host!" : "Be the first to start the conversation!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Comments List

    private var commentsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: .spacingM) {
                ForEach(viewModel.comments) { comment in
                    EventCommentRowView(
                        comment: comment,
                        onReply: { viewModel.startReply(to: comment) },
                        onDelete: { await viewModel.deleteComment(comment) }
                    )

                    // Replies
                    if let replies = comment.replies, !replies.isEmpty {
                        ForEach(replies) { reply in
                            EventCommentRowView(
                                comment: reply,
                                isReply: true,
                                onReply: { viewModel.startReply(to: comment) },
                                onDelete: { await viewModel.deleteComment(reply) }
                            )
                        }
                    }
                }
            }
            .padding(.spacingM)
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    // MARK: - Comment Input Bar

    private var commentInputBar: some View {
        VStack(spacing: 0) {
            Divider()

            // Reply indicator
            if viewModel.isReplying, let replyingTo = viewModel.replyingTo {
                HStack {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)

                    Text("Replying to \(replyingTo.user.displayNameOrUsername)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        viewModel.cancelReply()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Cancel reply")
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background(Color(.secondarySystemBackground))
                .accessibilityElement(children: .combine)
            }

            // Input field
            HStack(spacing: .spacingS) {
                TextField(viewModel.replyPlaceholder, text: $viewModel.newCommentText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.horizontal, .spacingM)
                    .padding(.vertical, .spacingS)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusPill)
                    .accessibilityLabel("Comment text field")
                    .accessibilityHint(viewModel.isReplying ? "Type your reply" : "Type your comment")

                Button {
                    Task {
                        await viewModel.postComment()
                    }
                } label: {
                    Group {
                        if viewModel.isPostingComment {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                        }
                    }
                    .frame(width: 36, height: 36)
                }
                .disabled(!viewModel.canPost)
                .foregroundStyle(viewModel.canPost ? .blue : .secondary)
                .accessibilityLabel(viewModel.isPostingComment ? "Posting comment" : "Send comment")
                .accessibilityHint(viewModel.canPost ? "Double tap to post your comment" : "Enter text to enable")
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(Color(.systemBackground))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Comment input area")
    }
}

// MARK: - Event Comment Row View

private struct EventCommentRowView: View {
    let comment: EventComment
    var isReply: Bool = false
    let onReply: () -> Void
    let onDelete: () async -> Void

    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .top, spacing: .spacingS) {
            // Indent for replies
            if isReply {
                Color.clear
                    .frame(width: 24)
            }

            // Avatar
            LazyImage(url: URL(string: comment.user.avatarUrl ?? "")) { state in
                if let image = state.image {
                    image
                        .resizable()
                        .scaledToFill()
                } else {
                    Circle()
                        .fill(avatarGradient)
                        .overlay(
                            Text(comment.user.displayNameOrUsername.prefix(1).uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        )
                }
            }
            .frame(width: isReply ? 28 : 36, height: isReply ? 28 : 36)
            .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: .spacingXS) {
                // Name and time
                HStack(spacing: .spacingXS) {
                    Text(comment.user.displayNameOrUsername)
                        .font(isReply ? .caption : .subheadline)
                        .fontWeight(.semibold)

                    Text("·")
                        .foregroundStyle(.tertiary)

                    Text(comment.relativeTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Comment text
                Text(comment.content)
                    .font(isReply ? .caption : .subheadline)
                    .foregroundStyle(.primary)

                // Actions
                HStack(spacing: .spacingM) {
                    Button {
                        onReply()
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Only show delete for own comments (simplified check)
                    Button {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, .spacingXS)
            }

            Spacer()
        }
        .padding(.vertical, .spacingXS)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(comment.user.displayNameOrUsername) said: \(comment.content). \(comment.relativeTime)")
        .accessibilityHint("Double tap to reply, or swipe right for more options")
        .confirmationDialog(
            "Delete Comment",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await onDelete()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this comment?")
        }
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventDiscussionView(eventId: "preview-event-id", isHost: true)
            .navigationTitle("Discussion")
    }
}
