import SwiftUI

struct PhotoCardView: View {
    let photo: Photo
    let onDeleted: (() async -> Void)?

    @Environment(AuthService.self) private var authService
    @State private var showingMenu = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false

    init(photo: Photo, onDeleted: (() async -> Void)? = nil) {
        self.photo = photo
        self.onDeleted = onDeleted
    }

    private var isOwner: Bool {
        authService.currentUser?.id.uuidString == photo.userId
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Photo image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: photo.cloudfrontUrl)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay {
                                ProgressView()
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.secondary)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 120)
                .clipped()

                // Menu button for owner
                if isOwner {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(.black.opacity(0.5))
                            )
                    }
                    .padding(4)
                }
            }

            // Photo info
            VStack(alignment: .leading, spacing: 4) {
                // User info
                HStack(spacing: 6) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                        .overlay {
                            Text(String((photo.user?.displayName ?? photo.user?.username ?? "?").prefix(1)))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }

                    Text(photo.user?.displayName ?? photo.user?.username ?? "Unknown")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .lineLimit(1)
                }

                // Caption
                if let caption = photo.caption {
                    Text(caption)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                // Stats
                HStack(spacing: 8) {
                    Label("\(photo.likesCount)", systemImage: "heart")
                    Label("\(photo.commentsCount)", systemImage: "bubble.right")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            .padding(8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await deletePhoto()
                }
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }

    private func deletePhoto() async {
        isDeleting = true

        do {
            try await PhotoService.shared.deletePhoto(photo.id)
            await onDeleted?()
        } catch {
            #if DEBUG
            print("Failed to delete photo: \(error)")
            #endif
        }

        isDeleting = false
    }
}
