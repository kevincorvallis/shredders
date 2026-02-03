//
//  UserProfileCacheService.swift
//  PowderTracker
//
//  Service for caching user profile data to avoid repeated fetches.
//  Caches both the current user's profile and other users' profiles
//  encountered in attendee lists, comments, etc.
//

import Foundation

/// Lightweight user profile data for caching
struct CachedUserProfile: Codable, Identifiable {
    let id: String
    let username: String?
    let displayName: String?
    let avatarUrl: String?

    var displayLabel: String {
        displayName ?? username ?? "User"
    }
}

/// Service for caching user profiles locally
/// OPTIMIZATION: Avoids repeated fetches of the same user data
@MainActor
class UserProfileCacheService {
    static let shared = UserProfileCacheService()

    private let cacheDirectory: URL
    private let currentUserFileName = "current_user_profile.json"
    private let otherUsersFileName = "user_profiles_cache.json"

    // In-memory cache for fast access
    private var currentUserCache: CachedUserProfile?
    private var otherUsersCache: [String: CachedUserProfile] = [:]

    // Cache expiry
    private let currentUserCacheExpiry: TimeInterval = 86400 // 24 hours
    private let otherUsersCacheExpiry: TimeInterval = 604800 // 7 days (other users' data rarely changes)

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDir.appendingPathComponent("UserProfileCache", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        // Load caches into memory on init
        loadCachesIntoMemory()
    }

    // MARK: - Current User Profile

    /// Cache the current user's profile
    func cacheCurrentUser(_ profile: CachedUserProfile) {
        currentUserCache = profile

        let cacheEntry = TimestampedCache(data: profile, cachedAt: Date())
        do {
            let data = try encoder.encode(cacheEntry)
            let fileURL = cacheDirectory.appendingPathComponent(currentUserFileName)
            try data.write(to: fileURL)
            #if DEBUG
            print("✅ Cached current user profile: \(profile.displayLabel)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to cache current user profile: \(error)")
            #endif
        }
    }

    /// Get cached current user profile
    func getCurrentUser() -> CachedUserProfile? {
        // Fast path: return from memory
        if let cached = currentUserCache {
            return cached
        }

        // Try loading from disk
        let fileURL = cacheDirectory.appendingPathComponent(currentUserFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(TimestampedCache<CachedUserProfile>.self, from: data)

            if Date().timeIntervalSince(cacheEntry.cachedAt) > currentUserCacheExpiry {
                return nil // Expired
            }

            currentUserCache = cacheEntry.data
            return cacheEntry.data
        } catch {
            return nil
        }
    }

    /// Clear current user cache (call on sign out)
    func clearCurrentUser() {
        currentUserCache = nil
        let fileURL = cacheDirectory.appendingPathComponent(currentUserFileName)
        try? FileManager.default.removeItem(at: fileURL)
        #if DEBUG
        print("🗑️ Cleared current user cache")
        #endif
    }

    // MARK: - Other Users' Profiles

    /// Cache a user profile (from attendee lists, comments, etc.)
    func cacheUser(_ profile: CachedUserProfile) {
        otherUsersCache[profile.id] = profile
        persistOtherUsersCache()
    }

    /// Cache multiple user profiles at once (batch operation)
    func cacheUsers(_ profiles: [CachedUserProfile]) {
        for profile in profiles {
            otherUsersCache[profile.id] = profile
        }
        persistOtherUsersCache()
        #if DEBUG
        print("✅ Cached \(profiles.count) user profiles")
        #endif
    }

    /// Get a cached user profile by ID
    func getUser(id: String) -> CachedUserProfile? {
        return otherUsersCache[id]
    }

    /// Get multiple cached user profiles
    func getUsers(ids: [String]) -> [String: CachedUserProfile] {
        var result: [String: CachedUserProfile] = [:]
        for id in ids {
            if let profile = otherUsersCache[id] {
                result[id] = profile
            }
        }
        return result
    }

    /// Check which user IDs are not in cache (need to be fetched)
    func getMissingUserIds(from ids: [String]) -> [String] {
        return ids.filter { otherUsersCache[$0] == nil }
    }

    // MARK: - Cache Management

    /// Clear all cached data (call on sign out)
    func clearAllCaches() {
        clearCurrentUser()
        otherUsersCache.removeAll()
        let fileURL = cacheDirectory.appendingPathComponent(otherUsersFileName)
        try? FileManager.default.removeItem(at: fileURL)
        #if DEBUG
        print("🗑️ Cleared all user profile caches")
        #endif
    }

    /// Get cache statistics
    func getCacheStats() -> (currentUser: Bool, otherUsersCount: Int) {
        return (currentUser: currentUserCache != nil, otherUsersCount: otherUsersCache.count)
    }

    // MARK: - Private Helpers

    private func loadCachesIntoMemory() {
        // Load current user
        _ = getCurrentUser()

        // Load other users
        let fileURL = cacheDirectory.appendingPathComponent(otherUsersFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(TimestampedCache<[String: CachedUserProfile]>.self, from: data)

            if Date().timeIntervalSince(cacheEntry.cachedAt) <= otherUsersCacheExpiry {
                otherUsersCache = cacheEntry.data
                #if DEBUG
                print("✅ Loaded \(otherUsersCache.count) user profiles from cache")
                #endif
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to load user profiles cache: \(error)")
            #endif
        }
    }

    private func persistOtherUsersCache() {
        let cacheEntry = TimestampedCache(data: otherUsersCache, cachedAt: Date())
        do {
            let data = try encoder.encode(cacheEntry)
            let fileURL = cacheDirectory.appendingPathComponent(otherUsersFileName)
            try data.write(to: fileURL)
        } catch {
            #if DEBUG
            print("⚠️ Failed to persist user profiles cache: \(error)")
            #endif
        }
    }
}

// MARK: - Helper Types

private struct TimestampedCache<T: Codable>: Codable {
    let data: T
    let cachedAt: Date
}

// MARK: - Convenience Extensions

extension UserProfileCacheService {
    /// Extract user profiles from event attendees and cache them
    func cacheAttendeesFromEvent(_ attendees: [EventAttendee]) {
        let profiles = attendees.map { attendee in
            CachedUserProfile(
                id: attendee.user.id,
                username: attendee.user.username,
                displayName: attendee.user.displayName,
                avatarUrl: attendee.user.avatarUrl
            )
        }
        cacheUsers(profiles)
    }

    /// Extract user profile from event creator and cache it
    func cacheCreatorFromEvent(_ event: Event) {
        let profile = CachedUserProfile(
            id: event.creator.id,
            username: event.creator.username,
            displayName: event.creator.displayName,
            avatarUrl: event.creator.avatarUrl
        )
        cacheUser(profile)
    }

    /// Extract user profile from event with details creator and cache it
    func cacheCreatorFromEvent(_ event: EventWithDetails) {
        let profile = CachedUserProfile(
            id: event.creator.id,
            username: event.creator.username,
            displayName: event.creator.displayName,
            avatarUrl: event.creator.avatarUrl
        )
        cacheUser(profile)
    }

    /// Extract user profiles from comments and cache them
    func cacheUsersFromComments(_ comments: [EventComment]) {
        let profiles = comments.map { comment in
            CachedUserProfile(
                id: comment.user.id,
                username: comment.user.username,
                displayName: comment.user.displayName,
                avatarUrl: comment.user.avatarUrl
            )
        }
        cacheUsers(profiles)
    }
}
