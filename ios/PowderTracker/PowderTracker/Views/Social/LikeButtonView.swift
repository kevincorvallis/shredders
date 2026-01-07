import SwiftUI

struct LikeButtonView: View {
    enum TargetType {
        case photo(String)
        case comment(String)
        case checkIn(String)
        case webcam(String)
    }

    let target: TargetType
    @Binding var likeCount: Int
    let size: CGFloat

    @Environment(AuthService.self) private var authService
    @State private var isLiked = false
    @State private var isLoading = false

    init(target: TargetType, likeCount: Binding<Int>, size: CGFloat = 20) {
        self.target = target
        self._likeCount = likeCount
        self.size = size
    }

    var body: some View {
        Button(action: handleToggleLike) {
            HStack(spacing: 4) {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: size))
                    .foregroundStyle(isLiked ? .red : .secondary)

                Text("\(likeCount)")
                    .font(.system(size: size - 4))
                    .foregroundStyle(.secondary)
            }
        }
        .disabled(isLoading || !authService.isAuthenticated)
        .opacity(isLoading ? 0.5 : 1.0)
        .task {
            await checkLikeStatus()
        }
    }

    private func checkLikeStatus() async {
        guard authService.isAuthenticated else { return }

        do {
            switch target {
            case .photo(let id):
                isLiked = try await LikeService.shared.isLiked(photoId: id)
            case .comment(let id):
                isLiked = try await LikeService.shared.isLiked(commentId: id)
            case .checkIn(let id):
                isLiked = try await LikeService.shared.isLiked(checkInId: id)
            case .webcam(let id):
                isLiked = try await LikeService.shared.isLiked(webcamId: id)
            }
        } catch {
            print("Error checking like status: \(error)")
        }
    }

    private func handleToggleLike() {
        guard authService.isAuthenticated else {
            // Could show a sign-in prompt here
            return
        }

        Task {
            isLoading = true

            do {
                let newLiked: Bool

                switch target {
                case .photo(let id):
                    newLiked = try await LikeService.shared.toggleLike(photoId: id)
                case .comment(let id):
                    newLiked = try await LikeService.shared.toggleLike(commentId: id)
                case .checkIn(let id):
                    newLiked = try await LikeService.shared.toggleLike(checkInId: id)
                case .webcam(let id):
                    newLiked = try await LikeService.shared.toggleLike(webcamId: id)
                }

                // Update local state
                withAnimation(.easeInOut(duration: 0.2)) {
                    isLiked = newLiked
                    likeCount = newLiked ? likeCount + 1 : likeCount - 1
                }
            } catch {
                print("Error toggling like: \(error)")
            }

            isLoading = false
        }
    }
}

#Preview {
    @Previewable @State var likeCount = 42

    VStack(spacing: 20) {
        LikeButtonView(
            target: .photo("preview-photo-id"),
            likeCount: $likeCount,
            size: 16
        )

        LikeButtonView(
            target: .comment("preview-comment-id"),
            likeCount: $likeCount,
            size: 20
        )

        LikeButtonView(
            target: .checkIn("preview-checkin-id"),
            likeCount: $likeCount,
            size: 24
        )
    }
    .padding()
    .environment(AuthService.shared)
}
