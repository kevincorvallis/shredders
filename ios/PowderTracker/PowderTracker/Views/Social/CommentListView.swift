import SwiftUI
import NukeUI

// MARK: - Comment List View

struct CommentListView: View {

    // MARK: - Target Type

    enum TargetType {
        case mountain(String)
        case webcam(String)
        case photo(String)
        case checkIn(String)
    }

    // MARK: - Properties

    let target: TargetType
    let limit: Int

    @Environment(AuthService.self) private var authService
    @State private var comments: [Comment] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var replyingToId: String?
    @State private var newCommentText = ""
    @State private var showingCommentInput = false

    // MARK: - Initialization

    init(target: TargetType, limit: Int = 50) {
        self.target = target
        self.limit = limit
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Comments")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                if authService.isAuthenticated {
                    Button {
                        showingCommentInput.toggle()
                    } label: {
                        Image(systemName: "plus.bubble")
                            .font(.title3)
                    }
                }
            }
            .padding()

            Divider()

            // Comment input (when adding new top-level comment)
            if showingCommentInput {
                CommentInputView(
                    placeholder: "Add a comment...",
                    text: $newCommentText,
                    onSubmit: {
                        await createComment(content: newCommentText, parentId: nil)
                    },
                    onCancel: {
                        showingCommentInput = false
                        newCommentText = ""
                    }
                )
                .padding()

                Divider()
            }

            // Comments list
            Group {
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(message: errorMessage)
                } else if comments.isEmpty {
                    emptyView
                } else {
                    commentsListView
                }
            }
        }
        .task {
            await loadComments()
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading comments...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Try Again") {
                Task { await loadComments() }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No comments yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Be the first to comment!")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var commentsListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(parentComments) { comment in
                    CommentRowView(
                        comment: comment,
                        replies: getReplies(for: comment.id),
                        isReplyingTo: replyingToId == comment.id,
                        onReply: {
                            replyingToId = comment.id
                            showingCommentInput = false
                        },
                        onCancelReply: {
                            replyingToId = nil
                        },
                        onReplySubmit: { content in
                            await createComment(content: content, parentId: comment.id)
                        },
                        onDelete: {
                            await deleteComment(id: comment.id)
                        }
                    )
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Helpers

    private var parentComments: [Comment] {
        comments.filter { $0.parentCommentId == nil }
    }

    private func getReplies(for parentId: String) -> [Comment] {
        comments.filter { $0.parentCommentId == parentId }
    }

    // MARK: - Data Methods

    private func loadComments() async {
        isLoading = true
        errorMessage = nil

        do {
            switch target {
            case .mountain(let id):
                comments = try await CommentService.shared.fetchComments(
                    for: id,
                    limit: limit
                )
            case .webcam(let id):
                comments = try await CommentService.shared.fetchComments(
                    webcamId: id,
                    limit: limit
                )
            case .photo(let id):
                comments = try await CommentService.shared.fetchComments(
                    photoId: id,
                    limit: limit
                )
            case .checkIn(let id):
                comments = try await CommentService.shared.fetchComments(
                    checkInId: id,
                    limit: limit
                )
            }
        } catch {
            errorMessage = "Failed to load comments: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func createComment(content: String, parentId: String?) async {
        do {
            let newComment: Comment

            switch target {
            case .mountain(let id):
                newComment = try await CommentService.shared.createComment(
                    content: content,
                    mountainId: id,
                    parentCommentId: parentId
                )
            case .webcam(let id):
                newComment = try await CommentService.shared.createComment(
                    content: content,
                    webcamId: id,
                    parentCommentId: parentId
                )
            case .photo(let id):
                newComment = try await CommentService.shared.createComment(
                    content: content,
                    photoId: id,
                    parentCommentId: parentId
                )
            case .checkIn(let id):
                newComment = try await CommentService.shared.createComment(
                    content: content,
                    checkInId: id,
                    parentCommentId: parentId
                )
            }

            // Add to local state
            comments.insert(newComment, at: 0)

            // Reset state
            newCommentText = ""
            showingCommentInput = false
            replyingToId = nil
        } catch {
            errorMessage = "Failed to post comment: \(error.localizedDescription)"
        }
    }

    private func deleteComment(id: String) async {
        do {
            try await CommentService.shared.deleteComment(id: id)

            // Update local state
            if let index = comments.firstIndex(where: { $0.id == id }) {
                comments[index] = Comment(
                    id: comments[index].id,
                    userId: comments[index].userId,
                    mountainId: comments[index].mountainId,
                    webcamId: comments[index].webcamId,
                    photoId: comments[index].photoId,
                    checkInId: comments[index].checkInId,
                    parentCommentId: comments[index].parentCommentId,
                    content: "[deleted]",
                    createdAt: comments[index].createdAt,
                    updatedAt: Date(),
                    isDeleted: true,
                    isFlagged: comments[index].isFlagged,
                    likesCount: comments[index].likesCount,
                    user: comments[index].user
                )
            }
        } catch {
            errorMessage = "Failed to delete comment: \(error.localizedDescription)"
        }
    }
}

// MARK: - Comment Row View

struct CommentRowView: View {
    let comment: Comment
    let replies: [Comment]
    let isReplyingTo: Bool
    let onReply: () -> Void
    let onCancelReply: () -> Void
    let onReplySubmit: (String) async -> Void
    let onDelete: () async -> Void

    @Environment(AuthService.self) private var authService
    @State private var replyText = ""
    @State private var likeCount: Int

    init(
        comment: Comment,
        replies: [Comment],
        isReplyingTo: Bool,
        onReply: @escaping () -> Void,
        onCancelReply: @escaping () -> Void,
        onReplySubmit: @escaping (String) async -> Void,
        onDelete: @escaping () async -> Void
    ) {
        self.comment = comment
        self.replies = replies
        self.isReplyingTo = isReplyingTo
        self.onReply = onReply
        self.onCancelReply = onCancelReply
        self.onReplySubmit = onReplySubmit
        self.onDelete = onDelete
        self._likeCount = State(initialValue: comment.likesCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                // User avatar
                if let avatarUrl = comment.user?.avatarUrl, let url = URL(string: avatarUrl) {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image.resizable()
                        } else {
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }

                // Comment content
                VStack(alignment: .leading, spacing: 4) {
                    // User name and timestamp
                    HStack(spacing: 8) {
                        Text(comment.user?.displayName ?? comment.user?.username ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(formatDate(comment.createdAt))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if comment.updatedAt != comment.createdAt {
                            Text("(edited)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Comment text
                    Text(comment.content)
                        .font(.body)
                        .foregroundStyle(comment.isDeleted ? .secondary : .primary)
                        .italic(comment.isDeleted)

                    // Actions
                    if !comment.isDeleted {
                        HStack(spacing: 16) {
                            LikeButtonView(
                                target: .comment(comment.id),
                                likeCount: $likeCount,
                                size: 16
                            )

                            Button("Reply") {
                                onReply()
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if authService.currentUser?.id.uuidString == comment.userId {
                                Button("Delete") {
                                    Task { await onDelete() }
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }

            // Reply input
            if isReplyingTo {
                CommentInputView(
                    placeholder: "Reply to \(comment.user?.displayName ?? comment.user?.username ?? "user")...",
                    text: $replyText,
                    onSubmit: {
                        await onReplySubmit(replyText)
                        replyText = ""
                    },
                    onCancel: {
                        onCancelReply()
                        replyText = ""
                    }
                )
                .padding(.leading, 44)
            }

            // Replies
            if !replies.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(replies) { reply in
                        CommentRowView(
                            comment: reply,
                            replies: [],
                            isReplyingTo: false,
                            onReply: {},
                            onCancelReply: {},
                            onReplySubmit: { _ in },
                            onDelete: {}
                        )
                        .padding(.leading, 44)
                    }
                }
            }
        }
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 32)
            .overlay {
                Text((comment.user?.displayName ?? comment.user?.username ?? "?").prefix(1))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
    }

    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let diffInSeconds = Int(now.timeIntervalSince(date))

        if diffInSeconds < 60 { return "just now" }
        if diffInSeconds < 3600 { return "\(diffInSeconds / 60)m ago" }
        if diffInSeconds < 86400 { return "\(diffInSeconds / 3600)h ago" }
        if diffInSeconds < 604800 { return "\(diffInSeconds / 86400)d ago" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Comment Input View

struct CommentInputView: View {
    let placeholder: String
    @Binding var text: String
    let onSubmit: () async -> Void
    let onCancel: () -> Void

    @Environment(AuthService.self) private var authService
    @State private var isSubmitting = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...6)
                .focused($isFocused)
                .onAppear {
                    isFocused = true
                }

            HStack(spacing: 8) {
                Button {
                    Task {
                        isSubmitting = true
                        await onSubmit()
                        isSubmitting = false
                    }
                } label: {
                    Text(isSubmitting ? "Posting..." : "Post")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(.cornerRadiusButton)
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)

                Button("Cancel") {
                    onCancel()
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    CommentListView(target: .photo("preview-photo-id"))
        .environment(AuthService.shared)
}
