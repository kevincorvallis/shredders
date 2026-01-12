# JWT Authentication Documentation

This document explains the JWT-based authentication system implemented in Shredders, inspired by the IWBH backend auth structure.

## Overview

The authentication system uses JSON Web Tokens (JWT) for API authentication, providing a stateless, scalable approach that works seamlessly with mobile apps and API clients. It operates alongside the existing Supabase cookie-based authentication for backward compatibility.

### Key Features

- **Access + Refresh Token Pair**: Short-lived access tokens (15 minutes) with long-lived refresh tokens (7 days)
- **Bearer Token Authentication**: Standard `Authorization: Bearer <token>` header format
- **Route Protection Middleware**: Easy-to-use middleware for protecting API routes
- **Dual Auth Support**: Works alongside Supabase authentication for gradual migration
- **IWBH-Inspired**: Based on proven patterns from the IWBH backend architecture

---

## Architecture

### Token Types

**Access Token**
- Short-lived (15 minutes by default)
- Used for authenticating API requests
- Sent in `Authorization: Bearer <token>` header
- Contains user identity claims (userId, email, username)

**Refresh Token**
- Long-lived (7 days by default)
- Used to obtain new access tokens without re-login
- Should be stored securely (never in localStorage)
- Submitted to `/api/auth/refresh` endpoint

### Token Payload

```typescript
interface TokenPayload {
  userId: string;     // Supabase auth user ID
  email: string;      // User's email
  username?: string;  // Optional username
  type: 'access' | 'refresh';
  iat: number;        // Issued at
  exp: number;        // Expiration time
}
```

---

## Quick Start

### 1. Environment Setup

JWT secrets are already configured in `.env.local`:

```bash
JWT_ACCESS_SECRET=GrZiYedVwCNCJHleVkcWNWbHEIpDH8dUm+r+T/jacrQ=
JWT_REFRESH_SECRET=DLuBHTQp/oggc6KZe1WWcpcWrwMauVPuy3pC+A7w63k=
JWT_ACCESS_EXPIRY=15m
JWT_REFRESH_EXPIRY=7d
```

**Security Note**: Rotate these secrets in production and never commit them to git.

### 2. User Authentication Flow

```bash
# Sign up a new user
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "username": "testuser"
  }'

# Response includes JWT tokens
{
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "Account created successfully"
}
```

### 3. Making Authenticated Requests

```bash
# Use access token in Authorization header
curl -X GET http://localhost:3000/api/protected/example \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Response
{
  "message": "This is a protected route",
  "user": {
    "userId": "uuid",
    "email": "user@example.com",
    "username": "testuser"
  },
  "timestamp": "2026-01-10T..."
}
```

### 4. Refreshing Tokens

```bash
# When access token expires, use refresh token
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }'

# Response with new token pair
{
  "accessToken": "new_access_token",
  "refreshToken": "new_refresh_token",
  "message": "Token refreshed successfully"
}
```

---

## Protecting API Routes

### Required Authentication

Use `withAuth` middleware to require authentication:

```typescript
// src/app/api/your-route/route.ts
import { NextResponse } from 'next/server';
import { withAuth, type AuthenticatedRequest } from '@/lib/auth';

async function handler(req: AuthenticatedRequest) {
  // User is guaranteed to be authenticated
  const userId = req.user?.userId;
  const email = req.user?.email;

  // Your route logic here
  return NextResponse.json({ success: true });
}

export const GET = withAuth(handler);
export const POST = withAuth(handler);
```

**Returns:**
- `401 Unauthorized` - If no token provided
- `403 Forbidden` - If token is invalid or expired

### Optional Authentication

Use `withOptionalAuth` for routes that work for both authenticated and anonymous users:

```typescript
import { withOptionalAuth, type AuthenticatedRequest } from '@/lib/auth';

async function handler(req: AuthenticatedRequest) {
  if (req.user) {
    // User is authenticated
    return NextResponse.json({
      message: 'Welcome back!',
      user: req.user
    });
  } else {
    // Anonymous user
    return NextResponse.json({
      message: 'Welcome, guest!'
    });
  }
}

export const GET = withOptionalAuth(handler);
```

### Manual Authentication Check

For more granular control:

```typescript
import { getAuthUser } from '@/lib/auth';

export async function POST(req: NextRequest) {
  const user = getAuthUser(req);

  if (!user) {
    return NextResponse.json(
      { error: 'Authentication required' },
      { status: 401 }
    );
  }

  // Continue with authenticated logic
}
```

---

## Dual Auth Support

The system supports both JWT bearer tokens and Supabase session cookies for backward compatibility:

```typescript
import { getAuthUser } from '@/lib/auth';
import { createClient } from '@/lib/supabase/server';

export async function POST(req: NextRequest) {
  // Try JWT first
  const jwtUser = getAuthUser(req);

  // Fallback to Supabase
  const supabase = await createClient();
  const { data: { user: supabaseUser } } = await supabase.auth.getUser();

  const user = jwtUser || supabaseUser;

  if (!user) {
    return NextResponse.json(
      { error: 'Not authenticated' },
      { status: 401 }
    );
  }

  // Use user.userId (JWT) or user.id (Supabase)
  const userId = jwtUser?.userId || supabaseUser?.id;

  // Your route logic
}
```

---

## Client-Side Integration

### React/Next.js Example

```typescript
// hooks/useJWTAuth.ts
import { useState, useEffect } from 'react';

export function useJWTAuth() {
  const [accessToken, setAccessToken] = useState<string | null>(null);
  const [refreshToken, setRefreshToken] = useState<string | null>(null);

  useEffect(() => {
    // Load tokens from secure storage
    const access = localStorage.getItem('accessToken');
    const refresh = localStorage.getItem('refreshToken');
    setAccessToken(access);
    setRefreshToken(refresh);
  }, []);

  const login = async (email: string, password: string) => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const data = await response.json();

    if (response.ok) {
      localStorage.setItem('accessToken', data.accessToken);
      localStorage.setItem('refreshToken', data.refreshToken);
      setAccessToken(data.accessToken);
      setRefreshToken(data.refreshToken);
    }

    return data;
  };

  const refresh = async () => {
    if (!refreshToken) return null;

    const response = await fetch('/api/auth/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });

    const data = await response.json();

    if (response.ok) {
      localStorage.setItem('accessToken', data.accessToken);
      localStorage.setItem('refreshToken', data.refreshToken);
      setAccessToken(data.accessToken);
      setRefreshToken(data.refreshToken);
    }

    return data;
  };

  const logout = () => {
    localStorage.removeItem('accessToken');
    localStorage.removeItem('refreshToken');
    setAccessToken(null);
    setRefreshToken(null);
  };

  return { accessToken, refreshToken, login, refresh, logout };
}
```

### Making Authenticated Requests

```typescript
const { accessToken } = useJWTAuth();

const fetchData = async () => {
  const response = await fetch('/api/protected/example', {
    headers: {
      'Authorization': `Bearer ${accessToken}`,
    },
  });

  return response.json();
};
```

---

## Mobile App Integration

### iOS/Swift Example

```swift
class AuthManager {
    private var accessToken: String?
    private var refreshToken: String?

    func login(email: String, password: String) async throws -> User {
        let url = URL(string: "https://yourapp.com/api/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.invalidCredentials
        }

        let result = try JSONDecoder().decode(LoginResponse.self, from: data)

        // Store tokens securely in Keychain
        self.accessToken = result.accessToken
        self.refreshToken = result.refreshToken

        return result.user
    }

    func makeAuthenticatedRequest<T: Decodable>(
        url: URL,
        method: String = "GET"
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method

        if let accessToken = accessToken {
            request.setValue("Bearer \(accessToken)",
                           forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check if token expired
        if let httpResponse = response as? HTTPURLResponse,
           httpResponse.statusCode == 403 {
            // Refresh token and retry
            try await refreshAccessToken()
            return try await makeAuthenticatedRequest(url: url, method: method)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func refreshAccessToken() async throws {
        guard let refreshToken = refreshToken else {
            throw AuthError.noRefreshToken
        }

        let url = URL(string: "https://yourapp.com/api/auth/refresh")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["refreshToken": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(RefreshResponse.self, from: data)

        self.accessToken = result.accessToken
        self.refreshToken = result.refreshToken
    }
}
```

---

## Security Best Practices

### Token Storage

**Web Applications:**
- ❌ **DO NOT** store tokens in localStorage (vulnerable to XSS)
- ✅ **DO** use httpOnly cookies when possible
- ✅ **DO** use sessionStorage for access tokens (cleared on tab close)
- ✅ **DO** use secure cookie for refresh tokens

**Mobile Applications:**
- ✅ **DO** use iOS Keychain (iOS)
- ✅ **DO** use Android Keystore (Android)
- ❌ **DO NOT** store in UserDefaults/SharedPreferences

### Token Transmission

- ✅ **Always** use HTTPS in production
- ✅ **Always** send tokens in `Authorization` header
- ❌ **Never** send tokens in URL parameters
- ❌ **Never** log tokens to console in production

### Secret Management

- ✅ **DO** use strong random secrets (32+ bytes)
- ✅ **DO** use different secrets for access and refresh tokens
- ✅ **DO** rotate secrets periodically
- ❌ **NEVER** commit secrets to git
- ❌ **NEVER** hardcode secrets in application code

### Token Expiration

- ✅ **DO** keep access tokens short-lived (15-30 minutes)
- ✅ **DO** implement automatic token refresh
- ✅ **DO** handle token expiration gracefully
- ✅ **DO** implement logout on refresh token expiration

---

## Troubleshooting

### "JWT secrets not configured" Error

**Problem**: Missing JWT environment variables

**Solution**: Ensure `.env.local` contains:
```bash
JWT_ACCESS_SECRET=your-secret-here
JWT_REFRESH_SECRET=your-secret-here
```

### 403 Forbidden Responses

**Problem**: Token is invalid or expired

**Solution**:
1. Check token expiration time
2. Try refreshing the token with `/api/auth/refresh`
3. If refresh fails, re-authenticate with `/api/auth/login`

### Token Verification Fails

**Problem**: Token was signed with different secret

**Solution**:
1. Ensure JWT secrets match between environments
2. Clear old tokens and re-authenticate
3. Check for secret rotation without client update

---

## API Reference

### POST /api/auth/login

Authenticate user and receive JWT tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  },
  "accessToken": "jwt_access_token",
  "refreshToken": "jwt_refresh_token",
  "message": "Logged in successfully"
}
```

### POST /api/auth/signup

Create new user account with JWT tokens.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "username": "testuser",
  "displayName": "Test User"
}
```

**Response (200):**
```json
{
  "user": {
    "id": "uuid",
    "email": "user@example.com"
  },
  "accessToken": "jwt_access_token",
  "refreshToken": "jwt_refresh_token",
  "message": "Account created successfully"
}
```

### POST /api/auth/refresh

Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "jwt_refresh_token"
}
```

**Response (200):**
```json
{
  "accessToken": "new_access_token",
  "refreshToken": "new_refresh_token",
  "message": "Token refreshed successfully"
}
```

---

## Differences from IWBH

### What We Added (Missing from IWBH):
- ✅ Token generation logic (IWBH only had verification)
- ✅ Token refresh mechanism
- ✅ Helper functions for user operations
- ✅ Complete Next.js integration
- ✅ Dual auth support (Supabase + JWT)

### What We Adapted:
- 🔄 Express.js middleware → Next.js route handlers
- 🔄 DynamoDB → Supabase (Postgres)
- 🔄 Firebase Admin SDK → Supabase Auth

### What We Kept:
- ✅ Bearer token authentication scheme
- ✅ JWT verification approach
- ✅ Optional vs required auth patterns
- ✅ Token-based stateless authentication

---

## Migration Guide

### From Supabase-Only to Dual Auth

**Step 1**: Existing routes continue working with Supabase sessions

**Step 2**: Update mobile apps to use JWT bearer tokens

**Step 3**: Gradually migrate web clients to JWT if needed

**Step 4**: Eventually deprecate Supabase sessions (optional)

### Example Migration

**Before (Supabase only):**
```typescript
const supabase = await createClient();
const { data: { user } } = await supabase.auth.getUser();
```

**After (Dual auth):**
```typescript
const jwtUser = getAuthUser(req);
const supabase = await createClient();
const { data: { user: supabaseUser } } = await supabase.auth.getUser();
const user = jwtUser || supabaseUser;
```

---

## Support

For issues or questions:
- Review this documentation
- Check the plan file: `.claude/plans/silly-launching-reef.md`
- Examine example route: `src/app/api/protected/example/route.ts`
- Review IWBH reference: `~/Downloads/IWBH/backend/middleware/auth.js`
