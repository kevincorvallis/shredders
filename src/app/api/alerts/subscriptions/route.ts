import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/**
 * Helper: Look up internal user profile ID from auth_user_id
 */
async function getProfileId(authUserId: string): Promise<string | null> {
  const adminClient = createAdminClient();
  const { data } = await adminClient
    .from('users')
    .select('id')
    .eq('auth_user_id', authUserId)
    .single();
  return data?.id ?? null;
}

/**
 * GET /api/alerts/subscriptions
 *
 * Fetch alert subscriptions for the current user
 * Query params:
 *   - mountainId: Filter by mountain (optional)
 */
export const GET = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();
    const { searchParams } = new URL(request.url);

    const profileId = await getProfileId(authUser.userId);
    if (!profileId) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    const mountainId = searchParams.get('mountainId');

    // Build query
    let query = adminClient
      .from('alert_subscriptions')
      .select('*')
      .eq('user_id', profileId)
      .order('created_at', { ascending: false });

    if (mountainId) {
      query = query.eq('mountain_id', mountainId);
    }

    const { data: subscriptions, error } = await query;

    if (error) {
      console.error('Error fetching subscriptions:', error);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ subscriptions: subscriptions || [] });
  } catch (error) {
    return handleError(error, { endpoint: 'GET /api/alerts/subscriptions' });
  }
});

/**
 * POST /api/alerts/subscriptions
 *
 * Create or update an alert subscription
 * Body:
 *   - mountainId: Mountain ID (required)
 *   - weatherAlerts: Subscribe to weather alerts (default: true)
 *   - powderAlerts: Subscribe to powder alerts (default: true)
 *   - powderThreshold: Minimum inches for powder alert (default: 6)
 */
export const POST = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();

    const profileId = await getProfileId(authUser.userId);
    if (!profileId) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    const body = await request.json();
    const {
      mountainId,
      weatherAlerts = true,
      powderAlerts = true,
      powderThreshold = 6,
    } = body;

    // Validate required fields
    if (!mountainId) {
      return handleError(Errors.missingField('mountainId'));
    }

    // Validate powder threshold
    if (powderThreshold < 0 || powderThreshold > 100) {
      return handleError(Errors.validationFailed(['Powder threshold must be between 0 and 100 inches']));
    }

    // Check if subscription already exists
    const { data: existing } = await adminClient
      .from('alert_subscriptions')
      .select('id')
      .eq('user_id', profileId)
      .eq('mountain_id', mountainId)
      .maybeSingle();

    let subscription;

    if (existing) {
      // Update existing subscription
      const { data: updated, error: updateError } = await adminClient
        .from('alert_subscriptions')
        .update({
          weather_alerts: weatherAlerts,
          powder_alerts: powderAlerts,
          powder_threshold: powderThreshold,
          updated_at: new Date().toISOString(),
        })
        .eq('id', existing.id)
        .select()
        .single();

      if (updateError) {
        console.error('Error updating subscription:', updateError);
        return handleError(Errors.databaseError());
      }

      subscription = updated;
    } else {
      // Create new subscription
      const { data: created, error: createError } = await adminClient
        .from('alert_subscriptions')
        .insert({
          user_id: profileId,
          mountain_id: mountainId,
          weather_alerts: weatherAlerts,
          powder_alerts: powderAlerts,
          powder_threshold: powderThreshold,
        })
        .select()
        .single();

      if (createError) {
        console.error('Error creating subscription:', createError);
        return handleError(Errors.databaseError());
      }

      subscription = created;
    }

    return NextResponse.json({ subscription }, { status: existing ? 200 : 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/alerts/subscriptions' });
  }
});

/**
 * DELETE /api/alerts/subscriptions
 *
 * Delete an alert subscription
 * Query params:
 *   - mountainId: Mountain ID (required)
 */
export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    const adminClient = createAdminClient();
    const { searchParams } = new URL(request.url);

    const profileId = await getProfileId(authUser.userId);
    if (!profileId) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    const mountainId = searchParams.get('mountainId');

    if (!mountainId) {
      return handleError(Errors.missingField('mountainId'));
    }

    const { error: deleteError } = await adminClient
      .from('alert_subscriptions')
      .delete()
      .eq('user_id', profileId)
      .eq('mountain_id', mountainId);

    if (deleteError) {
      console.error('Error deleting subscription:', deleteError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/alerts/subscriptions' });
  }
});
