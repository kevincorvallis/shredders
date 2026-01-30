# Event Social Features - Manual Test Checklist

Use this checklist to manually verify the Event Social Features implementation.

## Prerequisites

- [ ] iOS app is installed on device/simulator
- [ ] Have two test accounts ready (User A and User B)
- [ ] Have an existing event with some RSVPs

---

## 1. RSVP Gating Tests

### 1.1 Non-RSVP'd User Experience
- [ ] Open an event you have NOT RSVP'd to
- [ ] Verify Discussion tab shows blurred/gated content
- [ ] Verify "RSVP to Unlock" button is visible
- [ ] Verify comment count is shown (e.g., "5 comments")
- [ ] Verify Activity tab shows gated content
- [ ] Verify Photos tab shows gated content with photo count

### 1.2 RSVP Unlock Flow
- [ ] Tap "RSVP to Unlock" button
- [ ] Verify RSVP is processed (going status)
- [ ] Verify Discussion unlocks with animation
- [ ] Verify comment input field appears
- [ ] Verify Activity tab now shows full timeline
- [ ] Verify Photos tab shows full gallery

### 1.3 Event Creator Access
- [ ] Open an event you created (even without RSVP)
- [ ] Verify full access to Discussion, Activity, Photos
- [ ] Verify no gating overlay appears

---

## 2. Discussion Feature Tests

### 2.1 Comment List
- [ ] Verify comments load correctly
- [ ] Verify user avatars display (or initials fallback)
- [ ] Verify usernames and timestamps show
- [ ] Verify comment content displays fully
- [ ] Verify pull-to-refresh works

### 2.2 Posting Comments
- [ ] Tap comment input field
- [ ] Verify keyboard appears
- [ ] Type a comment
- [ ] Verify send button becomes enabled
- [ ] Tap send button
- [ ] Verify comment appears immediately (optimistic update)
- [ ] Verify haptic feedback on send
- [ ] Verify comment persists after refresh

### 2.3 Threaded Replies
- [ ] Tap "Reply" on an existing comment
- [ ] Verify "Replying to [username]" indicator appears
- [ ] Type a reply
- [ ] Send the reply
- [ ] Verify reply appears indented under parent
- [ ] Tap cancel (X) to cancel reply mode

### 2.4 Deleting Comments
- [ ] Find your own comment
- [ ] Tap "Delete" button
- [ ] Verify confirmation dialog appears
- [ ] Tap "Delete" to confirm
- [ ] Verify comment is removed
- [ ] Verify haptic feedback

### 2.5 Empty State
- [ ] Open event with no comments
- [ ] Verify "No comments yet" message
- [ ] Verify "Be the first to comment!" prompt

---

## 3. Activity Timeline Tests

### 3.1 Activity Feed
- [ ] Navigate to Activity tab
- [ ] Verify activities load in reverse chronological order
- [ ] Verify each activity shows:
  - [ ] Icon (thumbs up for going, etc.)
  - [ ] User avatar/initials
  - [ ] Description text
  - [ ] Relative timestamp

### 3.2 Activity Types
- [ ] Verify RSVP "going" activities display correctly
- [ ] Verify RSVP "maybe" activities display correctly
- [ ] Verify comment activities show preview text
- [ ] Verify photo upload activities display

### 3.3 Milestones
- [ ] Find/create event with 5+ going
- [ ] Verify milestone celebration appears (🎉)
- [ ] Verify special styling (highlighted background)
- [ ] Test milestone at 10, 15, 20 going

### 3.4 Pagination
- [ ] Scroll to bottom of activity list
- [ ] Verify more activities load
- [ ] Verify loading indicator shows

### 3.5 Empty State
- [ ] Open newly created event
- [ ] Verify "No activity yet" message

---

## 4. Photo Sharing Tests

### 4.1 Photo Gallery
- [ ] Navigate to Photos tab
- [ ] Verify photos display in grid (3 columns)
- [ ] Verify thumbnails load correctly
- [ ] Verify scroll works smoothly
- [ ] Verify pull-to-refresh works

### 4.2 Adding Photos
- [ ] Tap "Add Photo" button
- [ ] Verify photo picker opens
- [ ] Select a photo from library
- [ ] Verify upload sheet appears with preview
- [ ] Add a caption (optional)
- [ ] Tap "Upload Photo"
- [ ] Verify progress indicator shows
- [ ] Verify photo appears in gallery after upload
- [ ] Verify haptic feedback on success

### 4.3 Full-Screen Viewer
- [ ] Tap on a photo in the grid
- [ ] Verify full-screen viewer opens
- [ ] Verify photo displays at full resolution
- [ ] Verify caption shows (if present)
- [ ] Verify "by [username]" and timestamp show
- [ ] Swipe left/right to navigate photos
- [ ] Verify page indicator updates
- [ ] Tap X to close viewer

### 4.4 Deleting Photos
- [ ] Open photo you uploaded in viewer
- [ ] Tap trash icon
- [ ] Verify confirmation dialog
- [ ] Tap "Delete"
- [ ] Verify photo is removed from gallery
- [ ] Verify haptic feedback

### 4.5 Empty State
- [ ] Open event with no photos
- [ ] Verify "No photos yet" message
- [ ] Verify "Be the first to share!" prompt

---

## 5. Tab Badge Counts

- [ ] Verify Discussion tab shows comment count (if any)
- [ ] Verify Photos tab shows photo count (if any)
- [ ] Verify counts update after posting/deleting

---

## 6. Dark Mode Tests

- [ ] Enable dark mode in Settings
- [ ] Open event detail view
- [ ] Verify Discussion tab displays correctly
- [ ] Verify Activity tab displays correctly
- [ ] Verify Photos tab displays correctly
- [ ] Verify gated content displays correctly
- [ ] Verify photo viewer displays correctly

---

## 7. Accessibility Tests

### 7.1 VoiceOver
- [ ] Enable VoiceOver
- [ ] Navigate to event detail
- [ ] Verify social tabs are announced
- [ ] Navigate to Discussion
- [ ] Verify comments are read with full context
- [ ] Verify comment input is accessible
- [ ] Navigate to Activity
- [ ] Verify activities are read clearly
- [ ] Navigate to Photos
- [ ] Verify photos have accessibility labels

### 7.2 Dynamic Type
- [ ] Set text size to largest
- [ ] Verify Discussion tab text scales
- [ ] Verify Activity tab text scales
- [ ] Verify layout doesn't break

---

## 8. Network & Error Handling

### 8.1 Slow Network
- [ ] Enable Network Link Conditioner (3G)
- [ ] Load Discussion tab
- [ ] Verify loading indicator shows
- [ ] Post a comment
- [ ] Verify optimistic update works
- [ ] Verify final state is correct

### 8.2 Offline Mode
- [ ] Enable Airplane mode
- [ ] Try to load Discussion
- [ ] Verify error message shows
- [ ] Try to post comment
- [ ] Verify appropriate error handling

### 8.3 Error Recovery
- [ ] Simulate API error (server down)
- [ ] Verify error message displays
- [ ] Pull to refresh
- [ ] Verify recovery works when server is back

---

## 9. Cross-User Tests

### 9.1 Multi-User Comments
- [ ] User A posts a comment
- [ ] User B opens same event
- [ ] Verify User B sees User A's comment
- [ ] User B replies to User A
- [ ] User A refreshes
- [ ] Verify User A sees the reply

### 9.2 Multi-User Photos
- [ ] User A uploads a photo
- [ ] User B opens same event
- [ ] Verify User B sees the photo
- [ ] Verify User B cannot delete User A's photo

---

## 10. Performance Tests

- [ ] Open event with 50+ comments
- [ ] Verify smooth scrolling
- [ ] Verify no memory warnings
- [ ] Open event with 50+ photos
- [ ] Verify smooth gallery scrolling
- [ ] Verify thumbnails load progressively

---

## Test Sign-Off

| Test Section | Tester | Date | Pass/Fail |
|--------------|--------|------|-----------|
| RSVP Gating | | | |
| Discussion | | | |
| Activity Timeline | | | |
| Photo Sharing | | | |
| Tab Badges | | | |
| Dark Mode | | | |
| Accessibility | | | |
| Network Handling | | | |
| Cross-User | | | |
| Performance | | | |

**Overall Status:** [ ] PASS / [ ] FAIL

**Notes:**
