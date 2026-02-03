# Event Functionality Improvements

A phased approach to improving the event system in Shredders.

---

## Phase 1: Performance Optimizations
**Priority: High | Effort: Low**

### API Query Optimization
- [x] Parallelize database queries in `GET /api/events/[id]`
  - [x] Use `Promise.allSettled()` for attendees, comment count, photo count, conditions queries
  - [x] Move conditions fetch to parallel with other queries
  - [x] Benchmark before/after response times
- [x] Fix inefficient `attendingOnly` query in `GET /api/events`
  - [x] Skip base query when `attendingOnly` is true
  - [x] Only run the event_attendees join query

### iOS Performance
- [x] Add retry logic with exponential backoff to `EventService.swift`
  - [x] Create `executeWithRetry` helper function
  - [x] Apply to all network requests
  - [x] Add configurable max retries (default: 3)

---

## Phase 2: Notifications & Alerts
**Priority: High | Effort: Medium**

### Event Update Notifications
- [x] Notify attendees when event is cancelled
  - [x] Create notification trigger/function (`sendEventCancellationNotification`)
  - [x] Send push notification to going/maybe attendees
  - [ ] Send email notification (optional)
- [x] Notify attendees when event date/time changes
  - [x] Create notification function (`sendEventUpdateNotification`)
  - [x] API integration ready (needs PATCH endpoint integration)
- [x] Notify event creator when someone RSVPs
  - [x] Add activity record (already exists)
  - [x] Send push notification (`sendNewRSVPNotification`, `sendRSVPChangeNotification`)

### Comment Notifications
- [x] Notify event creator on new comments (`sendNewCommentNotification`)
- [x] Notify parent comment author on replies (`sendCommentReplyNotification`)
- [x] Add notification preferences (EventNotificationSettingsView.swift)

### Weather Alerts
- [ ] Add powder alert threshold per event
- [ ] Send notification if conditions exceed threshold before event date
- [ ] Add poor weather warning notifications

---

## Phase 3: Enhanced Search & Discovery
**Priority: Medium | Effort: Low**

### Additional Filters for `GET /api/events`
- [x] Add `dateFrom` and `dateTo` query params for date range filtering
- [x] Add `skillLevel` filter
- [x] Add `carpoolAvailable` filter (events offering rides)
- [x] Add `hasAvailableSeats` filter (events with carpool seats remaining)

### Search Improvements
- [x] Add text search on event title and notes
- [x] Add sorting options (date, popularity)
- [x] Add "events this weekend" shortcut filter (`thisWeekend` param)

---

## Phase 4: Carpool Matching
**Priority: Medium | Effort: Medium**

### Matching Logic
- [x] Create `GET /api/events/[id]/carpool` endpoint
  - [x] Return drivers with available seats
  - [x] Return riders who need rides
  - [x] Calculate seats remaining per driver
- [ ] Add pickup location matching
  - [ ] Store pickup location coordinates
  - [ ] Calculate distance between pickup locations
  - [ ] Suggest optimal driver-rider matches

### UI Updates
- [ ] Add carpool section to event detail view
- [ ] Show "X seats available" badge on event cards
- [ ] Add "Request ride from [driver]" action
- [ ] Add driver acceptance flow

---

## Phase 5: Security & Reliability
**Priority: Medium | Effort: Low**

### Rate Limiting
- [x] Add rate limiting to event creation (10/hour)
- [x] Add rate limiting to RSVP changes (20/hour)
- [x] Add rate limiting to comment posting (30/hour)
- [x] Return 429 with retry-after header when exceeded

### Input Validation
- [x] Add client-side validation in iOS `EventService.createEvent`
  - [x] Validate title length (3-100 chars)
  - [x] Validate notes length (max 2000)
  - [x] Validate date is not in past
  - [x] Validate time format (HH:MM)
  - [x] Validate carpool seats (0-8)
- [ ] Add client-side validation in web create form (existing server validation is sufficient)

---

## Phase 6: Event Lifecycle Features
**Priority: Medium | Effort: Medium**

### Event Cloning
- [x] Create `POST /api/events/[id]/clone` endpoint
  - [x] Copy event details except date
  - [x] Require new event date in request body
  - [x] Return new event with fresh invite token
- [ ] Add "Clone Event" button in UI (creator only)

### Event Reactivation
- [x] Add `POST /api/events/[id]/reactivate` endpoint
  - [x] Only allow if event date is in future
  - [x] Change status from 'cancelled' to 'active'
  - [ ] Notify previous attendees (requires Phase 2)
- [ ] Add "Reactivate" button for cancelled events

### Auto-Complete Events
- [ ] Add scheduled job to mark past events as 'completed'
- [ ] Run daily to update status for events where `event_date < today`

---

## Phase 7: Capacity & Waitlist
**Priority: Low | Effort: Medium**

### Capacity Limits
- [x] Add `max_attendees` column to events table (migration 010)
- [x] Update `CreateEventRequest` type to include `maxAttendees`
- [x] Add validation in RSVP endpoint to check capacity
- [x] Return waitlist status when event is full

### Waitlist
- [x] Add `waitlist` status to RSVPStatus type
- [x] Create waitlist queue ordered by `waitlist_position`
- [x] Auto-promote from waitlist when someone declines
  - [x] Create database trigger (`handle_waitlist_promotion`)
  - [ ] Notify promoted user (requires push notification integration)
- [ ] Show waitlist position in UI

---

## Phase 8: Recurring Events
**Priority: Low | Effort: High**

### Database Schema
- [x] Add `event_series` table (migration 011)
  - [x] `id`, `user_id`, title, mountain_id, recurrence settings
- [x] Add `series_id` column to events table (nullable)
- [x] Add `is_series_exception` flag for modified instances

### Recurrence Rules
- [x] Support weekly recurrence
- [x] Support biweekly recurrence
- [x] Support monthly recurrence (same day of month - `monthly_day`)
- [x] Support monthly recurrence (same weekday - `monthly_weekday`, e.g., "2nd Saturday")

### Series Management
- [x] Create `POST /api/events/series` to create recurring series
- [x] Generate event instances for next 3 months (`generate_series_instances` function)
- [x] Add `PATCH /api/events/series/[id]` with `updateFutureEvents` option
- [x] Add `DELETE /api/events/series/[id]` to cancel series
- [ ] Add scheduled job to generate future instances (requires cron setup)

---

## Phase 9: UX Polish
**Priority: Low | Effort: Low**

### Comment Improvements
- [x] Limit comment nesting depth to 2 levels
- [ ] Add @mention support in comments
- [ ] Add emoji reactions to comments

### Event Cards
- [ ] Add weather conditions preview to event cards
- [ ] Show "Best conditions!" badge when powder score > 80
- [ ] Add quick RSVP action on event cards (without opening detail)

### Sharing
- [x] Add calendar integration (.ics download)
- [x] Add "Add to Apple Calendar" deep link
- [x] Add "Add to Google Calendar" link

---

## Completion Tracking

| Phase | Status | Completion |
|-------|--------|------------|
| Phase 1: Performance | ✅ Complete | 100% |
| Phase 2: Notifications | 🟡 In Progress | 75% |
| Phase 3: Search & Discovery | ✅ Complete | 100% |
| Phase 4: Carpool Matching | 🟡 In Progress | 40% |
| Phase 5: Security | ✅ Complete | 100% |
| Phase 6: Lifecycle Features | 🟡 In Progress | 60% |
| Phase 7: Capacity & Waitlist | 🟡 In Progress | 80% |
| Phase 8: Recurring Events | 🟡 In Progress | 90% |
| Phase 9: UX Polish | 🟡 In Progress | 45% |

---

## Quick Reference

### Files to Modify

**API Routes:**
- `src/app/api/events/route.ts` - List/create events
- `src/app/api/events/[id]/route.ts` - Get/update/delete event
- `src/app/api/events/[id]/rsvp/route.ts` - RSVP management
- `src/app/api/events/[id]/clone/route.ts` - Clone event
- `src/app/api/events/[id]/reactivate/route.ts` - Reactivate cancelled event
- `src/app/api/events/[id]/carpool/route.ts` - Carpool information
- `src/app/api/events/[id]/calendar/route.ts` - Calendar export (.ics, Google, Apple)
- `src/app/api/events/series/route.ts` - List/create recurring series
- `src/app/api/events/series/[id]/route.ts` - Get/update/cancel series

**Types:**
- `src/types/event.ts` - TypeScript types

**iOS:**
- `ios/PowderTracker/PowderTracker/Services/EventService.swift` - API client
- `ios/PowderTracker/PowderTracker/Models/Event.swift` - Event models

**Database:**
- Supabase migrations for schema changes
