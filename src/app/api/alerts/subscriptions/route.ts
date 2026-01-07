import { NextResponse } from 'next/server';
import { createClient } from '@/lib/supabase/server';

/**
 * GET /api/alerts/subscriptions
 *
 * Fetch alert subscriptions for the current user
 * Query params:
 *   - mountainId: Filter by mountain (optional)
 */
export async function GET(request: Request) {
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

    const { searchParams } = new URL(request.url);
    const mountainId = searchParams.get('mountainId');

    // Build query
    let query = supabase
      .from('alert_subscriptions')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (mountainId) {
      query = query.eq('mountain_id', mountainId);
    }

    const { data: subscriptions, error } = await query;

    if (error) {
      console.error('Error fetching subscriptions:', error);
      return NextResponse.json(
        { error: 'Failed to fetch subscriptions' },
        { status: 500 }
      );
    }

    return NextResponse.json({ subscriptions: subscriptions || [] });
  } catch (error) {
    console.error('Error in GET /api/alerts/subscriptions:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

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

    const body = await request.json();
    const {
      mountainId,
      weatherAlerts = true,
      powderAlerts = true,
      powderThreshold = 6,
    } = body;

    // Validate required fields
    if (!mountainId) {
      return NextResponse.json(
        { error: 'Mountain ID is required' },
        { status: 400 }
      );
    }

    // Validate powder threshold
    if (powderThreshold < 0 || powderThreshold > 100) {
      return NextResponse.json(
        { error: 'Powder threshold must be between 0 and 100 inches' },
        { status: 400 }
      );
    }

    // Check if subscription already exists
    const { data: existing } = await supabase
      .from('alert_subscriptions')
      .select('id')
      .eq('user_id', user.id)
      .eq('mountain_id', mountainId)
      .maybeSingle();

    let subscription;

    if (existing) {
      // Update existing subscription
      const { data: updated, error: updateError } = await supabase
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
        return NextResponse.json(
          { error: 'Failed to update subscription' },
          { status: 500 }
        );
      }

      subscription = updated;
    } else {
      // Create new subscription
      const { data: created, error: createError } = await supabase
        .from('alert_subscriptions')
        .insert({
          user_id: user.id,
          mountain_id: mountainId,
          weather_alerts: weatherAlerts,
          powder_alerts: powderAlerts,
          powder_threshold: powderThreshold,
        })
        .select()
        .single();

      if (createError) {
        console.error('Error creating subscription:', createError);
        return NextResponse.json(
          { error: 'Failed to create subscription' },
          { status: 500 }
        );
      }

      subscription = created;
    }

    return NextResponse.json({ subscription }, { status: existing ? 200 : 201 });
  } catch (error) {
    console.error('Error in POST /api/alerts/subscriptions:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/alerts/subscriptions
 *
 * Delete an alert subscription
 * Query params:
 *   - mountainId: Mountain ID (required)
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

    const { searchParams } = new URL(request.url);
    const mountainId = searchParams.get('mountainId');

    if (!mountainId) {
      return NextResponse.json(
        { error: 'Mountain ID is required' },
        { status: 400 }
      );
    }

    const { error: deleteError } = await supabase
      .from('alert_subscriptions')
      .delete()
      .eq('user_id', user.id)
      .eq('mountain_id', mountainId);

    if (deleteError) {
      console.error('Error deleting subscription:', deleteError);
      return NextResponse.json(
        { error: 'Failed to delete subscription' },
        { status: 500 }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('Error in DELETE /api/alerts/subscriptions:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}
