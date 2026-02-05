import Foundation
import Combine

@MainActor
class FavoritesService: ObservableObject {
    static let shared = FavoritesService()

    private let maxFavorites = 5
    private let storageKey = "favoriteMountainIds"
    private var isSyncing = false
    private var syncTask: Task<Void, Never>?

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
        debouncedSync()
        return true
    }

    func remove(_ mountainId: String) {
        favoriteIds.removeAll { $0 == mountainId }
        saveFavorites()
        debouncedSync()
    }

    /// Debounce backend sync to batch rapid toggling into a single request
    private func debouncedSync() {
        syncTask?.cancel()
        syncTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s debounce
            guard !Task.isCancelled else { return }
            await syncToBackend()
        }
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

    // MARK: - Backend Sync

    /// Sync favorites to backend (call after local changes)
    func syncToBackend() async {
        guard !isSyncing else { return }
        guard AuthService.shared.isAuthenticated else { return }

        isSyncing = true
        defer { isSyncing = false }

        guard let url = URL(string: "\(AppConfig.apiBaseURL)/auth/user/preferences") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth header - try JWT token first, then Supabase session
        if let token = KeychainHelper.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let session = try? await SupabaseClientManager.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            return
        }

        let body = ["favoriteMountainIds": favoriteIds]
        request.httpBody = try? JSONEncoder().encode(body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                #if DEBUG
                print("✅ Favorites synced to backend")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to sync favorites: \(error)")
            #endif
        }
    }

    /// Fetch favorites from backend (call on app launch)
    func fetchFromBackend() async {
        guard AuthService.shared.isAuthenticated else { return }

        guard let url = URL(string: "\(AppConfig.apiBaseURL)/auth/user/preferences") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Add auth header - try JWT token first, then Supabase session
        if let token = KeychainHelper.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let session = try? await SupabaseClientManager.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                struct PreferencesResponse: Codable {
                    let favoriteMountainIds: [String]
                    let unitsPreference: String
                }
                let prefs = try JSONDecoder().decode(PreferencesResponse.self, from: data)

                // Update local storage if backend has data
                if !prefs.favoriteMountainIds.isEmpty {
                    favoriteIds = prefs.favoriteMountainIds
                    saveFavorites()
                    #if DEBUG
                    print("✅ Favorites loaded from backend: \(favoriteIds)")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to fetch favorites: \(error)")
            #endif
        }
    }
}
