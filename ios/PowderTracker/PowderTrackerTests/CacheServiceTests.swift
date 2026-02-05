import XCTest
@testable import PowderTracker

/// Tests for EventCacheService and RSVPCacheService
@MainActor
final class EventCacheServiceTests: XCTestCase {

    private var cacheService: EventCacheService!

    override func setUp() {
        super.setUp()
        cacheService = EventCacheService.shared
        cacheService.clearCache()
    }

    override func tearDown() {
        cacheService.clearCache()
        super.tearDown()
    }

    // MARK: - Events List Cache

    func testCacheEvents_StoresEvents() {
        let events = Event.mockList(count: 5)

        cacheService.cacheEvents(events)

        let cached = cacheService.getCachedEvents()
        XCTAssertNotNil(cached, "Should retrieve cached events")
        XCTAssertEqual(cached?.count, 5, "Should cache all events")
    }

    func testCacheEvents_EmptyList() {
        cacheService.cacheEvents([])

        let cached = cacheService.getCachedEvents()
        XCTAssertNotNil(cached, "Should cache even an empty list")
        XCTAssertEqual(cached?.count, 0)
    }

    func testGetCachedEvents_ReturnsNilWhenEmpty() {
        let cached = cacheService.getCachedEvents()
        XCTAssertNil(cached, "Should return nil when no events are cached")
    }

    func testGetCachedEvents_OverwritesPreviousCache() {
        let firstBatch = Event.mockList(count: 3)
        cacheService.cacheEvents(firstBatch)

        let secondBatch = Event.mockList(count: 7)
        cacheService.cacheEvents(secondBatch)

        let cached = cacheService.getCachedEvents()
        XCTAssertEqual(cached?.count, 7, "Should return latest cached events")
    }

    // MARK: - Cache Freshness

    func testShouldRefreshEvents_TrueWhenNoCache() {
        XCTAssertTrue(cacheService.shouldRefreshEvents(),
                     "Should refresh when no cache exists")
    }

    func testShouldRefreshEvents_FalseForFreshCache() {
        cacheService.cacheEvents(Event.mockList(count: 3))

        // Freshly cached events should not need refresh (stale threshold is 1 hour)
        XCTAssertFalse(cacheService.shouldRefreshEvents(),
                      "Should not need refresh for freshly cached data")
    }

    func testHasCachedEvents_TrueAfterCaching() {
        cacheService.cacheEvents(Event.mockList(count: 3))

        XCTAssertTrue(cacheService.hasCachedEvents())
    }

    func testHasCachedEvents_FalseWhenEmpty() {
        XCTAssertFalse(cacheService.hasCachedEvents())
    }

    // MARK: - Event Details Cache

    func testCacheEventDetails_StoresAndRetrieves() {
        let eventDetail = EventWithDetails.mock(id: "detail-test-1")

        cacheService.cacheEventDetails(eventDetail)

        let cached = cacheService.getCachedEventDetails(id: "detail-test-1")
        XCTAssertNotNil(cached, "Should retrieve cached event details")
        XCTAssertEqual(cached?.id, "detail-test-1")
    }

    func testGetCachedEventDetails_ReturnsNilForUnknownId() {
        let cached = cacheService.getCachedEventDetails(id: "unknown-id")
        XCTAssertNil(cached, "Should return nil for uncached event ID")
    }

    func testShouldRefreshEventDetails_TrueWhenNotCached() {
        XCTAssertTrue(cacheService.shouldRefreshEventDetails(id: "uncached-id"),
                     "Should refresh when event details not cached")
    }

    func testShouldRefreshEventDetails_FalseForFreshCache() {
        let detail = EventWithDetails.mock(id: "fresh-detail")
        cacheService.cacheEventDetails(detail)

        XCTAssertFalse(cacheService.shouldRefreshEventDetails(id: "fresh-detail"),
                      "Should not need refresh for freshly cached details")
    }

    // MARK: - Cache Invalidation

    func testInvalidateEvent_RemovesEventDetails() {
        let detail = EventWithDetails.mock(id: "invalidate-test")
        cacheService.cacheEventDetails(detail)

        cacheService.invalidateEvent(id: "invalidate-test")

        let cached = cacheService.getCachedEventDetails(id: "invalidate-test")
        XCTAssertNil(cached, "Should remove event details after invalidation")
    }

    func testInvalidateEvent_AlsoInvalidatesEventsList() {
        cacheService.cacheEvents(Event.mockList(count: 3))

        cacheService.invalidateEvent(id: "any-event")

        let cachedList = cacheService.getCachedEvents()
        XCTAssertNil(cachedList, "Invalidating an event should also clear the events list cache")
    }

    func testInvalidateAll_ClearsAllCaches() {
        cacheService.cacheEvents(Event.mockList(count: 3))
        cacheService.cacheEventDetails(EventWithDetails.mock(id: "d1"))
        cacheService.cacheEventDetails(EventWithDetails.mock(id: "d2"))

        cacheService.invalidateAll()

        XCTAssertNil(cacheService.getCachedEvents())
        XCTAssertNil(cacheService.getCachedEventDetails(id: "d1"))
        XCTAssertNil(cacheService.getCachedEventDetails(id: "d2"))
    }

    // MARK: - Cache Management

    func testClearCache_RemovesEverything() {
        cacheService.cacheEvents(Event.mockList(count: 3))
        cacheService.cacheEventDetails(EventWithDetails.mock(id: "clear-test"))

        cacheService.clearCache()

        XCTAssertNil(cacheService.getCachedEvents())
        XCTAssertNil(cacheService.getCachedEventDetails(id: "clear-test"))
    }

    func testGetCacheSize_ZeroWhenEmpty() {
        cacheService.clearCache()

        let size = cacheService.getCacheSize()
        XCTAssertEqual(size, 0, "Cache size should be 0 when empty")
    }

    func testGetCacheSize_IncreasesAfterCaching() {
        cacheService.clearCache()
        let emptySize = cacheService.getCacheSize()

        cacheService.cacheEvents(Event.mockList(count: 10))

        let sizeAfter = cacheService.getCacheSize()
        XCTAssertGreaterThan(sizeAfter, emptySize,
                            "Cache size should increase after caching events")
    }
}

// MARK: - RSVPCacheService Tests

@MainActor
final class RSVPCacheServiceTests: XCTestCase {

    private var rsvpCache: RSVPCacheService!

    override func setUp() {
        super.setUp()
        rsvpCache = RSVPCacheService.shared
        rsvpCache.clearCache()
    }

    override func tearDown() {
        rsvpCache.clearCache()
        super.tearDown()
    }

    // MARK: - Cache RSVP

    func testCacheRSVP_StoresStatus() {
        rsvpCache.cacheRSVP(eventId: "event-1", status: "going")

        let cached = rsvpCache.getRSVP(eventId: "event-1")
        XCTAssertNotNil(cached)
        XCTAssertEqual(cached?.status, "going")
        XCTAssertEqual(cached?.eventId, "event-1")
    }

    func testCacheRSVP_WithDriverAndRideInfo() {
        rsvpCache.cacheRSVP(eventId: "event-2", status: "going",
                           isDriver: true, needsRide: false)

        let cached = rsvpCache.getRSVP(eventId: "event-2")
        XCTAssertNotNil(cached)
        XCTAssertTrue(cached?.isDriver ?? false)
        XCTAssertFalse(cached?.needsRide ?? true)
    }

    func testCacheRSVP_OverwritesPrevious() {
        rsvpCache.cacheRSVP(eventId: "event-3", status: "maybe")
        rsvpCache.cacheRSVP(eventId: "event-3", status: "going")

        let cached = rsvpCache.getRSVP(eventId: "event-3")
        XCTAssertEqual(cached?.status, "going",
                      "Should return latest RSVP status")
    }

    // MARK: - Get RSVP Status

    func testGetRSVPStatus_ReturnsStatusString() {
        rsvpCache.cacheRSVP(eventId: "event-4", status: "maybe")

        let status = rsvpCache.getRSVPStatus(eventId: "event-4")
        XCTAssertEqual(status, "maybe")
    }

    func testGetRSVPStatus_ReturnsNilForUnknown() {
        let status = rsvpCache.getRSVPStatus(eventId: "unknown-event")
        XCTAssertNil(status)
    }

    // MARK: - HasRSVP

    func testHasRSVP_TrueForGoing() {
        rsvpCache.cacheRSVP(eventId: "event-5", status: "going")

        XCTAssertTrue(rsvpCache.hasRSVP(eventId: "event-5"))
    }

    func testHasRSVP_TrueForMaybe() {
        rsvpCache.cacheRSVP(eventId: "event-6", status: "maybe")

        XCTAssertTrue(rsvpCache.hasRSVP(eventId: "event-6"))
    }

    func testHasRSVP_FalseForDeclined() {
        rsvpCache.cacheRSVP(eventId: "event-7", status: "declined")

        XCTAssertFalse(rsvpCache.hasRSVP(eventId: "event-7"),
                      "Declined should not count as having RSVP'd")
    }

    func testHasRSVP_FalseForUnknown() {
        XCTAssertFalse(rsvpCache.hasRSVP(eventId: "unknown"))
    }

    // MARK: - Remove RSVP

    func testRemoveRSVP_ClearsFromCache() {
        rsvpCache.cacheRSVP(eventId: "event-8", status: "going")

        rsvpCache.removeRSVP(eventId: "event-8")

        XCTAssertNil(rsvpCache.getRSVP(eventId: "event-8"),
                    "Should remove RSVP from cache")
        XCTAssertFalse(rsvpCache.hasRSVP(eventId: "event-8"))
    }

    func testRemoveRSVP_NonexistentDoesNothing() {
        // Should not crash when removing nonexistent
        rsvpCache.removeRSVP(eventId: "nonexistent")
        XCTAssertNil(rsvpCache.getRSVP(eventId: "nonexistent"))
    }

    // MARK: - Invalidate RSVP

    func testInvalidateRSVP_SameAsRemove() {
        rsvpCache.cacheRSVP(eventId: "event-9", status: "going")

        rsvpCache.invalidateRSVP(eventId: "event-9")

        XCTAssertNil(rsvpCache.getRSVP(eventId: "event-9"))
    }

    // MARK: - Attending Event IDs

    func testGetAttendingEventIds_ReturnsGoingAndMaybe() {
        rsvpCache.cacheRSVP(eventId: "going-event", status: "going")
        rsvpCache.cacheRSVP(eventId: "maybe-event", status: "maybe")
        rsvpCache.cacheRSVP(eventId: "declined-event", status: "declined")

        let attending = rsvpCache.getAttendingEventIds()

        XCTAssertTrue(attending.contains("going-event"))
        XCTAssertTrue(attending.contains("maybe-event"))
        XCTAssertFalse(attending.contains("declined-event"),
                      "Declined events should not be in attending list")
    }

    func testGetAttendingEventIds_EmptyWhenNoRSVPs() {
        let attending = rsvpCache.getAttendingEventIds()
        XCTAssertTrue(attending.isEmpty)
    }

    // MARK: - Cache Stats

    func testGetCacheStats_ReturnsCorrectCount() {
        XCTAssertEqual(rsvpCache.getCacheStats(), 0)

        rsvpCache.cacheRSVP(eventId: "e1", status: "going")
        rsvpCache.cacheRSVP(eventId: "e2", status: "maybe")

        XCTAssertEqual(rsvpCache.getCacheStats(), 2)
    }

    // MARK: - Clear Cache

    func testClearCache_RemovesAllEntries() {
        rsvpCache.cacheRSVP(eventId: "e1", status: "going")
        rsvpCache.cacheRSVP(eventId: "e2", status: "maybe")
        rsvpCache.cacheRSVP(eventId: "e3", status: "declined")

        rsvpCache.clearCache()

        XCTAssertEqual(rsvpCache.getCacheStats(), 0)
        XCTAssertTrue(rsvpCache.getAttendingEventIds().isEmpty)
        XCTAssertNil(rsvpCache.getRSVP(eventId: "e1"))
    }

    // MARK: - Batch Operations

    func testCacheRSVPsFromEvents_CachesEventStatuses() {
        let events = [
            Event.mockWithRSVP(.going, id: "batch-1"),
            Event.mockWithRSVP(.maybe, id: "batch-2"),
            Event.mock(id: "batch-3", userRSVPStatus: nil) // No RSVP
        ]

        rsvpCache.cacheRSVPsFromEvents(events)

        XCTAssertEqual(rsvpCache.getRSVPStatus(eventId: "batch-1"), "going")
        XCTAssertEqual(rsvpCache.getRSVPStatus(eventId: "batch-2"), "maybe")
        XCTAssertNil(rsvpCache.getRSVPStatus(eventId: "batch-3"),
                    "Should not cache events without RSVP status")
    }
}
