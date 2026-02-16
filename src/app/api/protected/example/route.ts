/**
 * GET /api/protected/example
 *
 * Example of a protected API route using dual auth middleware
 */

import { NextResponse } from 'next/server';
import { withDualAuth } from '@/lib/auth';

export const GET = withDualAuth(async (req, authUser) => {
  return NextResponse.json({
    message: 'This is a protected route',
    user: {
      userId: authUser.userId,
      email: authUser.email,
      username: authUser.username,
    },
    timestamp: new Date().toISOString(),
  });
});
