import Foundation
import Combine

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()

    private let maxFavorites = 5
    private let storageKey = "favoriteMountainIds"

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
            return false
        } else {
            return add(mountainId)
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
        }
    }
}
