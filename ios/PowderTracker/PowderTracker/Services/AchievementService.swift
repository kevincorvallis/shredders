import SwiftUI
import Combine

/// Manages user achievements with local storage and CloudKit sync
@MainActor
@Observable
final class AchievementService: @unchecked Sendable {
    static let shared = AchievementService()

    private(set) var achievements: [Achievement]
    private(set) var recentlyUnlocked: Achievement?

    private let userDefaultsKey = "user_achievements"

    private init() {
        self.achievements = Self.loadAchievements()
        self.recentlyUnlocked = nil
    }

    // MARK: - Public Methods

    /// Update progress for a specific achievement
    func updateProgress(achievementId: String, progress: Int) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }

        let wasUnlocked = achievements[index].isUnlocked
        achievements[index].currentProgress = min(progress, achievements[index].requiredProgress)

        // Check if just unlocked
        if !wasUnlocked && achievements[index].isUnlocked {
            achievements[index].unlockedDate = Date()
            recentlyUnlocked = achievements[index]
            HapticFeedback.success.trigger()
        }

        save()
    }

    /// Increment progress for a specific achievement
    func incrementProgress(achievementId: String, by amount: Int = 1) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementId }) else { return }
        updateProgress(achievementId: achievementId, progress: achievements[index].currentProgress + amount)
    }

    /// Clear the recently unlocked achievement after displaying
    func clearRecentlyUnlocked() {
        recentlyUnlocked = nil
    }

    /// Get achievements by category
    func achievements(for category: AchievementCategory) -> [Achievement] {
        achievements.filter { $0.category == category }
    }

    /// Get unlocked achievements
    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    /// Get achievements in progress (started but not complete)
    var inProgressAchievements: [Achievement] {
        achievements.filter { !$0.isUnlocked && $0.currentProgress > 0 }
    }

    /// Total achievement points (each achievement worth 10 points)
    var totalPoints: Int {
        unlockedAchievements.count * 10
    }

    /// Overall completion percentage
    var completionPercentage: Double {
        guard !achievements.isEmpty else { return 0 }
        return Double(unlockedAchievements.count) / Double(achievements.count)
    }

    // MARK: - Achievement Triggers

    /// Called when user views a mountain
    func trackMountainView(mountainId: String) {
        // First mountain achievement
        incrementProgress(achievementId: "first_mountain")

        // Track unique mountains viewed
        var viewedMountains = getViewedMountains()
        if !viewedMountains.contains(mountainId) {
            viewedMountains.insert(mountainId)
            saveViewedMountains(viewedMountains)

            // Update explorer achievements
            updateProgress(achievementId: "explorer_5", progress: viewedMountains.count)
            updateProgress(achievementId: "explorer_10", progress: viewedMountains.count)
        }
    }

    /// Called when conditions are checked
    func trackConditionsCheck(snowfall24h: Int) {
        // Early bird check
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 7 {
            incrementProgress(achievementId: "early_check")
            incrementProgress(achievementId: "early_5")
        }

        // Powder day achievements
        if snowfall24h >= 6 {
            incrementProgress(achievementId: "powder_day")
            incrementProgress(achievementId: "powder_5")
        }

        if snowfall24h >= 12 {
            incrementProgress(achievementId: "deep_powder")
        }

        // Track daily streak
        trackDailyUsage()
    }

    /// Called when user shares conditions
    func trackShare() {
        incrementProgress(achievementId: "first_share")
    }

    /// Called when user adds a favorite
    func trackFavoriteAdded() {
        incrementProgress(achievementId: "favorite_mountain")
    }

    // MARK: - Private Methods

    private func trackDailyUsage() {
        let today = Calendar.current.startOfDay(for: Date())
        var usageDays = getUsageDays()

        if !usageDays.contains(today) {
            usageDays.append(today)
            saveUsageDays(usageDays)

            // Update season achievement
            updateProgress(achievementId: "season_30", progress: usageDays.count)

            // Check streak
            let streak = calculateCurrentStreak(from: usageDays)
            updateProgress(achievementId: "streak_3", progress: streak)
            updateProgress(achievementId: "streak_7", progress: streak)
        }
    }

    private func calculateCurrentStreak(from days: [Date]) -> Int {
        let sorted = days.sorted(by: >)
        guard !sorted.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 1
        var previousDay = sorted[0]

        for day in sorted.dropFirst() {
            if let diff = calendar.dateComponents([.day], from: day, to: previousDay).day,
               diff == 1 {
                streak += 1
                previousDay = day
            } else {
                break
            }
        }

        return streak
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    private static func loadAchievements() -> [Achievement] {
        guard let data = UserDefaults.standard.data(forKey: "user_achievements"),
              let saved = try? JSONDecoder().decode([Achievement].self, from: data) else {
            return Achievement.allAchievements
        }

        // Merge with any new achievements
        var merged = saved
        for achievement in Achievement.allAchievements {
            if !merged.contains(where: { $0.id == achievement.id }) {
                merged.append(achievement)
            }
        }

        return merged
    }

    // MARK: - Helper Storage

    private func getViewedMountains() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: "viewed_mountains"),
              let mountains = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return []
        }
        return mountains
    }

    private func saveViewedMountains(_ mountains: Set<String>) {
        if let data = try? JSONEncoder().encode(mountains) {
            UserDefaults.standard.set(data, forKey: "viewed_mountains")
        }
    }

    private func getUsageDays() -> [Date] {
        guard let data = UserDefaults.standard.data(forKey: "usage_days"),
              let days = try? JSONDecoder().decode([Date].self, from: data) else {
            return []
        }
        return days
    }

    private func saveUsageDays(_ days: [Date]) {
        if let data = try? JSONEncoder().encode(days) {
            UserDefaults.standard.set(data, forKey: "usage_days")
        }
    }
}
