/**
 * GET /api/protected/example
 *
 * Example of a protected API route using JWT middleware
 * Pattern based on IWBH's authenticateToken middleware
 */

import { NextResponse } from 'next/server';
import { withAuth, type AuthenticatedRequest } from '@/lib/auth';

async function handler(req: AuthenticatedRequest) {
  // User is automatically authenticated and available on req.user
  return NextResponse.json({
    message: 'This is a protected route',
    user: {
      userId: req.user?.userId,
      email: req.user?.email,
      username: req.user?.username,
    },
    timestamp: new Date().toISOString(),
  });
}

export const GET = withAuth(handler);
