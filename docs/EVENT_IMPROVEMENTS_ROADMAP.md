# Event Improvements Roadmap

## Overview
This roadmap outlines improvements to the PowderTracker events system based on comprehensive analysis. The events system is currently 87% complete with excellent core functionality.

---

## Phase 1: Carpool Coordination UI (High Priority)
**Status:** ✅ Complete

### Tasks
- [x] 1.1 Create CarpoolCoordinationView for driver/rider matching
- [x] 1.2 Add "I can drive" / "I need a ride" toggle in RSVP flow
- [x] 1.3 Show driver list with available seats
- [x] 1.4 Show riders looking for rides
- [x] 1.5 Add pickup location input field
- [x] 1.6 Display carpool stats (drivers, riders, seats)

### Implementation Notes
- Created `CarpoolCoordinationView.swift` with driver/rider sections
- Created `RSVPCarpoolSheet` for RSVP with carpool options
- Integrated into `EventDetailView` - shows when event.carpoolAvailable is true
- Uses existing database fields: `is_driver`, `needs_ride`, `pickup_location`

---

## Phase 2: Calendar Integration (Medium Priority)
**Status:** ✅ Complete

### Tasks
- [x] 2.1 Add EventKit framework integration - Created CalendarService.swift
- [x] 2.2 Create "Add to Calendar" button in EventDetailView - Added to share menu
- [x] 2.3 Include event title, date, time, location, notes - Full event details included
- [x] 2.4 Handle calendar permission requests gracefully - iOS 17+ fullAccess support
- [ ] 2.5 Update calendar event when event is edited (future enhancement)
- [ ] 2.6 Remove calendar event when event is cancelled (future enhancement)

### Implementation Notes
- Created `CalendarService.swift` with EKEventStore integration
- Supports iOS 17+ full calendar access and fallback for older versions
- Adds morning-of and 1-hour-before alarms automatically
- Added to share menu in EventDetailView with "Add to Calendar" option

---

## Phase 3: Event Search & Discovery (Medium Priority)
**Status:** ✅ Complete (Core)

### Tasks
- [x] 3.1 Add search bar to EventsView - Used .searchable modifier
- [x] 3.2 Implement search by title, notes, mountain, location
- [ ] 3.3 Add date range filter (future enhancement)
- [ ] 3.4 Add distance/location filter (future enhancement)
- [ ] 3.5 Add skill level filter (future enhancement)
- [ ] 3.6 Persist recent searches (future enhancement)

### Implementation Notes
- Added `.searchable` modifier to EventsView
- Client-side filtering by title, mountain name, notes, departure location
- Shows ContentUnavailableView.search when no results found

---

## Phase 4: Push Notifications (High Priority - Future)
**Status:** Database function exists, implementation missing

### Tasks
- [ ] 4.1 Set up APNs integration
- [ ] 4.2 Morning-of event reminders
- [ ] 4.3 Event update notifications
- [ ] 4.4 New comment notifications
- [ ] 4.5 RSVP change notifications
- [ ] 4.6 Notification preferences settings

### Implementation Notes
- `get_events_for_reminder(date)` function exists in DB
- Need APNs setup and backend scheduler

---

## Phase 5: Map Integration (Low Priority)
**Status:** Not implemented

### Tasks
- [ ] 5.1 Show departure locations on map
- [ ] 5.2 Integrate with Apple Maps for directions
- [ ] 5.3 Group events by location
- [ ] 5.4 Show distance from user location

---

## Phase 6: Bug Fixes & Polish
**Status:** ✅ Complete

### Tasks
- [x] 6.1 Fix PookieBSnowIntroView memory leak (particleTimer) - Replaced Timer.publish with TimelineView
- [x] 6.2 Fix force unwrap crash risk in snowflakes Canvas - Added guard let check
- [x] 6.3 Fix division by zero in starsLayer - Added guard for zero size
- [x] 6.4 Clean up redundant brockBlink code - Fixed scaleEffect to only apply y-axis

---

## Current Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Event CRUD | ✅ Complete | Create, edit, cancel working |
| RSVP System | ✅ Complete | Going, Maybe, Declined |
| Discussion | ✅ Complete | Threaded comments, RSVP-gated |
| Photos | ✅ Complete | Upload, gallery, thumbnails |
| Activity Feed | ✅ Complete | 8 activity types |
| Sharing/Invites | ✅ Complete | QR, iMessage, web preview |
| Last Minute Crew | ✅ Complete | Urgency countdown |
| Carpool UI | ✅ Complete | Driver/rider matching, RSVP sheet |
| Bug Fixes | ✅ Complete | Memory leak, crash risks fixed |
| Calendar | ✅ Complete | Add to Calendar, auto-alarms |
| Search | ✅ Complete | Title, mountain, notes, location |
| Push Notifications | ❌ Missing | DB functions ready |
| Map View | ❌ Missing | No departure map |

---

## Priority Order (Updated)
1. ~~**Phase 1: Carpool UI**~~ ✅ Complete
2. ~~**Phase 6: Bug Fixes**~~ ✅ Complete
3. ~~**Phase 2: Calendar**~~ ✅ Complete
4. ~~**Phase 3: Search**~~ ✅ Complete
5. **Phase 4: Push Notifications** - Requires APNs infrastructure
6. **Phase 5: Map** - Nice to have
