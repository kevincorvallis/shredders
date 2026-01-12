# Sprint 1 Security Features - Test Plan

## Overview
This document outlines the testing procedures for Sprint 1 Critical Security Enhancements:
- ✅ Token Blacklist/Revocation System
- ✅ Rate Limiting on Auth Endpoints
- ✅ Zod Input Validation
- ✅ Audit Logging Infrastructure

---

## Prerequisites

### 1. Apply Database Migration
Before testing, ensure the database migration has been applied:

**Option A: Supabase Dashboard (Recommended)**
1. Go to https://supabase.com/dashboard
2. Select your project
3. Navigate to SQL Editor
4. Copy contents of `migrations/001_token_blacklist_and_audit_logs.sql`
5. Paste and execute

**Option B: Supabase CLI**
```bash
brew install supabase/tap/supabase
supabase link --project-ref <your-project-ref>
supabase db push
```

**Verify Migration**
Check that these tables exist:
- `token_blacklist` (with indexes on jti, user_id, expires_at)
- `audit_logs` (with indexes on user_id, event_type, created_at)

### 2. Environment Setup
Ensure `.env.local` contains:
```env
# JWT Configuration
JWT_ACCESS_SECRET=<at-least-32-character-secret>
JWT_REFRESH_SECRET=<different-32-character-secret>
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d

# Supabase
NEXT_PUBLIC_SUPABASE_URL=<your-supabase-url>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

---

## Test Suite

### Test 1: Input Validation (Zod Schemas)

#### 1.1 Signup Validation

**Test: Valid Signup**
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "username": "testuser",
    "displayName": "Test User"
  }'
```
**Expected**: 200 OK with user data and tokens

**Test: Weak Password**
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "weak",
    "username": "testuser"
  }'
```
**Expected**: 400 Bad Request with validation errors:
```json
{
  "error": "Validation failed",
  "details": [
    "Must be at least 12 characters",
    "Must contain uppercase letter",
    "Must contain number",
    "Must contain special character"
  ]
}
```

**Test: Invalid Email**
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "not-an-email",
    "password": "SecurePass123!",
    "username": "testuser"
  }'
```
**Expected**: 400 Bad Request with "Invalid email" error

**Test: Invalid Username (special chars)**
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!",
    "username": "test@user!"
  }'
```
**Expected**: 400 Bad Request with "Alphanumeric and underscore only" error

#### 1.2 Login Validation

**Test: Valid Login**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }'
```
**Expected**: 200 OK with tokens

**Test: Missing Fields**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com"
  }'
```
**Expected**: 400 Bad Request with validation error

---

### Test 2: Rate Limiting

#### 2.1 Login Rate Limit (5 per 5 minutes per IP+email)

**Test: Exceed Login Rate Limit**
```bash
# Run this command 6 times rapidly
for i in {1..6}; do
  echo "Attempt $i:"
  curl -X POST http://localhost:3000/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{
      "email": "test@example.com",
      "password": "WrongPassword123!"
    }'
  echo -e "\n---"
done
```

**Expected**:
- Attempts 1-5: 401 Unauthorized (invalid credentials)
- Attempt 6: 429 Too Many Requests
  ```json
  {
    "error": "Too many login attempts",
    "retryAfter": 300,
    "message": "Please try again in 300 seconds"
  }
  ```
- Response includes `Retry-After: 300` header

**Verify**: Wait 5 minutes or test with different IP/email combination

#### 2.2 Signup Rate Limit (3 per hour per IP)

**Test: Exceed Signup Rate Limit**
```bash
# Run this command 4 times rapidly with different emails
for i in {1..4}; do
  echo "Attempt $i:"
  curl -X POST http://localhost:3000/api/auth/signup \
    -H "Content-Type: application/json" \
    -d "{
      \"email\": \"test$i@example.com\",
      \"password\": \"SecurePass123!\",
      \"username\": \"testuser$i\"
    }"
  echo -e "\n---"
done
```

**Expected**:
- Attempts 1-3: 200 OK (or 400 if user exists)
- Attempt 4: 429 Too Many Requests with `retryAfter` in minutes

#### 2.3 Refresh Rate Limit (10 per minute per IP)

**Test: Exceed Refresh Rate Limit**
```bash
# First get a refresh token by logging in
REFRESH_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq -r '.refreshToken')

# Try to refresh 11 times
for i in {1..11}; do
  echo "Attempt $i:"
  curl -X POST http://localhost:3000/api/auth/refresh \
    -H "Content-Type: application/json" \
    -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}"
  echo -e "\n---"
done
```

**Expected**:
- Attempts 1-10: 200 OK with new tokens (or 401 if token invalid after first use)
- Attempt 11: 429 Too Many Requests

---

### Test 3: Token Blacklist & Revocation

#### 3.1 Logout Blacklists Token

**Test: Token Works Before Logout**
```bash
# 1. Login to get tokens
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }')

ACCESS_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.accessToken')

# 2. Access protected route (should work)
curl -X GET http://localhost:3000/api/protected \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```
**Expected**: 200 OK (or whatever the protected route returns)

**Test: Token Blacklisted After Logout**
```bash
# 3. Logout (blacklists the token)
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 4. Try to access protected route again (should fail)
curl -X GET http://localhost:3000/api/protected \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```
**Expected**: 401 Unauthorized with "Token has been revoked" error

#### 3.2 Refresh Token Blacklisted After Use

**Test: Refresh Token Single Use**
```bash
# 1. Get refresh token
REFRESH_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq -r '.refreshToken')

# 2. Use refresh token (should work)
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}"

# 3. Try to use same refresh token again (should fail)
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\": \"$REFRESH_TOKEN\"}"
```
**Expected**:
- First refresh: 200 OK with new tokens
- Second refresh: 401 Unauthorized "Refresh token has been revoked"

---

### Test 4: Audit Logging

#### 4.1 Verify Audit Logs Created

**Test: Check Audit Logs in Database**
```sql
-- In Supabase SQL Editor, run:
SELECT
  event_type,
  success,
  user_id,
  ip_address,
  created_at,
  event_data
FROM audit_logs
ORDER BY created_at DESC
LIMIT 20;
```

**Expected Events**:
- `login` - successful logins
- `login_failed` - failed login attempts
- `signup` - new user registrations
- `signup_failed` - failed signups
- `refresh` - token refreshes
- `refresh_failed` - failed refresh attempts
- `logout` - user logouts
- `rate_limit_exceeded` - rate limit violations

**Verify Event Data**:
- Each event has `user_id` (except failed before user identified)
- `ip_address` is captured
- `user_agent` is captured
- `success` boolean is set correctly
- `event_data` contains relevant context (e.g., login duration)

#### 4.2 Query Audit Logs via API

**Test: User Can View Own Audit Logs**
```bash
# Get access token
ACCESS_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq -r '.accessToken')

# Query user's audit logs (if endpoint exists)
curl -X GET http://localhost:3000/api/auth/audit-logs \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Note**: If this endpoint doesn't exist yet, verify in database directly (see Test 4.1)

---

### Test 5: Middleware Blacklist Checking

#### 5.1 Protected Routes Reject Blacklisted Tokens

**Test: Access Protected Route with Blacklisted Token**
```bash
# 1. Create a protected test route if needed
# Edit: src/app/api/test-protected/route.ts

# 2. Login and get token
ACCESS_TOKEN=$(curl -s -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "SecurePass123!"
  }' | jq -r '.accessToken')

# 3. Access protected route (should work)
curl -X GET http://localhost:3000/api/test-protected \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 4. Logout (blacklists token)
curl -X POST http://localhost:3000/api/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 5. Try to access protected route again (should fail)
curl -X GET http://localhost:3000/api/test-protected \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

**Expected**:
- Step 3: 200 OK
- Step 5: 401 Unauthorized "Token has been revoked"

---

## Database Verification

### Verify Token Blacklist Table

```sql
-- Check blacklisted tokens
SELECT
  jti,
  user_id,
  token_type,
  reason,
  revoked_at,
  expires_at
FROM token_blacklist
ORDER BY revoked_at DESC
LIMIT 10;
```

**Expected**:
- Tokens from logout operations with reason "User logout"
- Old refresh tokens with reason "Token replaced"
- Each entry has valid `expires_at` timestamp

### Verify Cleanup Function

```sql
-- Test cleanup function
SELECT cleanup_expired_blacklist_tokens();
```

**Expected**: Returns count of deleted expired tokens (may be 0 if none expired)

---

## Security Best Practices Checklist

- [x] **JWT Secrets**: Minimum 32 characters, cryptographically random
- [x] **Token Expiry**: Access tokens ≤ 15 minutes, Refresh tokens ≤ 7 days
- [x] **Rate Limiting**: Prevents brute force attacks on auth endpoints
- [x] **Input Validation**: All inputs validated with Zod schemas
- [x] **Password Strength**: Minimum 12 characters with complexity requirements
- [x] **Token Revocation**: Blacklist system prevents token reuse
- [x] **Audit Logging**: All auth events logged with IP and user agent
- [x] **Error Messages**: Generic messages to prevent user enumeration
- [x] **Blacklist Checking**: Middleware checks blacklist on all protected routes
- [x] **Database RLS**: Row-level security policies on sensitive tables

---

## Known Issues & Future Enhancements

### Current Limitations
1. **Blacklist Storage**: Using database (slower than Redis)
   - **Mitigation**: Indexed on `jti` for fast lookups
   - **Future**: Migrate to Redis for sub-millisecond lookups

2. **No Refresh Token Rotation**: Refresh tokens not yet rotating
   - **Planned**: Sprint 2 will add token rotation

3. **No Session Management UI**: Users can't view/revoke sessions
   - **Planned**: Sprint 3 will add session management API

### Performance Considerations
- **Blacklist Lookup**: ~10-50ms per request (database lookup)
- **Audit Log Insert**: Async, doesn't block response
- **Rate Limit Check**: In-memory, <1ms

---

## Rollback Plan

If issues arise, rollback steps:

1. **Revert Code Changes**
   ```bash
   git revert <sprint-1-commit-hash>
   ```

2. **Drop Database Tables** (only if necessary)
   ```sql
   DROP TABLE IF EXISTS audit_logs;
   DROP TABLE IF EXISTS token_blacklist;
   DROP FUNCTION IF EXISTS cleanup_expired_blacklist_tokens();
   ```

3. **Restore Environment Variables**
   - Remove new JWT configuration
   - Restore previous values

---

## Success Criteria

Sprint 1 is considered successful when:

- ✅ All 5 test sections pass
- ✅ Database migration applied without errors
- ✅ Audit logs capture all auth events
- ✅ Rate limiting blocks excessive requests
- ✅ Revoked tokens rejected by middleware
- ✅ Input validation prevents malformed requests
- ✅ No security vulnerabilities introduced
- ✅ Performance impact < 100ms per request

---

## Next Steps

After Sprint 1 verification:

1. **Sprint 2**: Refresh Token Rotation
   - Detect token reuse
   - Implement token families
   - Auto-revoke on suspicious activity

2. **Sprint 3**: Session Management
   - User-facing session list API
   - Device tracking
   - Revoke specific sessions

3. **Sprint 4**: Advanced Features
   - Password reset flow
   - Multi-factor authentication
   - API key management

---

## Support

For issues or questions:
- Review plan: `~/.claude/plans/silly-launching-reef.md`
- Check logs: `audit_logs` table in Supabase
- Debug: Enable verbose logging in auth modules
