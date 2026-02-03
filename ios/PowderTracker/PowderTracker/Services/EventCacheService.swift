//
//  EventCacheService.swift
//  PowderTracker
//
//  Service for caching events locally for offline access.
//

import Foundation

/// Service for caching events locally for offline viewing
/// OPTIMIZATION: Extended cache TTL to 24 hours with stale-while-revalidate pattern
@MainActor
class EventCacheService {
    static let shared = EventCacheService()

    private let cacheDirectory: URL
    private let eventsFileName = "cached_events.json"
    private let eventDetailsPrefix = "event_detail_"

    // OPTIMIZATION: Extended cache expiry from 1 hour to 24 hours for better offline access
    private let cacheExpirySeconds: TimeInterval = 86400 // 24 hours

    // Stale-while-revalidate: Return stale data immediately but trigger background refresh
    // after this threshold
    private let staleThresholdSeconds: TimeInterval = 3600 // 1 hour - data is "fresh" for 1 hour

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        // Use caches directory for temporary storage
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDir.appendingPathComponent("EventCache", isDirectory: true)

        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Events List Cache

    /// Cache a list of events
    func cacheEvents(_ events: [Event]) {
        let cacheEntry = CachedEventsList(
            events: events,
            cachedAt: Date()
        )

        do {
            let data = try encoder.encode(cacheEntry)
            let fileURL = cacheDirectory.appendingPathComponent(eventsFileName)
            try data.write(to: fileURL)
            #if DEBUG
            print("✅ Cached \(events.count) events")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to cache events: \(error)")
            #endif
        }
    }

    /// Get cached events list
    /// - Parameter allowStale: If true, returns stale (but not expired) data
    func getCachedEvents(allowStale: Bool = true) -> [Event]? {
        let fileURL = cacheDirectory.appendingPathComponent(eventsFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(CachedEventsList.self, from: data)
            let age = Date().timeIntervalSince(cacheEntry.cachedAt)

            // Check if cache is expired (beyond 24 hours)
            if age > cacheExpirySeconds {
                #if DEBUG
                print("⚠️ Events cache expired (age: \(Int(age/3600))h)")
                #endif
                return nil
            }

            #if DEBUG
            let freshOrStale = age > staleThresholdSeconds ? "stale" : "fresh"
            print("✅ Loaded \(cacheEntry.events.count) events from cache (\(freshOrStale), age: \(Int(age/60))min)")
            #endif
            return cacheEntry.events
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached events: \(error)")
            #endif
            return nil
        }
    }

    /// Check if cached events need background refresh (stale but not expired)
    func shouldRefreshEvents() -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent(eventsFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return true // No cache, definitely refresh
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(CachedEventsList.self, from: data)
            let age = Date().timeIntervalSince(cacheEntry.cachedAt)

            // Refresh if data is stale (older than 1 hour)
            return age > staleThresholdSeconds
        } catch {
            return true
        }
    }

    /// Check if we have valid cached events
    func hasCachedEvents() -> Bool {
        return getCachedEvents() != nil
    }

    // MARK: - Event Details Cache

    /// Cache event details
    func cacheEventDetails(_ event: EventWithDetails) {
        let cacheEntry = CachedEventDetails(
            event: event,
            cachedAt: Date()
        )

        do {
            let data = try encoder.encode(cacheEntry)
            let fileURL = cacheDirectory.appendingPathComponent("\(eventDetailsPrefix)\(event.id).json")
            try data.write(to: fileURL)
            #if DEBUG
            print("✅ Cached event details for \(event.id)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to cache event details: \(error)")
            #endif
        }
    }

    /// Get cached event details
    /// - Parameter allowStale: If true, returns stale (but not expired) data
    func getCachedEventDetails(id: String, allowStale: Bool = true) -> EventWithDetails? {
        let fileURL = cacheDirectory.appendingPathComponent("\(eventDetailsPrefix)\(id).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(CachedEventDetails.self, from: data)
            let age = Date().timeIntervalSince(cacheEntry.cachedAt)

            // Check if cache is expired (beyond 24 hours)
            if age > cacheExpirySeconds {
                #if DEBUG
                print("⚠️ Event details cache expired for \(id) (age: \(Int(age/3600))h)")
                #endif
                return nil
            }

            #if DEBUG
            let freshOrStale = age > staleThresholdSeconds ? "stale" : "fresh"
            print("✅ Loaded event details from cache for \(id) (\(freshOrStale))")
            #endif
            return cacheEntry.event
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached event details: \(error)")
            #endif
            return nil
        }
    }

    /// Check if cached event details need background refresh
    func shouldRefreshEventDetails(id: String) -> Bool {
        let fileURL = cacheDirectory.appendingPathComponent("\(eventDetailsPrefix)\(id).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return true
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(CachedEventDetails.self, from: data)
            let age = Date().timeIntervalSince(cacheEntry.cachedAt)

            return age > staleThresholdSeconds
        } catch {
            return true
        }
    }

    /// Invalidate cache for a specific event (call after mutations)
    func invalidateEvent(id: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(eventDetailsPrefix)\(id).json")
        try? FileManager.default.removeItem(at: fileURL)

        // Also invalidate the events list since counts may have changed
        let listURL = cacheDirectory.appendingPathComponent(eventsFileName)
        try? FileManager.default.removeItem(at: listURL)

        #if DEBUG
        print("🗑️ Invalidated cache for event \(id)")
        #endif
    }

    /// Invalidate all event caches (call after creating/deleting events)
    func invalidateAll() {
        clearCache()
    }

    // MARK: - Cache Management

    /// Clear all cached events
    func clearCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
            #if DEBUG
            print("✅ Event cache cleared")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to clear event cache: \(error)")
            #endif
        }
    }

    /// Remove expired cache entries
    func pruneExpiredCache() {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])

            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let modDate = attributes[.modificationDate] as? Date,
                   Date().timeIntervalSince(modDate) > cacheExpirySeconds {
                    try FileManager.default.removeItem(at: file)
                    #if DEBUG
                    print("🗑️ Removed expired cache: \(file.lastPathComponent)")
                    #endif
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to prune cache: \(error)")
            #endif
        }
    }

    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0
        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? Int64 {
                    totalSize += size
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ Failed to calculate cache size: \(error)")
            #endif
        }
        return totalSize
    }
}

// MARK: - Cache Models

private struct CachedEventsList: Codable {
    let events: [Event]
    let cachedAt: Date
}

private struct CachedEventDetails: Codable {
    let event: EventWithDetails
    let cachedAt: Date
}
