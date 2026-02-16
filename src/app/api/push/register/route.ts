import { NextResponse } from 'next/server';
import { createAdminClient } from '@/lib/supabase/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/**
 * POST /api/push/register
 *
 * Register a device token for push notifications
 * Body:
 *   - deviceToken: APNs device token (required)
 *   - platform: Platform (ios or web) (required)
 *   - deviceId: Unique device identifier (required)
 *   - appVersion: App version (optional)
 *   - osVersion: OS version (optional)
 */
export const POST = withDualAuth(async (request, authUser) => {
  try {
    // Look up internal user profile ID
    const adminClient = createAdminClient();
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    const body = await request.json();
    const {
      deviceToken,
      platform,
      deviceId,
      appVersion,
      osVersion,
    } = body;

    // Validate required fields
    if (!deviceToken || !platform || !deviceId) {
      return handleError(Errors.validationFailed(['Device token, platform, and device ID are required']));
    }

    // Validate platform
    if (!['ios', 'web'].includes(platform)) {
      return handleError(Errors.validationFailed(['Platform must be "ios" or "web"']));
    }

    // Check if token already exists for this device
    const { data: existing } = await adminClient
      .from('push_notification_tokens')
      .select('id')
      .eq('user_id', userProfile.id)
      .eq('device_id', deviceId)
      .maybeSingle();

    let token;

    if (existing) {
      // Update existing token
      const { data: updated, error: updateError } = await adminClient
        .from('push_notification_tokens')
        .update({
          device_token: deviceToken,
          platform,
          app_version: appVersion || null,
          os_version: osVersion || null,
          is_active: true,
          last_used_at: new Date().toISOString(),
        })
        .eq('id', existing.id)
        .select()
        .single();

      if (updateError) {
        console.error('Error updating token:', updateError);
        return handleError(Errors.databaseError());
      }

      token = updated;
    } else {
      // Create new token
      const { data: created, error: createError } = await adminClient
        .from('push_notification_tokens')
        .insert({
          user_id: userProfile.id,
          device_token: deviceToken,
          platform,
          device_id: deviceId,
          app_version: appVersion || null,
          os_version: osVersion || null,
          is_active: true,
          last_used_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (createError) {
        console.error('Error creating token:', createError);
        return handleError(Errors.databaseError());
      }

      token = created;
    }

    return NextResponse.json({ token }, { status: existing ? 200 : 201 });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/push/register' });
  }
});

/**
 * DELETE /api/push/register
 *
 * Unregister a device token (mark as inactive)
 * Query params:
 *   - deviceId: Device ID (required)
 */
export const DELETE = withDualAuth(async (request, authUser) => {
  try {
    // Look up internal user profile ID
    const adminClient = createAdminClient();
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', authUser.userId)
      .single();

    if (!userProfile) {
      return handleError(Errors.unauthorized('User profile not found'));
    }

    const { searchParams } = new URL(request.url);
    const deviceId = searchParams.get('deviceId');

    if (!deviceId) {
      return handleError(Errors.missingField('deviceId'));
    }

    // Mark token as inactive instead of deleting
    const { error: updateError } = await adminClient
      .from('push_notification_tokens')
      .update({ is_active: false })
      .eq('user_id', userProfile.id)
      .eq('device_id', deviceId);

    if (updateError) {
      console.error('Error deactivating token:', updateError);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    return handleError(error, { endpoint: 'DELETE /api/push/register' });
  }
});
