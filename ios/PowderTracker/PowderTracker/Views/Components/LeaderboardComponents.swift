import SwiftUI

// MARK: - Leaderboard Models

/// Represents a user's entry in the leaderboard
struct LeaderboardEntry: Identifiable, Equatable {
    let id: String
    let userId: String
    let username: String
    let avatarUrl: String?
    let rank: Int
    let previousRank: Int?
    let score: Int
    let mountainsVisited: Int
    let powderDaysTracked: Int
    let isFriend: Bool
    let isCurrentUser: Bool

    var rankChange: RankChange {
        guard let previous = previousRank else { return .new }
        if rank < previous { return .up(previous - rank) }
        if rank > previous { return .down(rank - previous) }
        return .same
    }

    enum RankChange: Equatable {
        case up(Int)
        case down(Int)
        case same
        case new
    }
}

/// Personal best stats for the user
struct PersonalBestStats: Equatable {
    let highestRank: Int
    let bestScore: Int
    let mostMountainsInSeason: Int
    let longestStreak: Int
    let totalPowderDays: Int
}

// MARK: - Leaderboard View

/// Main leaderboard view with friend/global toggle
struct LeaderboardView: View {
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedScope: LeaderboardScope = .global
    @State private var entries: [LeaderboardEntry] = []
    @State private var personalBest: PersonalBestStats?
    @State private var isLoading = false
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingL) {
                // Scope toggle
                scopeToggle

                // Personal best highlights
                if let stats = personalBest {
                    PersonalBestCard(stats: stats)
                }

                // Leaderboard list
                if isLoading {
                    leaderboardSkeleton
                } else {
                    leaderboardList
                }
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Leaderboard")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    generateShareableCard()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheetView(image: image)
            }
        }
        .onAppear {
            loadSampleData()
        }
    }

    // MARK: - Components

    private var scopeToggle: some View {
        HStack(spacing: 0) {
            ForEach(LeaderboardScope.allCases, id: \.self) { scope in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedScope = scope
                        HapticFeedback.selection.trigger()
                    }
                } label: {
                    Text(scope.title)
                        .font(.subheadline)
                        .fontWeight(selectedScope == scope ? .semibold : .regular)
                        .foregroundColor(selectedScope == scope ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, .spacingM)
                        .background {
                            if selectedScope == scope {
                                Capsule()
                                    .fill(Color.blue.gradient)
                            }
                        }
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private var leaderboardList: some View {
        LazyVStack(spacing: .spacingM) {
            ForEach(filteredEntries) { entry in
                LeaderboardRowView(entry: entry)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            }
        }
    }

    private var filteredEntries: [LeaderboardEntry] {
        switch selectedScope {
        case .global:
            return entries
        case .friends:
            return entries.filter { $0.isFriend || $0.isCurrentUser }
        }
    }

    private var leaderboardSkeleton: some View {
        VStack(spacing: .spacingM) {
            ForEach(0..<5, id: \.self) { _ in
                RoundedRectangle(cornerRadius: .cornerRadiusCard)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 80)
                    .shimmering()
            }
        }
    }

    // MARK: - Data Loading

    private func loadSampleData() {
        // Sample data for demonstration
        entries = [
            LeaderboardEntry(id: "1", userId: "u1", username: "PowderHunter42", avatarUrl: nil, rank: 1, previousRank: 1, score: 12500, mountainsVisited: 15, powderDaysTracked: 45, isFriend: false, isCurrentUser: false),
            LeaderboardEntry(id: "2", userId: "u2", username: "SkiBum_Sarah", avatarUrl: nil, rank: 2, previousRank: 4, score: 11200, mountainsVisited: 12, powderDaysTracked: 38, isFriend: true, isCurrentUser: false),
            LeaderboardEntry(id: "3", userId: "u3", username: "You", avatarUrl: nil, rank: 3, previousRank: 5, score: 10800, mountainsVisited: 10, powderDaysTracked: 32, isFriend: false, isCurrentUser: true),
            LeaderboardEntry(id: "4", userId: "u4", username: "FreshyFinder", avatarUrl: nil, rank: 4, previousRank: 2, score: 9500, mountainsVisited: 8, powderDaysTracked: 28, isFriend: true, isCurrentUser: false),
            LeaderboardEntry(id: "5", userId: "u5", username: "CrystalChaser", avatarUrl: nil, rank: 5, previousRank: 3, score: 8900, mountainsVisited: 7, powderDaysTracked: 25, isFriend: false, isCurrentUser: false),
        ]

        personalBest = PersonalBestStats(
            highestRank: 2,
            bestScore: 11500,
            mostMountainsInSeason: 12,
            longestStreak: 7,
            totalPowderDays: 45
        )
    }

    private func generateShareableCard() {
        let renderer = ImageRenderer(content: ShareableStatsCard(
            username: "You",
            rank: 3,
            score: 10800,
            powderDays: 32,
            mountainsVisited: 10
        ))
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            shareImage = image
            showShareSheet = true
        }
    }
}

// MARK: - Leaderboard Row

/// Individual row in the leaderboard showing rank, user, and score
struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    @State private var animateRankChange = false

    var body: some View {
        HStack(spacing: .spacingM) {
            // Rank with change indicator
            rankView

            // Avatar
            avatarView

            // User info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(entry.username)
                        .font(.headline)
                        .foregroundColor(entry.isCurrentUser ? .blue : .primary)

                    if entry.isCurrentUser {
                        Text("YOU")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue))
                    }

                    if entry.isFriend && !entry.isCurrentUser {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: .spacingM) {
                    Label("\(entry.mountainsVisited)", systemImage: "mountain.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label("\(entry.powderDaysTracked)", systemImage: "snowflake")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(entry.score)")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(entry.isCurrentUser ? .blue : .primary)

                Text("pts")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(entry.isCurrentUser ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadiusCard)
                        .stroke(entry.isCurrentUser ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2)) {
                animateRankChange = true
            }
        }
    }

    private var rankView: some View {
        ZStack {
            // Rank number
            Text("\(entry.rank)")
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(rankColor)
                .frame(width: 44)

            // Rank change indicator
            if animateRankChange {
                rankChangeIndicator
                    .offset(x: 16, y: -16)
            }
        }
    }

    @ViewBuilder
    private var rankChangeIndicator: some View {
        switch entry.rankChange {
        case .up(let change):
            HStack(spacing: 2) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                Text("\(change)")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.green))
            .transition(.scale.combined(with: .opacity))

        case .down(let change):
            HStack(spacing: 2) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                Text("\(change)")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.red))
            .transition(.scale.combined(with: .opacity))

        case .same:
            EmptyView()

        case .new:
            Text("NEW")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.orange))
                .transition(.scale.combined(with: .opacity))
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(avatarGradient)
                .frame(width: 44, height: 44)

            Text(String(entry.username.prefix(1)).uppercased())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .overlay(
            Circle()
                .stroke(entry.rank <= 3 ? rankColor : Color.clear, lineWidth: 2)
        )
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75) // Silver
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2) // Bronze
        default: return .primary
        }
    }

    private var avatarGradient: LinearGradient {
        switch entry.rank {
        case 1: return LinearGradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.3), Color(red: 1.0, green: 0.7, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 2: return LinearGradient(colors: [Color(red: 0.85, green: 0.85, blue: 0.9), Color(red: 0.6, green: 0.6, blue: 0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case 3: return LinearGradient(colors: [Color(red: 0.9, green: 0.6, blue: 0.3), Color(red: 0.7, green: 0.4, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: return LinearGradient(colors: [.blue.opacity(0.8), .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Personal Best Card

/// Card showing the user's personal best statistics
struct PersonalBestCard: View {
    let stats: PersonalBestStats
    @State private var animateStats = false

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                    .symbolEffect(.pulse, value: animateStats)

                Text("Personal Bests")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: .spacingM) {
                StatBubble(
                    value: "#\(stats.highestRank)",
                    label: "Best Rank",
                    icon: "star.fill",
                    color: .yellow,
                    animate: animateStats
                )

                StatBubble(
                    value: "\(stats.bestScore)",
                    label: "High Score",
                    icon: "bolt.fill",
                    color: .orange,
                    animate: animateStats
                )

                StatBubble(
                    value: "\(stats.longestStreak)",
                    label: "Day Streak",
                    icon: "flame.fill",
                    color: .red,
                    animate: animateStats
                )
            }

            // Bottom stats
            HStack(spacing: .spacingL) {
                HStack(spacing: 6) {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.blue)
                    Text("\(stats.mostMountainsInSeason) mountains this season")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "snowflake")
                        .foregroundColor(.cyan)
                    Text("\(stats.totalPowderDays) total powder days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.spacingL)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadiusHero)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateStats = true
            }
        }
    }
}

/// Individual stat bubble in the personal best card
struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let animate: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0.0)

            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Shareable Stats Card

/// A card optimized for sharing to social media
struct ShareableStatsCard: View {
    let username: String
    let rank: Int
    let score: Int
    let powderDays: Int
    let mountainsVisited: Int

    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "snowflake.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.white.gradient)

                Text("PowderTracker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()
            }

            Divider()
                .background(Color.white.opacity(0.3))

            // User stats
            VStack(spacing: 12) {
                Text(username)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                HStack(spacing: 24) {
                    VStack {
                        Text("#\(rank)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("Rank")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    VStack {
                        Text("\(score)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Points")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }

            // Stats row
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "snowflake")
                        .foregroundColor(.cyan)
                    Text("\(powderDays) Powder Days")
                        .foregroundColor(.white)
                }

                HStack(spacing: 6) {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.blue)
                    Text("\(mountainsVisited) Mountains")
                        .foregroundColor(.white)
                }
            }
            .font(.subheadline)

            Spacer()

            // Footer
            Text("Season 2024-25")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(24)
        .frame(width: 350, height: 400)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.5),
                    Color(red: 0.2, green: 0.3, blue: 0.7),
                    Color(red: 0.1, green: 0.4, blue: 0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }
}

// MARK: - Share Sheet

struct ShareSheetView: UIViewControllerRepresentable {
    let image: UIImage

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Supporting Types

enum LeaderboardScope: String, CaseIterable {
    case global
    case friends

    var title: String {
        switch self {
        case .global: return "Global"
        case .friends: return "Friends"
        }
    }
}

// MARK: - Previews

#Preview("Leaderboard View") {
    NavigationStack {
        LeaderboardView()
    }
}

#Preview("Leaderboard Row - First Place") {
    LeaderboardRowView(entry: LeaderboardEntry(
        id: "1",
        userId: "u1",
        username: "PowderHunter42",
        avatarUrl: nil,
        rank: 1,
        previousRank: 2,
        score: 12500,
        mountainsVisited: 15,
        powderDaysTracked: 45,
        isFriend: false,
        isCurrentUser: false
    ))
    .padding()
}

#Preview("Personal Best Card") {
    PersonalBestCard(stats: PersonalBestStats(
        highestRank: 2,
        bestScore: 11500,
        mostMountainsInSeason: 12,
        longestStreak: 7,
        totalPowderDays: 45
    ))
    .padding()
}

#Preview("Shareable Stats Card") {
    ShareableStatsCard(
        username: "PowderHunter42",
        rank: 3,
        score: 10800,
        powderDays: 32,
        mountainsVisited: 10
    )
}
