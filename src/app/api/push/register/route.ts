import { NextResponse } from 'next/server';
import { createClient, createAdminClient } from '@/lib/supabase/server';

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
export async function POST(request: Request) {
  try {
    const supabase = await createClient();

    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Look up internal user profile ID
    const adminClient = createAdminClient();
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', user.id)
      .single();

    if (!userProfile) {
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 401 }
      );
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
      return NextResponse.json(
        { error: 'Device token, platform, and device ID are required' },
        { status: 400 }
      );
    }

    // Validate platform
    if (!['ios', 'web'].includes(platform)) {
      return NextResponse.json(
        { error: 'Platform must be "ios" or "web"' },
        { status: 400 }
      );
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
        return NextResponse.json(
          { error: 'Failed to update device token' },
          { status: 500 }
        );
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
        return NextResponse.json(
          { error: 'Failed to register device token' },
          { status: 500 }
        );
      }

      token = created;
    }

    return NextResponse.json({ token }, { status: existing ? 200 : 201 });
  } catch (error) {
    console.error('Error in POST /api/push/register:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/push/register
 *
 * Unregister a device token (mark as inactive)
 * Query params:
 *   - deviceId: Device ID (required)
 */
export async function DELETE(request: Request) {
  try {
    const supabase = await createClient();

    // Check authentication
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json(
        { error: 'Not authenticated' },
        { status: 401 }
      );
    }

    // Look up internal user profile ID
    const adminClient = createAdminClient();
    const { data: userProfile } = await adminClient
      .from('users')
      .select('id')
      .eq('auth_user_id', user.id)
      .single();

    if (!userProfile) {
      return NextResponse.json(
        { error: 'User profile not found' },
        { status: 401 }
      );
    }

    const { searchParams } = new URL(request.url);
    const deviceId = searchParams.get('deviceId');

    if (!deviceId) {
      return NextResponse.json(
        { error: 'Device ID is required' },
        { status: 400 }
      );
    }

    // Mark token as inactive instead of deleting
    const { error: updateError } = await adminClient
      .from('push_notification_tokens')
      .update({ is_active: false })
      .eq('user_id', userProfile.id)
      .eq('device_id', deviceId);

    if (updateError) {
      console.error('Error deactivating token:', updateError);
      return NextResponse.json(
        { error: 'Failed to unregister device token' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error in DELETE /api/push/register:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
