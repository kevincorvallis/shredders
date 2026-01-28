import Foundation
import Combine

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    private let maxFavorites = 5
    private let storageKey = "favoriteMountainIds"

    // Default favorites for first-time users
    static let defaultFavorites = ["baker", "crystal", "stevens"]

    @Published var favoriteIds: [String] = []

    init() {
        loadFavorites()
        migrateFromLegacySelection()
    }

    // MARK: - Public API

    func isFavorite(_ mountainId: String) -> Bool {
        favoriteIds.contains(mountainId)
    }

    func toggleFavorite(_ mountainId: String) -> Bool {
        if isFavorite(mountainId) {
            remove(mountainId)
            HapticFeedback.light.trigger()
            return false
        } else {
            let added = add(mountainId)
            if added {
                HapticFeedback.success.trigger()
            } else {
                HapticFeedback.warning.trigger()
            }
            return added
        }
    }

    func add(_ mountainId: String) -> Bool {
        guard !isFavorite(mountainId) else { return true }
        guard favoriteIds.count < maxFavorites else { return false }

        favoriteIds.append(mountainId)
        saveFavorites()
        return true
    }

    func remove(_ mountainId: String) {
        favoriteIds.removeAll { $0 == mountainId }
        saveFavorites()
    }

    func reorder(from source: IndexSet, to destination: Int) {
        var ids = favoriteIds
        ids.move(fromOffsets: source, toOffset: destination)
        favoriteIds = ids
        saveFavorites()
    }

    func canAddMore() -> Bool {
        favoriteIds.count < maxFavorites
    }

    func remainingSlots() -> Int {
        maxFavorites - favoriteIds.count
    }

    // MARK: - Persistence

    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            favoriteIds = Array(decoded.prefix(maxFavorites)) // Ensure max 5
        }
    }

    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    // MARK: - Migration

    private func migrateFromLegacySelection() {
        // Only migrate if no favorites exist
        guard favoriteIds.isEmpty else { return }

        // Check for legacy selectedMountainId
        if let legacyId = UserDefaults.standard.string(forKey: "selectedMountainId"),
           !legacyId.isEmpty {
            _ = add(legacyId)

            // Add remaining defaults (exclude legacy ID if already added)
            for defaultId in Self.defaultFavorites where defaultId != legacyId && favoriteIds.count < 3 {
                _ = add(defaultId)
            }
        } else {
            // No legacy selection - use all defaults
            Self.defaultFavorites.forEach { _ = add($0) }
        }
    }
}
