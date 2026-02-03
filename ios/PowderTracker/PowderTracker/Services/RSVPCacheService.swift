//
//  RSVPCacheService.swift
//  PowderTracker
//
//  Service for caching the user's RSVP statuses locally.
//  Provides instant UI feedback without network requests for known events.
//

import Foundation

/// Cached RSVP status for an event
struct CachedRSVP: Codable {
    let eventId: String
    let status: String // going, maybe, declined, waitlist
    let isDriver: Bool
    let needsRide: Bool
    let cachedAt: Date
}

/// Service for caching user's RSVP statuses
/// OPTIMIZATION: Provides instant RSVP status without network requests
@MainActor
class RSVPCacheService {
    static let shared = RSVPCacheService()

    private let cacheDirectory: URL
    private let cacheFileName = "user_rsvps.json"

    // In-memory cache for fast access
    private var rsvpCache: [String: CachedRSVP] = [:]

    // Cache expiry - RSVPs should stay valid until explicitly invalidated
    private let cacheExpiry: TimeInterval = 604800 // 7 days

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDir.appendingPathComponent("RSVPCache", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()

        loadCacheIntoMemory()
    }

    // MARK: - RSVP Caching

    /// Cache an RSVP status after a successful RSVP operation
    func cacheRSVP(eventId: String, status: String, isDriver: Bool = false, needsRide: Bool = false) {
        let rsvp = CachedRSVP(
            eventId: eventId,
            status: status,
            isDriver: isDriver,
            needsRide: needsRide,
            cachedAt: Date()
        )
        rsvpCache[eventId] = rsvp
        persistCache()

        #if DEBUG
        print("✅ Cached RSVP for event \(eventId): \(status)")
        #endif
    }

    /// Cache RSVP from an RSVPResponse
    func cacheRSVPFromResponse(_ response: RSVPResponse) {
        cacheRSVP(
            eventId: response.event.id,
            status: response.attendee.status.rawValue,
            isDriver: response.attendee.isDriver,
            needsRide: response.attendee.needsRide
        )
    }

    /// Get cached RSVP status for an event
    func getRSVP(eventId: String) -> CachedRSVP? {
        guard let cached = rsvpCache[eventId] else { return nil }

        // Check expiry
        if Date().timeIntervalSince(cached.cachedAt) > cacheExpiry {
            rsvpCache.removeValue(forKey: eventId)
            return nil
        }

        return cached
    }

    /// Get RSVP status string for an event (convenience method)
    func getRSVPStatus(eventId: String) -> String? {
        return getRSVP(eventId: eventId)?.status
    }

    /// Check if user has RSVP'd to an event (going or maybe)
    func hasRSVP(eventId: String) -> Bool {
        guard let status = getRSVPStatus(eventId: eventId) else { return false }
        return status == "going" || status == "maybe"
    }

    /// Remove RSVP from cache (call after removing RSVP)
    func removeRSVP(eventId: String) {
        rsvpCache.removeValue(forKey: eventId)
        persistCache()

        #if DEBUG
        print("🗑️ Removed cached RSVP for event \(eventId)")
        #endif
    }

    /// Invalidate RSVP cache for an event (force refetch)
    func invalidateRSVP(eventId: String) {
        removeRSVP(eventId: eventId)
    }

    // MARK: - Batch Operations

    /// Cache multiple RSVPs from event list (user's attending events)
    func cacheRSVPsFromEvents(_ events: [Event]) {
        for event in events {
            if let status = event.userRSVPStatus {
                cacheRSVP(eventId: event.id, status: status.rawValue)
            }
        }
    }

    /// Get all cached event IDs where user is attending
    func getAttendingEventIds() -> [String] {
        return rsvpCache.compactMap { (eventId, rsvp) -> String? in
            if rsvp.status == "going" || rsvp.status == "maybe" {
                return eventId
            }
            return nil
        }
    }

    // MARK: - Cache Management

    /// Clear all cached RSVPs (call on sign out)
    func clearCache() {
        rsvpCache.removeAll()
        let fileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        try? FileManager.default.removeItem(at: fileURL)

        #if DEBUG
        print("🗑️ Cleared all RSVP cache")
        #endif
    }

    /// Get cache statistics
    func getCacheStats() -> Int {
        return rsvpCache.count
    }

    // MARK: - Private Helpers

    private func loadCacheIntoMemory() {
        let fileURL = cacheDirectory.appendingPathComponent(cacheFileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            rsvpCache = try decoder.decode([String: CachedRSVP].self, from: data)

            // Prune expired entries
            let now = Date()
            rsvpCache = rsvpCache.filter { _, rsvp in
                now.timeIntervalSince(rsvp.cachedAt) <= cacheExpiry
            }

            #if DEBUG
            print("✅ Loaded \(rsvpCache.count) RSVPs from cache")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to load RSVP cache: \(error)")
            #endif
        }
    }

    private func persistCache() {
        do {
            let data = try encoder.encode(rsvpCache)
            let fileURL = cacheDirectory.appendingPathComponent(cacheFileName)
            try data.write(to: fileURL)
        } catch {
            #if DEBUG
            print("⚠️ Failed to persist RSVP cache: \(error)")
            #endif
        }
    }
}

// MARK: - Integration with EventService

extension RSVPCacheService {
    /// Update cache after RSVP operation in EventService
    /// Call this from EventService.rsvp() after successful response
    func handleRSVPResponse(_ response: RSVPResponse) {
        cacheRSVPFromResponse(response)

        // Also invalidate event cache since counts changed
        EventCacheService.shared.invalidateEvent(id: response.event.id)
    }

    /// Update cache after removing RSVP
    /// Call this from EventService.removeRSVP() after success
    func handleRSVPRemoved(eventId: String) {
        removeRSVP(eventId: eventId)
        EventCacheService.shared.invalidateEvent(id: eventId)
    }
}
