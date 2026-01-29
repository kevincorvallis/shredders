# Production Verification Checklist

Use this checklist after deploying changes to verify the iOS app and backend are working correctly in production.

## Automated Verification Script

Run the automated verification script first:

```bash
cd ios/PowderTracker
./scripts/verify-production.sh
```

This checks:
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

## Notes

- Always test on a **real device** for Apple Sign In (simulator has limitations)
- Clear app data/reinstall if seeing stale token issues
- Check both WiFi and cellular connections
- Test with different iOS versions if possible
