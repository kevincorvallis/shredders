# Production Verification Checklist

Use this checklist after deploying changes to verify the iOS app and backend are working correctly in production.

## Automated Verification Scripts

### Quick API Check (from project root)

```bash
./scripts/verify-production-full.sh
```

### Full Verification (API + iOS build + tests)

```bash
./scripts/verify-production-full.sh --all
```

### Options

| Command | What It Does |
|---------|--------------|
| `./scripts/verify-production-full.sh` | API checks only (fast) |
| `./scripts/verify-production-full.sh --ios-build` | API checks + build iOS |
| `./scripts/verify-production-full.sh --ios-tests` | API checks + run UI tests |
| `./scripts/verify-production-full.sh --all` | Everything (API + build + tests) |

### What the API checks verify:
- API availability and response times
- Public endpoints (events, mountains)
- Auth protection (401 for protected endpoints)
- Data quality (events have creators, mountains have data)

**All checks should pass before proceeding with manual testing.**

---

## Quick Smoke Test (5 minutes)

### Authentication
- [ ] **Apple Sign In**: Sign in with Apple completes successfully
- [ ] **Profile loads**: User profile appears after login
- [ ] **Token stored**: App stays logged in after backgrounding/foregrounding

### Core Functionality
- [ ] **Events list**: Events tab loads without errors
- [ ] **Create event**: Can create a new event (no "must be signed in" error)
- [ ] **Event appears**: Created event shows in events list
- [ ] **Sign out**: Logout clears session, returns to login screen

---

## Detailed Test Cases

### 1. Apple Sign In Flow

| Step | Expected Result | Pass |
|------|-----------------|------|
| Tap "Sign in with Apple" | Apple auth sheet appears | [ ] |
| Complete Apple authentication | Returns to app, logged in | [ ] |
| Check Profile tab | Shows user info (name, email) | [ ] |
| Force quit app, relaunch | Still logged in | [ ] |
| Background app for 5+ minutes, return | Still logged in | [ ] |

### 2. Email/Password Flow

| Step | Expected Result | Pass |
|------|-----------------|------|
| Tap Sign Up, enter valid credentials | Account created (or verification email sent) | [ ] |
| Login with created account | Successfully logged in | [ ] |
| Try signup with existing Apple email | Error: "account already exists, use original method" | [ ] |
| Login with wrong password | Error message (not "user not found") | [ ] |

### 3. Event Creation (Critical Path)

| Step | Expected Result | Pass |
|------|-----------------|------|
| Navigate to Events tab | Events list loads | [ ] |
| Tap Create Event button | Form appears | [ ] |
| Fill in: Title, Mountain, Date | Form validates inputs | [ ] |
| Tap Create/Submit | Event created successfully | [ ] |
| Check events list | New event appears | [ ] |
| Tap on created event | Detail view loads with correct info | [ ] |

### 4. RSVP Flow

| Step | Expected Result | Pass |
|------|-----------------|------|
| Open an event (not your own) | RSVP buttons visible | [ ] |
| Tap "Going" | RSVP recorded, UI updates | [ ] |
| Tap "Maybe" | RSVP changes to maybe | [ ] |
| Remove RSVP | RSVP removed successfully | [ ] |

### 5. Token Persistence & Refresh

| Step | Expected Result | Pass |
|------|-----------------|------|
| Login and use app normally | All features work | [ ] |
| Wait 20+ minutes | Token should auto-refresh | [ ] |
| Create event after waiting | Still works (token refreshed) | [ ] |
| Sign out | All tokens cleared | [ ] |
| Reopen app | Shows login screen (not logged in) | [ ] |

---

## API Endpoint Verification

Test these endpoints directly (replace `TOKEN` with a valid auth token):

```bash
# Get events (public)
curl -s "https://shredders-bay.vercel.app/api/events"

# Get events (authenticated - should show isCreator correctly)
curl -s "https://shredders-bay.vercel.app/api/events" \
  -H "Authorization: Bearer TOKEN"

# Create event (requires auth)
curl -X POST "https://shredders-bay.vercel.app/api/events" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN" \
  -d '{"mountainId":"stevens","title":"Test Event","eventDate":"2026-02-15"}'

# Without auth (should return 401)
curl -X POST "https://shredders-bay.vercel.app/api/events" \
  -H "Content-Type: application/json" \
  -d '{"mountainId":"stevens","title":"Test","eventDate":"2026-02-15"}'
```

### Expected API Responses

| Endpoint | Without Auth | With Valid Auth |
|----------|--------------|-----------------|
| GET /events | 200 OK (public data) | 200 OK (with isCreator) |
| POST /events | 401 Not authenticated | 201 Created |
| POST /events/[id]/rsvp | 401 Not authenticated | 200 OK |
| DELETE /events/[id] | 401 Not authenticated | 200 OK (if creator) |

---

## Error Handling Verification

### Authentication Errors
- [ ] Invalid credentials: Shows "Invalid email or password" (not technical errors)
- [ ] Network offline: Shows appropriate offline message
- [ ] Token expired: Auto-refreshes or prompts re-login

### Event Errors
- [ ] Missing required fields: Shows validation error
- [ ] Past date: Shows "date cannot be in the past"
- [ ] Not authenticated: Shows "sign in required" (not "user not found")
- [ ] Not authorized: Shows "can only edit your own events"

---

## Regression Checks

After any auth-related changes, verify these don't break:

- [ ] Mountains list loads correctly
- [ ] Weather overlays work
- [ ] Check-ins work (if logged in)
- [ ] Likes/comments work (if logged in)
- [ ] Push notifications register correctly
- [ ] Deep links work (e.g., `powdertracker://events/123`)

---

## Monitoring & Logs

### Check Vercel Logs
```bash
vercel logs shredders-bay --follow
```

### Key Metrics to Watch
- Authentication success rate (target: >99%)
- Event creation success rate (target: >95%)
- API response times (target: <500ms)
- Error rates by endpoint (target: <1%)

### Alert Triggers
- Auth failure rate >10% in 5 minutes
- Event creation failures spike
- 5xx errors on any endpoint
- Token refresh failures

---

## Rollback Criteria

Rollback immediately if:
- [ ] Users cannot sign in (auth completely broken)
- [ ] Event creation fails for all users
- [ ] API returns 5xx errors consistently
- [ ] Data corruption detected

### Rollback Command
```bash
git revert HEAD
git push origin main
# Or use Vercel dashboard to redeploy previous version
```

---

## Post-Deployment Checklist

### Immediate (0-5 minutes)
- [ ] Run Quick Smoke Test above
- [ ] Check Vercel deployment logs for errors
- [ ] Verify at least one real user can log in

### Short-term (5-60 minutes)
- [ ] Monitor error rates in logs
- [ ] Check for user reports of issues
- [ ] Run full Detailed Test Cases

### Long-term (1-24 hours)
- [ ] Review auth success/failure metrics
- [ ] Check for any token refresh issues
- [ ] Monitor for unusual patterns

---

## Test Accounts

| Account Type | Purpose |
|--------------|---------|
| Apple Sign In (personal) | Test Apple auth flow |
| Email: testuser123@gmail.com | Test email/password flow |
| New signup | Test fresh account creation |

---

## Version History

| Date | Version | Changes Tested |
|------|---------|----------------|
| 2026-01-28 | 2719a12c | Auth user ID fix, Apple Sign In tokens |

---

## iOS Simulator Testing

### Build and Run

```bash
# Build the app
cd ios/PowderTracker
xcodebuild -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Boot simulator if needed
xcrun simctl boot "iPhone 16 Pro"

# Install the app
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/PowderTracker-*/Build/Products/Debug-iphonesimulator/PowderTracker.app

# Launch app
xcrun simctl launch booted com.shredders.powdertracker
```

### Stream App Logs

```bash
# Stream all PowderTracker logs
xcrun simctl spawn booted log stream --predicate 'process CONTAINS "PowderTracker"'

# Filter for auth-related logs
xcrun simctl spawn booted log stream --predicate 'process CONTAINS "PowderTracker"' | grep -E "(auth|token|keychain|sign|event)"

# Filter for network errors
xcrun simctl spawn booted log stream --predicate 'process CONTAINS "PowderTracker"' | grep -iE "(error|fail|401|403|500)"
```

### Take Screenshots

```bash
# Capture current screen
xcrun simctl io booted screenshot ~/Desktop/ios_screenshot.png

# Record video (useful for debugging flows)
xcrun simctl io booted recordVideo ~/Desktop/ios_recording.mov
# Press Ctrl+C to stop recording
```

### Reset App State

```bash
# Uninstall and reinstall to clear all data (including Keychain)
xcrun simctl uninstall booted com.shredders.powdertracker
xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/PowderTracker-*/Build/Products/Debug-iphonesimulator/PowderTracker.app
```

---

## Running UI Tests

### Run All UI Tests

```bash
cd ios/PowderTracker
xcodebuild test \
  -scheme PowderTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:PowderTrackerUITests
```

### Run Specific Test Classes

```bash
# Authentication tests only
xcodebuild test \
  -scheme PowderTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:PowderTrackerUITests/AuthenticationUITests

# Events tests only
xcodebuild test \
  -scheme PowderTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:PowderTrackerUITests/EventsUITests
```

### Test Coverage Areas

| Test Class | What It Covers |
|------------|----------------|
| `AuthenticationUITests` | Apple Sign In, token persistence, sign out |
| `EventsUITests` | Event creation, auth verification |

---

## Troubleshooting

### "User not found" on Signup

**Cause:** Email already exists with a different auth method (e.g., Apple Sign In)

**Fix:**
- User should sign in with their original method
- Check if profile exists: `SELECT * FROM users WHERE email = 'user@example.com'`

### "Must be signed in" After Apple Sign In

**Cause:** Token not stored in Keychain or not passed to EventService

**Verify:**
1. Check logs for Keychain save success
2. Verify token is passed in Authorization header
3. Check `dual-auth.ts` handles Supabase tokens

**Fix:** Sign out and sign in again to refresh tokens

### "Failed to create event"

**Cause:** Usually a user ID mismatch (auth_user_id vs users.id)

**Verify:**
```sql
-- Check if user has a profile
SELECT id, auth_user_id, email FROM users WHERE auth_user_id = 'supabase-auth-id';
```

**Fix:** Ensure backend looks up `users.id` from `auth_user_id` before database operations

### Token Expired / 401 Errors

**Cause:** Access token expired and refresh failed

**Verify:**
1. Check Keychain has valid refresh token
2. Check Supabase session is valid

**Fix:**
- Force sign out and sign in again
- Clear Keychain: Uninstall and reinstall app

### App Stuck on Loading

**Cause:** Network issue or API timeout

**Verify:**
1. Check API is reachable: `curl https://shredders-bay.vercel.app/api/events`
2. Check simulator has network access

**Fix:**
- Check WiFi/network connection
- Restart simulator
- Check Vercel deployment status

### "Invalid skill level" or Validation Errors

**Cause:** iOS app sending unexpected values

**Valid Values:**
- `skillLevel`: `beginner`, `intermediate`, `advanced`, `expert`, `all`
- `eventDate`: `YYYY-MM-DD` format, must be today or future
- `departureTime`: `HH:MM` format

---

## Environment Verification

Before testing, verify the app is pointing to the correct environment:

### Check Current API Target

In `Config/AppConfig.swift`:
```swift
// Should return production URL
static var apiBaseURL: String {
    // Default: https://shredders-bay.vercel.app/api
}
```

### Override for Local Testing

Set environment variable in Xcode scheme:
- Edit Scheme → Run → Arguments → Environment Variables
- Add: `SHREDDERS_API_URL` = `http://localhost:3000/api`

### Verify at Runtime

The app logs the API base URL on launch. Check logs for:
```
[API] Using base URL: https://shredders-bay.vercel.app/api
```

---

## Database Verification

### Check User Profile Exists

```sql
SELECT id, auth_user_id, email, username, display_name
FROM users
WHERE email = 'user@example.com';
```

### Check Event Was Created

```sql
SELECT e.id, e.title, e.event_date, e.user_id, u.email
FROM events e
JOIN users u ON e.user_id = u.id
WHERE e.created_at > NOW() - INTERVAL '1 hour'
ORDER BY e.created_at DESC;
```

### Check RSVP Status

```sql
SELECT ea.status, e.title, u.email
FROM event_attendees ea
JOIN events e ON ea.event_id = e.id
JOIN users u ON ea.user_id = u.id
WHERE e.id = 'event-id-here';
```

---

## Notes

- Always test on a **real device** for Apple Sign In (simulator has limitations)
- Clear app data/reinstall if seeing stale token issues
- Check both WiFi and cellular connections
- Test with different iOS versions if possible
- The automated script (`verify-production.sh`) only tests backend APIs
- Manual testing is still required for iOS-specific flows like Apple Sign In
