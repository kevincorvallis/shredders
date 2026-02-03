# Backend & API Performance Optimization Checklist

**Scope:** All phases (complete implementation)
**Last Updated:** 2026-02-03

## Overview
Comprehensive performance optimization checklist for PowderTracker backend APIs and iOS network layer. Addresses latency issues, redundant queries, and caching gaps.

**Analysis Summary:**
- 12 performance categories identified
- Primary targets: Sequential queries, missing caching, N+1 problems, redundant lookups
- Estimated impact: 30-50% reduction in API response times

---

## Phase 1: Quick Wins (High ROI, Low Effort) ✅ COMPLETED

### 1.1 Add HTTP Cache Headers ✅
**Files Modified:**
- `src/app/api/events/route.ts` - Events list (60s cache, 120s stale-while-revalidate)
- `src/app/api/events/[id]/route.ts` - Event detail (5 min cache, 10 min stale-while-revalidate)
- `src/app/api/mountains/[mountainId]/route.ts` - Mountain data (1 hour cache)

**Implementation:**
```typescript
// Events list - frequently changing data
return NextResponse.json(response, {
  headers: {
    'Cache-Control': 'public, max-age=60, stale-while-revalidate=120',
  },
});

// Event detail - moderately stable
return NextResponse.json(response, {
  headers: {
    'Cache-Control': 'public, max-age=300, stale-while-revalidate=600',
  },
});

// Mountains - relatively static
return NextResponse.json(mountain, {
  headers: {
    'Cache-Control': 'public, max-age=3600, stale-while-revalidate=7200',
  },
});
```

### 1.2 Fix Duplicate RSVP Query ✅
**File:** `src/app/api/events/[id]/rsvp/route.ts`

**Problem:** Same RSVP record fetched twice in same request (capacity check + main logic).

**Solution:** Moved RSVP fetch before capacity check and reused throughout:
```typescript
// Fetch once at the start
const { data: existingRSVP } = await supabase
  .from('event_attendees')
  .select('id, status')
  .eq('event_id', eventId)
  .eq('user_id', userProfile.id)
  .single();

// Reuse for capacity check
if (!existingRSVP || existingRSVP.status !== 'going') {
  effectiveStatus = 'waitlist';
  // ...
}
```

### 1.3 Combine Sequential Auth Checks ✅
**Files:**
- `src/app/api/events/[id]/comments/route.ts`
- `src/app/api/events/[id]/photos/route.ts`

**Problem:** Two sequential queries for creator + RSVP check.

**Solution:** Combined into single parallel helper:
```typescript
async function checkUserEventAccess(
  supabase: any,
  eventId: string,
  userProfileId: string
): Promise<{ isCreator: boolean; hasRSVP: boolean }> {
  const [eventResult, rsvpResult] = await Promise.all([
    supabase.from('events').select('user_id').eq('id', eventId).single(),
    supabase.from('event_attendees').select('status')
      .eq('event_id', eventId)
      .eq('user_id', userProfileId)
      .in('status', ['going', 'maybe'])
      .maybeSingle(),
  ]);
  return {
    isCreator: eventResult.data?.user_id === userProfileId,
    hasRSVP: !!rsvpResult.data,
  };
}
```

### 1.4 iOS Auth Token Memory Caching ✅
**File:** `ios/PowderTracker/PowderTracker/Services/EventService.swift`

**Problem:** `addAuthHeader()` queries Keychain on every request.

**Solution:** Added static token cache with 5-minute expiry:
```swift
private static var cachedToken: String?
private static var tokenExpiry: Date?
private static let tokenCacheDuration: TimeInterval = 300

private func addAuthHeader(to request: inout URLRequest) async throws {
    // Check memory cache first
    if let token = Self.cachedToken,
       let expiry = Self.tokenExpiry,
       expiry > Date() {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return
    }
    // ... fetch from Keychain and cache
}

static func clearCachedToken() {
    cachedToken = nil
    tokenExpiry = nil
}
```

---

## Phase 2: Query Optimization (Medium Effort) ✅ COMPLETED

### 2.1 Fix In-Memory Filtering for attendingOnly ✅
**File:** `src/app/api/events/route.ts`

**Problem:** Fetched all user's events then filtered in JavaScript.

**Solution:** Push filters to Supabase query using `!inner` join:
```typescript
let attendeeQuery = supabase
  .from('event_attendees')
  .select(`
    status,
    event:event_id!inner (
      id, user_id, mountain_id, title, notes, ...
    )
  `, { count: 'exact' })
  .eq('user_id', userProfileId)
  .in('status', ['going', 'maybe']);

// Database-side filters
attendeeQuery = attendeeQuery.eq('event.status', status);
if (mountainId) attendeeQuery = attendeeQuery.eq('event.mountain_id', mountainId);
if (skillLevel) attendeeQuery = attendeeQuery.eq('event.skill_level', skillLevel);
// ... date filters, text search, etc.
```

### 2.2 Select Only Needed Columns ✅
**Files:**
- `src/app/api/events/[id]/route.ts` - Attendees query

**Changed from:**
```typescript
.select(`*, user:user_id (...)`)
```

**Changed to:**
```typescript
.select(`
  id, user_id, status, is_driver, needs_ride,
  pickup_location, responded_at, waitlist_position,
  user:user_id (id, username, display_name, avatar_url)
`)
```

---

## Phase 3: Batch Endpoints ✅ COMPLETED

### 3.1 Batch Mountains Endpoints (Already Existed)
The following batch endpoints were already implemented:
- `GET /api/mountains/batch/conditions` - All mountain conditions
- `GET /api/mountains/batch/powder-scores` - All powder scores
- `GET /api/mountains/batch/snowfall` - All snowfall history

### 3.2 Batch Events Endpoint ✅ NEW
**File:** `src/app/api/events/batch/route.ts`

**Endpoint:** `GET /api/events/batch?ids=id1,id2,id3`

**Features:**
- Fetches up to 20 events in single request
- Batch fetches all attendees, user RSVPs in parallel
- Returns full event details with attendees
- 30-second cache header

**Usage:**
```typescript
// iOS
func fetchEventsBatch(ids: [String]) async throws -> [EventWithDetails] {
    let idsParam = ids.joined(separator: ",")
    let url = URL(string: "\(baseURL)/events/batch?ids=\(idsParam)")!
    // ...
}
```

---

## Phase 4: iOS Service Optimization ✅ COMPLETED

### 4.1 Auth Token Caching ✅
See Phase 1.4 above.

### 4.2 Extended Cache TTL with Stale-While-Revalidate ✅
**File:** `ios/PowderTracker/PowderTracker/Services/EventCacheService.swift`

**Changes:**
- Extended cache expiry from 1 hour to 24 hours
- Added stale threshold of 1 hour (data is "fresh" for 1 hour)
- Added `shouldRefreshEvents()` and `shouldRefreshEventDetails()` methods
- Added `invalidateEvent(id:)` for cache invalidation on mutations

```swift
private let cacheExpirySeconds: TimeInterval = 86400 // 24 hours
private let staleThresholdSeconds: TimeInterval = 3600 // 1 hour

func getCachedEvents(allowStale: Bool = true) -> [Event]? {
    // Returns data even if stale (but not expired)
    // Caller should check shouldRefreshEvents() for background refresh
}

func shouldRefreshEvents() -> Bool {
    // Returns true if data is older than 1 hour
}

func invalidateEvent(id: String) {
    // Call after RSVP, comments, etc. to force refresh
}
```

---

## Phase 5: Database Optimization (Future)

### 5.1 Add Composite Index for Upcoming Events
```sql
CREATE INDEX CONCURRENTLY idx_events_upcoming_filtered
ON events(event_date, status, mountain_id, skill_level)
WHERE status = 'active';
```

### 5.2 Denormalize Photo/Comment Counts
Currently using COUNT queries. Consider:
- Adding `photo_count`, `comment_count` columns
- Creating triggers to maintain counts

### 5.3 Paginate Attendees
For events with many attendees, add limit to attendees query (default 50).

---

## Verification

### Testing Approach
1. **Measure Baseline:** Use Instruments/Network profiler to measure current API latency
2. **After Each Phase:** Re-measure to confirm improvements
3. **Load Testing:** Test with simulated concurrent users

### Key Metrics to Track
- Event list load time (target: <500ms)
- Event detail load time (target: <300ms)
- RSVP operation time (target: <200ms)
- Comment post time (target: <200ms)

### Test Commands
```bash
# Backend API health check
./scripts/verify-production-full.sh

# iOS build and test
./scripts/safe-build.sh test

# Measure API response times
curl -w "@curl-format.txt" -s "https://shredders-bay.vercel.app/api/events?limit=20"
```

### Create curl-format.txt for timing
```
     time_namelookup:  %{time_namelookup}s\n
        time_connect:  %{time_connect}s\n
     time_appconnect:  %{time_appconnect}s\n
    time_pretransfer:  %{time_pretransfer}s\n
       time_redirect:  %{time_redirect}s\n
  time_starttransfer:  %{time_starttransfer}s\n
                     ----------\n
          time_total:  %{time_total}s\n
```

---

## Files Modified

**Backend (High Priority):**
- ✅ `src/app/api/events/route.ts` - Cache headers, attendingOnly optimization
- ✅ `src/app/api/events/[id]/route.ts` - Cache headers, column selection
- ✅ `src/app/api/events/[id]/rsvp/route.ts` - Duplicate query fix
- ✅ `src/app/api/events/[id]/comments/route.ts` - Combined auth check
- ✅ `src/app/api/events/[id]/photos/route.ts` - Combined auth check
- ✅ `src/app/api/mountains/[mountainId]/route.ts` - Cache headers

**iOS (High Priority):**
- ✅ `ios/PowderTracker/PowderTracker/Services/EventService.swift` - Token caching
- ✅ `ios/PowderTracker/PowderTracker/Services/EventCacheService.swift` - Extended TTL, stale-while-revalidate

**New Files:**
- ✅ `src/app/api/events/batch/route.ts` - Batch events endpoint

---

## Impact Summary

| Phase | Items | Est. Savings | Status |
|-------|-------|--------------|--------|
| 1 | Quick Wins | 100-300ms per request | ✅ Done |
| 2 | Query Optimization | 200-500ms for filtered queries | ✅ Done |
| 3 | Batch Endpoints | 300-500ms for multi-event loads | ✅ Done |
| 4 | iOS Services | 50-200ms per request | ✅ Done |
| 5 | Database | Variable | Planned |

**Total Estimated Impact:** 30-50% reduction in API response times for common operations.

---

## Phase 6: Advanced Caching (User & RSVP Data) ✅ COMPLETED

### 6.1 Server-Side User Profile Caching ✅
**File:** `src/lib/auth/dual-auth.ts`

**Problem:** Every authenticated request queries `users.id` from `auth_user_id`.

**Solution:** Added in-memory cache for auth_user_id → profile mapping:
```typescript
// In-memory cache for auth_user_id -> users.id mapping
const userProfileCache = new Map<string, { profileId: string; username?: string; cachedAt: number }>();
const PROFILE_CACHE_TTL = 5 * 60 * 1000; // 5 minutes

export interface AuthenticatedUser {
  userId: string;        // auth_user_id
  profileId?: string;    // users.id (cached)
  email: string;
  username?: string;
  authMethod: 'jwt' | 'supabase';
}
```

**API Routes Updated:**
- `src/app/api/events/route.ts` - Uses `authUser.profileId`
- `src/app/api/events/[id]/route.ts` - Uses `authUser.profileId`
- `src/app/api/events/[id]/rsvp/route.ts` - Uses `authUser.profileId`
- `src/app/api/events/[id]/comments/route.ts` - Uses `authUser.profileId`
- `src/app/api/events/[id]/photos/route.ts` - Uses `authUser.profileId`

### 6.2 iOS UserProfileCacheService ✅ NEW
**File:** `ios/PowderTracker/PowderTracker/Services/UserProfileCacheService.swift`

**Features:**
- Caches current user's profile (24-hour expiry)
- Caches other users' profiles from attendee lists, comments (7-day expiry)
- In-memory + disk persistence
- Helper methods to extract profiles from events/comments

**Usage:**
```swift
// Cache current user
UserProfileCacheService.shared.cacheCurrentUser(profile)

// Get cached user
let user = UserProfileCacheService.shared.getUser(id: userId)

// Auto-cache from events
UserProfileCacheService.shared.cacheAttendeesFromEvent(attendees)
UserProfileCacheService.shared.cacheCreatorFromEvent(event)
```

### 6.3 iOS RSVPCacheService ✅ NEW
**File:** `ios/PowderTracker/PowderTracker/Services/RSVPCacheService.swift`

**Features:**
- Caches user's RSVP statuses locally
- Instant UI feedback without network requests
- Auto-invalidates event cache on RSVP changes
- 7-day expiry (or until explicitly invalidated)

**Usage:**
```swift
// Get cached RSVP status
let status = RSVPCacheService.shared.getRSVPStatus(eventId: eventId)

// Check if user has RSVP'd
let hasRSVP = RSVPCacheService.shared.hasRSVP(eventId: eventId)

// Auto-update after RSVP operation (in EventService)
rsvpCache.handleRSVPResponse(response)
rsvpCache.handleRSVPRemoved(eventId: eventId)
```

### 6.4 EventService Integration ✅
**File:** `ios/PowderTracker/PowderTracker/Services/EventService.swift`

**Integration Points:**
- `fetchEvents()` - Caches creator profiles and RSVP statuses
- `fetchEvent()` - Caches creator, attendees, and RSVP status
- `rsvp()` - Updates RSVP cache, invalidates event cache
- `removeRSVP()` - Updates RSVP cache, invalidates event cache
- `clearAllCaches()` - Clears all caches on sign out

---

## Files Modified (Phase 6)

**Backend:**
- ✅ `src/lib/auth/dual-auth.ts` - User profile cache, profileId in AuthenticatedUser
- ✅ `src/app/api/events/route.ts` - Use cached profileId
- ✅ `src/app/api/events/[id]/route.ts` - Use cached profileId
- ✅ `src/app/api/events/[id]/rsvp/route.ts` - Use cached profileId
- ✅ `src/app/api/events/[id]/comments/route.ts` - Use cached profileId
- ✅ `src/app/api/events/[id]/photos/route.ts` - Use cached profileId

**iOS (New Files):**
- ✅ `ios/PowderTracker/PowderTracker/Services/UserProfileCacheService.swift`
- ✅ `ios/PowderTracker/PowderTracker/Services/RSVPCacheService.swift`

**iOS (Modified):**
- ✅ `ios/PowderTracker/PowderTracker/Services/EventService.swift` - Cache integration

---

## Updated Impact Summary

| Phase | Items | Est. Savings | Status |
|-------|-------|--------------|--------|
| 1 | Quick Wins | 100-300ms per request | ✅ Done |
| 2 | Query Optimization | 200-500ms for filtered queries | ✅ Done |
| 3 | Batch Endpoints | 300-500ms for multi-event loads | ✅ Done |
| 4 | iOS Services | 50-200ms per request | ✅ Done |
| 5 | Database | Variable | Planned |
| 6 | Advanced Caching | 100-500ms for repeat requests | ✅ Done |

**Total Estimated Impact:** 40-60% reduction in API response times for common operations, with instant responses for cached data.
