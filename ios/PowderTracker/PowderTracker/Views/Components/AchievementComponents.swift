import SwiftUI

// MARK: - Achievement Model

/// Types of achievements available
enum AchievementCategory: String, CaseIterable, Codable {
    case explorer = "Explorer"      // Visit new mountains
    case powderHound = "Powder Hound" // Track powder days
    case earlyBird = "Early Bird"    // Check conditions early
    case socialite = "Socialite"     // Share and engage
    case dedication = "Dedication"    // Streak and consistency

    var icon: String {
        switch self {
        case .explorer: return "map.fill"
        case .powderHound: return "snowflake"
        case .earlyBird: return "sunrise.fill"
        case .socialite: return "person.3.fill"
        case .dedication: return "flame.fill"
        }
    }

    var color: Color {
        switch self {
        case .explorer: return .blue
        case .powderHound: return .cyan
        case .earlyBird: return .orange
        case .socialite: return .purple
        case .dedication: return .red
        }
    }
}

/// Represents a single achievement
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    let category: AchievementCategory
    let icon: String
    let requiredProgress: Int
    var currentProgress: Int
    var unlockedDate: Date?

    var isUnlocked: Bool { currentProgress >= requiredProgress }
    var progressPercentage: Double {
        guard requiredProgress > 0 else { return 0 }
        return min(Double(currentProgress) / Double(requiredProgress), 1.0)
    }
}

// MARK: - Predefined Achievements

extension Achievement {
    static let allAchievements: [Achievement] = [
        // Explorer
        Achievement(id: "first_mountain", name: "First Tracks", description: "View your first mountain", category: .explorer, icon: "mountain.2.fill", requiredProgress: 1, currentProgress: 0),
        Achievement(id: "explorer_5", name: "Trailblazer", description: "View 5 different mountains", category: .explorer, icon: "map.fill", requiredProgress: 5, currentProgress: 0),
        Achievement(id: "explorer_10", name: "Mountain Maven", description: "View 10 different mountains", category: .explorer, icon: "globe.americas.fill", requiredProgress: 10, currentProgress: 0),

        // Powder Hound
        Achievement(id: "powder_day", name: "Powder Day!", description: "Check conditions on a powder day", category: .powderHound, icon: "snowflake", requiredProgress: 1, currentProgress: 0),
        Achievement(id: "powder_5", name: "Powder Seeker", description: "Find 5 powder days", category: .powderHound, icon: "cloud.snow.fill", requiredProgress: 5, currentProgress: 0),
        Achievement(id: "deep_powder", name: "Deep Days", description: "Check a day with 12\"+ fresh snow", category: .powderHound, icon: "snowflake.circle.fill", requiredProgress: 1, currentProgress: 0),

        // Early Bird
        Achievement(id: "early_check", name: "Early Bird", description: "Check conditions before 7 AM", category: .earlyBird, icon: "sunrise.fill", requiredProgress: 1, currentProgress: 0),
        Achievement(id: "early_5", name: "Dawn Patrol", description: "Check conditions before 7 AM 5 times", category: .earlyBird, icon: "alarm.fill", requiredProgress: 5, currentProgress: 0),

        // Socialite
        Achievement(id: "first_share", name: "Spread the Stoke", description: "Share conditions with a friend", category: .socialite, icon: "square.and.arrow.up.fill", requiredProgress: 1, currentProgress: 0),
        Achievement(id: "favorite_mountain", name: "Home Mountain", description: "Add a mountain to favorites", category: .socialite, icon: "star.fill", requiredProgress: 1, currentProgress: 0),

        // Dedication
        Achievement(id: "streak_3", name: "Committed", description: "Check conditions 3 days in a row", category: .dedication, icon: "flame.fill", requiredProgress: 3, currentProgress: 0),
        Achievement(id: "streak_7", name: "Dedicated Shredder", description: "Check conditions 7 days in a row", category: .dedication, icon: "flame.circle.fill", requiredProgress: 7, currentProgress: 0),
        Achievement(id: "season_30", name: "Season Pass", description: "Use the app for 30 days this season", category: .dedication, icon: "calendar.badge.checkmark", requiredProgress: 30, currentProgress: 0)
    ]
}

// MARK: - Achievement Badge View

/// A badge component for displaying achievements
struct AchievementBadge: View {
    let achievement: Achievement
    var size: CGFloat = 60

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(achievement.isUnlocked
                    ? achievement.category.color.gradient
                    : Color.gray.opacity(0.3).gradient
                )
                .frame(width: size, height: size)

            // Icon
            Image(systemName: achievement.icon)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(achievement.isUnlocked ? .white : .gray)

            // Lock overlay for locked achievements
            if !achievement.isUnlocked {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: size, height: size)

                Image(systemName: "lock.fill")
                    .font(.system(size: size * 0.25))
                    .foregroundColor(.secondary)
            }

            // Progress ring for partial progress
            if !achievement.isUnlocked && achievement.currentProgress > 0 {
                Circle()
                    .trim(from: 0, to: achievement.progressPercentage)
                    .stroke(
                        achievement.category.color,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: size + 6, height: size + 6)
                    .rotationEffect(.degrees(-90))
            }
        }
        .shadow(color: achievement.isUnlocked
            ? achievement.category.color.opacity(0.4)
            : .clear,
            radius: 8)
    }
}

// MARK: - Achievement Card View

/// Full card view for an achievement with details
struct AchievementCard: View {
    let achievement: Achievement
    var showProgress: Bool = true

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: .spacingM) {
            AchievementBadge(achievement: achievement, size: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? .primary : .secondary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if showProgress && !achievement.isUnlocked {
                    HStack(spacing: 8) {
                        ProgressView(value: achievement.progressPercentage)
                            .tint(achievement.category.color)

                        Text("\(achievement.currentProgress)/\(achievement.requiredProgress)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .monospacedDigit()
                    }
                }

                if achievement.isUnlocked, let date = achievement.unlockedDate {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(achievement.category.color)
                }
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(achievement.category.color)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
        .adaptiveShadow(colorScheme: colorScheme, radius: 6, y: 3)
    }
}

// MARK: - Achievement Unlock Animation

/// Confetti particle for unlock animation
struct ConfettiParticle: View {
    let color: Color
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(rotation))
            .position(position)
            .opacity(opacity)
    }

    func animate(startPosition: CGPoint, delay: Double) {
        position = startPosition

        let endX = startPosition.x + CGFloat.random(in: -100...100)
        let endY = startPosition.y + CGFloat.random(in: 50...200)

        withAnimation(.easeOut(duration: 1.5).delay(delay)) {
            position = CGPoint(x: endX, y: endY)
            rotation = Double.random(in: -720...720)
            opacity = 0
        }
    }
}

/// Achievement unlock overlay with animation
struct AchievementUnlockView: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var showBadge = false
    @State private var showText = false
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: .spacingXL) {
                // Badge with scale animation
                AchievementBadge(achievement: achievement, size: 120)
                    .scaleEffect(showBadge ? 1 : 0.3)
                    .opacity(showBadge ? 1 : 0)

                // Achievement text
                VStack(spacing: .spacingS) {
                    Text("Achievement Unlocked!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(achievement.name)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(achievement.category.color)

                    Text(achievement.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 20)

                // Dismiss button
                Button {
                    onDismiss()
                } label: {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, .spacingXL)
                        .padding(.vertical, .spacingM)
                        .background(achievement.category.color)
                        .clipShape(Capsule())
                }
                .opacity(showText ? 1 : 0)
            }
            .padding(.spacingXXL)

            // Confetti overlay
            if showConfetti {
                ConfettiView(color: achievement.category.color)
            }
        }
        .onAppear {
            HapticFeedback.success.trigger()

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                showBadge = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showText = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
            }
        }
    }
}

/// Simple confetti effect
struct ConfettiView: View {
    let color: Color

    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, rotation: Double)] = []

    var body: some View {
        GeometryReader { geo in
            ForEach(particles, id: \.id) { particle in
                RoundedRectangle(cornerRadius: 2)
                    .fill([color, .yellow, .orange, .pink, .cyan].randomElement()!)
                    .frame(width: 8, height: 8)
                    .position(x: particle.x, y: particle.y)
                    .rotationEffect(.degrees(particle.rotation))
            }
        }
        .onAppear {
            createConfetti()
        }
    }

    private func createConfetti() {
        for i in 0..<50 {
            let startX = CGFloat.random(in: 100...300)
            let startY: CGFloat = 200

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                withAnimation(.easeOut(duration: 1.5)) {
                    particles.append((
                        id: i,
                        x: startX + CGFloat.random(in: -150...150),
                        y: startY + CGFloat.random(in: 100...400),
                        rotation: Double.random(in: 0...720)
                    ))
                }
            }
        }
    }
}

// MARK: - Achievement Progress Indicator

/// Shows progress toward an achievement
struct AchievementProgressIndicator: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: achievement.progressPercentage)
                    .stroke(
                        achievement.category.color,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(), value: achievement.progressPercentage)

                Text("\(Int(achievement.progressPercentage * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            .frame(width: 40, height: 40)

            Text(achievement.name)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Preview

#Preview("Achievement Badge") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            AchievementBadge(achievement: Achievement.allAchievements[0])
            AchievementBadge(achievement: {
                var a = Achievement.allAchievements[0]
                a.currentProgress = 1
                a.unlockedDate = Date()
                return a
            }())
        }
    }
    .padding()
}

#Preview("Achievement Card") {
    VStack(spacing: 16) {
        AchievementCard(achievement: Achievement.allAchievements[0])
        AchievementCard(achievement: {
            var a = Achievement.allAchievements[0]
            a.currentProgress = 1
            a.unlockedDate = Date()
            return a
        }())
    }
    .padding()
}
