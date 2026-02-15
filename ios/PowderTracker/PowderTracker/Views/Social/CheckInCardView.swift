import SwiftUI
import NukeUI

struct CheckInCardView: View {
    let checkIn: CheckIn
    let onDeleted: (() -> Void)?

    @Environment(AuthService.self) private var authService
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var likeCount: Int

    init(checkIn: CheckIn, onDeleted: (() -> Void)? = nil) {
        self.checkIn = checkIn
        self.onDeleted = onDeleted
        self._likeCount = State(initialValue: checkIn.likesCount)
    }

    private var isOwner: Bool {
        authService.currentUser?.id.uuidString == checkIn.userId
    }

    private var displayName: String {
        checkIn.user?.displayName ?? checkIn.user?.username ?? "Unknown"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top) {
                // User avatar
                if let avatarUrl = checkIn.user?.avatarUrl, let url = URL(string: avatarUrl) {
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image.resizable()
                        } else {
                            avatarPlaceholder
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                } else {
                    avatarPlaceholder
                }

                // User info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(displayName)
                            .font(.headline)

                        if !checkIn.isPublic {
                            Text("Private")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .foregroundStyle(.secondary)
                                .cornerRadius(.cornerRadiusTiny)
                        }
                    }

                    Text("Checked in \(formatDate(checkIn.checkInTime))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Rating badge
                if let rating = checkIn.rating {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)

                        Text("\(rating)/5")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(.cornerRadiusButton)
                }
            }

            // Conditions
            if checkIn.snowQuality != nil || checkIn.crowdLevel != nil {
                HStack(spacing: 8) {
                    if let snowQuality = checkIn.snowQuality {
                        conditionBadge(
                            icon: "snow",
                            text: formatCondition(snowQuality)
                        )
                    }

                    if let crowdLevel = checkIn.crowdLevel {
                        conditionBadge(
                            icon: "person.2",
                            text: formatCondition(crowdLevel)
                        )
                    }
                }
            }

            // Trip report with sentiment indicator
            if let tripReport = checkIn.tripReport, !tripReport.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tripReport)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if let sentiment = SentimentAnalyzer.shared.analyzeCheckIn(checkIn) {
                        HStack(spacing: 4) {
                            Image(systemName: sentiment.label.icon)
                                .font(.caption2)
                            Text(sentiment.label.displayName)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Actions
            HStack {
                LikeButtonView(
                    target: .checkIn(checkIn.id),
                    likeCount: $likeCount,
                    size: 16
                )

                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                    Text("\(checkIn.commentsCount)")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                if isOwner {
                    Menu {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .confirmationDialog(
            "Delete Check-In",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await deleteCheckIn()
                }
            }
        } message: {
            Text("Are you sure you want to delete this check-in? This action cannot be undone.")
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
            .frame(width: 48, height: 48)
            .overlay {
                Text(displayName.prefix(1))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
    }

    private func conditionBadge(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)

            Text(text)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray6))
        .foregroundStyle(.secondary)
        .cornerRadius(.cornerRadiusCard)
    }

    private func formatCondition(_ condition: String) -> String {
        condition
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }

    private func formatDate(_ date: Date) -> String {
        let now = Date()
        let diffInSeconds = Int(now.timeIntervalSince(date))

        if diffInSeconds < 3600 { return "\(diffInSeconds / 60)m ago" }
        if diffInSeconds < 86400 { return "\(diffInSeconds / 3600)h ago" }
        if diffInSeconds < 604800 { return "\(diffInSeconds / 86400)d ago" }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func deleteCheckIn() async {
        isDeleting = true

        do {
            try await CheckInService.shared.deleteCheckIn(id: checkIn.id)
            onDeleted?()
        } catch {
            #if DEBUG
            print("Failed to delete check-in: \(error)")
            #endif
        }

        isDeleting = false
    }
}

#Preview {
    CheckInCardView(
        checkIn: CheckIn(
            id: "1",
            userId: "user-1",
            mountainId: "baker",
            checkInTime: Date().addingTimeInterval(-3600),
            checkOutTime: nil,
            tripReport: "Amazing powder day! Got 12 runs in before lunch. Conditions were perfect.",
            rating: 5,
            snowQuality: "powder",
            crowdLevel: "moderate",
            weatherConditions: nil,
            likesCount: 12,
            commentsCount: 3,
            isPublic: true,
            user: CheckInUser(
                id: "user-1",
                username: "skier123",
                displayName: "John Doe",
                avatarUrl: nil
            )
        ),
        onDeleted: nil
    )
    .padding()
    .environment(AuthService.shared)
}
