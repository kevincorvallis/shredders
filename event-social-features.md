# Event Social Features Implementation Checklist

A phased checklist for implementing Partiful-style social features for events in the Shredders iOS app. RSVP-gated content model: users must RSVP to see/participate in discussions, photos, and activity.

---

## Tasks

### Phase 1: Backend API - Event Comments

- [ ] 1.1 Create `GET /api/events/[id]/comments` endpoint
- [ ] 1.2 Add RSVP validation middleware (return 403 if user hasn't RSVP'd)
- [ ] 1.3 Create `POST /api/events/[id]/comments` endpoint with RSVP check
- [ ] 1.4 Support threaded replies (parent_id field)
- [ ] 1.5 Return comment count for non-RSVP'd users (teaser)
- [ ] 1.6 Add `DELETE /api/events/[id]/comments/[commentId]` for own comments
- [ ] 1.7 Test endpoints with Postman/curl - verify RSVP gating works

- [ ] **HARD STOP** - Checkpoint: Backend comments API complete. Test all endpoints before proceeding.

**Validation:**
```bash
# Test comment endpoint without RSVP (should return 403)
curl -X GET "https://shredders-bay.vercel.app/api/events/TEST_EVENT_ID/comments" \
  -H "Authorization: Bearer TEST_TOKEN"

# Test comment endpoint with valid RSVP (should return 200)
# First RSVP to an event, then fetch comments

# Test posting a comment
curl -X POST "https://shredders-bay.vercel.app/api/events/TEST_EVENT_ID/comments" \
  -H "Authorization: Bearer TEST_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Test comment"}'
```

---

### Phase 2: iOS Models & Service Layer

- [ ] 2.1 Create `EventComment.swift` model (id, eventId, userId, content, createdAt, user, parentId, replies)
- [ ] 2.2 Add `fetchEventComments(eventId:)` to `EventService.swift`
- [ ] 2.3 Add `postEventComment(eventId:content:parentId:)` to `EventService.swift`
- [ ] 2.4 Add `deleteEventComment(eventId:commentId:)` to `EventService.swift`
- [ ] 2.5 Create `EventDiscussionViewModel.swift` with `@MainActor`
- [ ] 2.6 Handle loading, error, and empty states in ViewModel
- [ ] 2.7 Implement optimistic UI updates for posting comments

- [ ] **HARD STOP** - Checkpoint: iOS service layer complete. Build and verify no compile errors.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Verify model exists
ls ios/PowderTracker/PowderTracker/Models/EventComment.swift

# Verify ViewModel has @MainActor
grep "@MainActor" ios/PowderTracker/PowderTracker/ViewModels/EventDiscussionViewModel.swift
```

---

### Phase 3: iOS Discussion UI

- [ ] 3.1 Create `EventDiscussionView.swift` component
- [ ] 3.2 Show comment list with user avatars, names, timestamps
- [ ] 3.3 Add text input field with send button at bottom
- [ ] 3.4 Implement pull-to-refresh for comments
- [ ] 3.5 Show threaded replies with indentation
- [ ] 3.6 Add swipe-to-delete for own comments
- [ ] 3.7 Show loading spinner while fetching
- [ ] 3.8 Show empty state: "Be the first to comment!"

- [ ] **HARD STOP** - Checkpoint: Discussion UI complete. Test in simulator before proceeding.

**Validation:**
```bash
# Build and run
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Manual testing:
# - [ ] Open an event you've RSVP'd to
# - [ ] Verify discussion section appears
# - [ ] Post a comment
# - [ ] Verify comment appears immediately
# - [ ] Pull to refresh
# - [ ] Delete your own comment
```

---

### Phase 4: RSVP Gating UI

- [ ] 4.1 Create `RSVPGatedContentView.swift` wrapper component
- [ ] 4.2 Show blurred preview with comment count for non-RSVP'd users
- [ ] 4.3 Display "RSVP to join the conversation" CTA overlay
- [ ] 4.4 Tapping CTA triggers RSVP sheet/flow
- [ ] 4.5 Animate unlock transition when user RSVPs
- [ ] 4.6 Integrate gated view into `EventDetailView.swift`
- [ ] 4.7 Pass user's RSVP status to determine gating

- [ ] **HARD STOP** - Checkpoint: RSVP gating complete. Test both RSVP'd and non-RSVP'd states.

**Validation:**
```bash
# Manual testing:
# - [ ] Open an event you have NOT RSVP'd to
# - [ ] Verify discussion shows blurred with "RSVP to join" overlay
# - [ ] Verify comment count is visible (e.g., "5 comments")
# - [ ] RSVP to the event
# - [ ] Verify discussion unlocks and shows full content
# - [ ] Sign out, sign in as different user, verify gating works
```

---

### Phase 5: Activity Timeline Backend

- [ ] 5.1 Create `event_activity` table in Supabase (or use computed view)
- [ ] 5.2 Create `GET /api/events/[id]/activity` endpoint
- [ ] 5.3 Return activity types: rsvp_change, comment_posted, milestone_reached
- [ ] 5.4 Calculate milestones server-side (5 going, 10 going, etc.)
- [ ] 5.5 Include user info (avatar, name) for each activity
- [ ] 5.6 Paginate results (limit 20, offset support)
- [ ] 5.7 Add RSVP gating to activity endpoint

- [ ] **HARD STOP** - Checkpoint: Activity API complete. Test endpoint returns correct data.

**Validation:**
```bash
# Test activity endpoint
curl -X GET "https://shredders-bay.vercel.app/api/events/TEST_EVENT_ID/activity" \
  -H "Authorization: Bearer TEST_TOKEN"

# Verify response includes:
# - RSVP activities with user info
# - Comment activities
# - Milestone activities (if applicable)
```

---

### Phase 6: Activity Timeline iOS

- [ ] 6.1 Create `EventActivity.swift` model
- [ ] 6.2 Create `EventActivityViewModel.swift`
- [ ] 6.3 Add `fetchEventActivity(eventId:)` to `EventService.swift`
- [ ] 6.4 Create `EventActivityView.swift` timeline component
- [ ] 6.5 Design activity item cells (icon + "Sarah RSVP'd going" + timestamp)
- [ ] 6.6 Show milestone celebrations with special styling (🎉 emoji, highlight)
- [ ] 6.7 Integrate into `EventDetailView.swift` (tab or section)
- [ ] 6.8 Apply RSVP gating to activity timeline

- [ ] **HARD STOP** - Checkpoint: Activity timeline complete. Verify in simulator.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Manual testing:
# - [ ] Open an event you've RSVP'd to
# - [ ] Verify activity timeline appears
# - [ ] Verify RSVP activities show correctly
# - [ ] Verify milestones display with celebration styling
# - [ ] Verify non-RSVP'd users see gated content
```

---

### Phase 7: Photo Sharing Backend

- [ ] 7.1 Add `event_id` column to `photos` table (if not exists)
- [ ] 7.2 Create `GET /api/events/[id]/photos` endpoint with RSVP gating
- [ ] 7.3 Create `POST /api/events/[id]/photos` endpoint for uploads
- [ ] 7.4 Integrate with Supabase Storage for image uploads
- [ ] 7.5 Generate thumbnail URLs for gallery view
- [ ] 7.6 Return photo count for non-RSVP'd users (teaser)
- [ ] 7.7 Add `DELETE /api/events/[id]/photos/[photoId]` for own photos

- [ ] **HARD STOP** - Checkpoint: Photo API complete. Test upload and retrieval.

**Validation:**
```bash
# Test photo list endpoint
curl -X GET "https://shredders-bay.vercel.app/api/events/TEST_EVENT_ID/photos" \
  -H "Authorization: Bearer TEST_TOKEN"

# Test photo upload (multipart form)
curl -X POST "https://shredders-bay.vercel.app/api/events/TEST_EVENT_ID/photos" \
  -H "Authorization: Bearer TEST_TOKEN" \
  -F "photo=@test-image.jpg" \
  -F "caption=Great powder day!"
```

---

### Phase 8: Photo Sharing iOS

- [ ] 8.1 Create `EventPhoto.swift` model
- [ ] 8.2 Add `fetchEventPhotos(eventId:)` to `EventService.swift`
- [ ] 8.3 Add `uploadEventPhoto(eventId:image:caption:)` to `EventService.swift`
- [ ] 8.4 Create `EventPhotosViewModel.swift`
- [ ] 8.5 Create `EventPhotosView.swift` grid gallery
- [ ] 8.6 Create `EventPhotoUploadView.swift` with camera/library picker
- [ ] 8.7 Show full-screen photo viewer on tap
- [ ] 8.8 Add "Add Photo" button for RSVP'd users
- [ ] 8.9 Show upload progress indicator
- [ ] 8.10 Apply RSVP gating with blurred preview and photo count

- [ ] **HARD STOP** - Checkpoint: Photo sharing complete. Test full upload flow.

**Validation:**
```bash
# Build check
cd ios/PowderTracker && xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' build

# Manual testing:
# - [ ] Open an event you've RSVP'd to
# - [ ] Verify photos section appears
# - [ ] Tap "Add Photo" and select from library
# - [ ] Verify upload progress shows
# - [ ] Verify photo appears in gallery after upload
# - [ ] Tap photo to view full-screen
# - [ ] Delete your own photo
# - [ ] Verify non-RSVP'd users see blurred preview with count
```

---

### Phase 9: Integration & Polish

- [ ] 9.1 Add Discussion/Activity/Photos sections to `EventDetailView.swift`
- [ ] 9.2 Use segmented control or tabs to switch between sections
- [ ] 9.3 Show badge counts on tabs (3 new comments, 5 photos)
- [ ] 9.4 Add haptic feedback on comment post and photo upload
- [ ] 9.5 Implement real-time updates (polling or Supabase realtime)
- [ ] 9.6 Add push notifications for new comments on events you're attending
- [ ] 9.7 Cache comments/photos for offline viewing
- [ ] 9.8 Add accessibility labels to all new UI elements

- [ ] **HARD STOP** - Checkpoint: Integration complete. Full end-to-end testing.

**Validation:**
```bash
# Run all tests
cd ios/PowderTracker && xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16'

# Manual testing checklist:
# - [ ] Create new event
# - [ ] RSVP to event as different user
# - [ ] Post comment as RSVP'd user
# - [ ] Verify comment appears
# - [ ] Upload photo
# - [ ] Verify photo in gallery
# - [ ] Check activity timeline shows all actions
# - [ ] Sign out, view event as guest - verify gating
# - [ ] Test VoiceOver on all new elements
# - [ ] Test in dark mode
```

---

### Phase 10: Testing & QA

- [ ] 10.1 Write unit tests for `EventDiscussionViewModel`
- [ ] 10.2 Write unit tests for `EventActivityViewModel`
- [ ] 10.3 Write unit tests for `EventPhotosViewModel`
- [ ] 10.4 Add API tests for comment RSVP gating (401/403 scenarios)
- [ ] 10.5 Add UI tests for RSVP flow unlocking content
- [ ] 10.6 Test on iPhone SE (smallest screen)
- [ ] 10.7 Test on iPhone Pro Max (largest screen)
- [ ] 10.8 Test with slow network (Network Link Conditioner)
- [ ] 10.9 Test offline mode - verify cached content displays
- [ ] 10.10 Verify no memory leaks with Instruments

- [ ] **HARD STOP** - Checkpoint: All tests passing. Ready for release.

**Validation:**
```bash
# Run full test suite
cd ios/PowderTracker && xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' -enableCodeCoverage YES

# Check for memory leaks
# Manual: Xcode → Product → Profile → Leaks

# Test on multiple devices
xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)'
xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max'
```

---

## Universal Validation (Run After ANY Phase)

```bash
#!/bin/bash
# Quick smoke test for event social features

echo "🎿 Event Social Features Smoke Test"
echo "===================================="

cd ios/PowderTracker

# 1. Does it build?
echo "1. Build check..."
xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet build && echo "✅ Build passed" || echo "❌ Build FAILED"

# 2. Do tests pass?
echo "2. Test check..."
xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet 2>&1 | tail -3

# 3. New files exist?
echo "3. New files check..."
for f in "Models/EventComment.swift" "ViewModels/EventDiscussionViewModel.swift" "Views/Events/EventDiscussionView.swift"; do
  [ -f "PowderTracker/$f" ] && echo "✅ $f" || echo "⏳ $f (not yet created)"
done

echo ""
echo "Manual checks:"
echo "- [ ] ⌘R - App runs without crash"
echo "- [ ] Open event detail"
echo "- [ ] Verify discussion section visible (if RSVP'd)"
echo "- [ ] Verify gating works (if not RSVP'd)"
echo "- [ ] Post a test comment"
echo "- [ ] ⇧⌘A - Toggle dark mode, verify visuals"
```

---

## Success Criteria

- [ ] All API endpoints return correct responses with RSVP validation
- [ ] RSVP-gated content shows blurred preview for non-attendees
- [ ] Users can post comments after RSVP'ing
- [ ] Activity timeline shows RSVPs, comments, and milestones
- [ ] Photo upload and gallery work correctly
- [ ] All new UI works in light and dark mode
- [ ] VoiceOver reads all new elements meaningfully
- [ ] No memory leaks detected
- [ ] All tests pass
- [ ] App builds without errors

---

## Files to Create/Modify

### New Files
| File | Purpose |
|------|---------|
| `ios/.../Models/EventComment.swift` | Comment model |
| `ios/.../Models/EventActivity.swift` | Activity model |
| `ios/.../Models/EventPhoto.swift` | Photo model |
| `ios/.../ViewModels/EventDiscussionViewModel.swift` | Discussion state |
| `ios/.../ViewModels/EventActivityViewModel.swift` | Activity state |
| `ios/.../ViewModels/EventPhotosViewModel.swift` | Photos state |
| `ios/.../Views/Events/EventDiscussionView.swift` | Comment list UI |
| `ios/.../Views/Events/EventActivityView.swift` | Timeline UI |
| `ios/.../Views/Events/EventPhotosView.swift` | Photo gallery UI |
| `ios/.../Views/Events/RSVPGatedContentView.swift` | Gating wrapper |
| `src/app/api/events/[id]/comments/route.ts` | Comments API |
| `src/app/api/events/[id]/activity/route.ts` | Activity API |
| `src/app/api/events/[id]/photos/route.ts` | Photos API |

### Modified Files
| File | Changes |
|------|---------|
| `ios/.../Views/Events/EventDetailView.swift` | Add social sections |
| `ios/.../Services/EventService.swift` | Add new API methods |
