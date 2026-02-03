//
//  EventCacheService.swift
//  PowderTracker
//
//  Service for caching events locally for offline access.
//

import Foundation

/// Service for caching events locally for offline viewing
@MainActor
class EventCacheService {
    static let shared = EventCacheService()

    private let cacheDirectory: URL
    private let eventsFileName = "cached_events.json"
    private let eventDetailsPrefix = "event_detail_"
    private let cacheExpirySeconds: TimeInterval = 3600 // 1 hour

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
    func getCachedEvents() -> [Event]? {
        let fileURL = cacheDirectory.appendingPathComponent(eventsFileName)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(CachedEventsList.self, from: data)

            // Check if cache is expired
            if Date().timeIntervalSince(cacheEntry.cachedAt) > cacheExpirySeconds {
                #if DEBUG
                print("⚠️ Events cache expired")
                #endif
                return nil
            }

            #if DEBUG
            print("✅ Loaded \(cacheEntry.events.count) events from cache")
            #endif
            return cacheEntry.events
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached events: \(error)")
            #endif
            return nil
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
    func getCachedEventDetails(id: String) -> EventWithDetails? {
        let fileURL = cacheDirectory.appendingPathComponent("\(eventDetailsPrefix)\(id).json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheEntry = try decoder.decode(CachedEventDetails.self, from: data)

            // Check if cache is expired
            if Date().timeIntervalSince(cacheEntry.cachedAt) > cacheExpirySeconds {
                #if DEBUG
                print("⚠️ Event details cache expired for \(id)")
                #endif
                return nil
            }

            #if DEBUG
            print("✅ Loaded event details from cache for \(id)")
            #endif
            return cacheEntry.event
        } catch {
            #if DEBUG
            print("⚠️ Failed to load cached event details: \(error)")
            #endif
            return nil
        }
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
