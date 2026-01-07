/**
 * POST /api/photos/upload
 *
 * Upload a photo to Supabase Storage and create database record
 */

import { createClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const supabase = await createClient();

    // Check authentication
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      return NextResponse.json({ error: 'Not authenticated' }, { status: 401 });
    }

    // Parse multipart form data
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const mountainId = formData.get('mountainId') as string;
    const webcamId = formData.get('webcamId') as string | null;
    const caption = formData.get('caption') as string | null;
    const takenAt = formData.get('takenAt') as string | null;

    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }

    if (!mountainId) {
      return NextResponse.json({ error: 'Mountain ID required' }, { status: 400 });
    }

    // Validate file type
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { error: 'Invalid file type. Only JPEG, PNG, WebP, and HEIC are allowed.' },
        { status: 400 }
      );
    }

    // Validate file size (5MB)
    if (file.size > 5 * 1024 * 1024) {
      return NextResponse.json(
        { error: 'File too large. Maximum size is 5MB.' },
        { status: 400 }
      );
    }

    // Generate unique filename
    const fileExt = file.name.split('.').pop();
    const timestamp = Date.now();
    const randomStr = Math.random().toString(36).substring(7);
    const fileName = `${user.id}/${mountainId}/${timestamp}-${randomStr}.${fileExt}`;

    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await supabase.storage
      .from('user-photos')
      .upload(fileName, file, {
        contentType: file.type,
        cacheControl: '3600',
        upsert: false,
      });

    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      return NextResponse.json({ error: uploadError.message }, { status: 500 });
    }

    // Get public URL
    const {
      data: { publicUrl },
    } = supabase.storage.from('user-photos').getPublicUrl(fileName);

    // Create database record
    const { data: photoRecord, error: dbError } = await supabase
      .from('user_photos')
      .insert({
        user_id: user.id,
        mountain_id: mountainId,
        webcam_id: webcamId,
        s3_key: fileName,
        s3_bucket: 'user-photos',
        cloudfront_url: publicUrl,
        thumbnail_url: publicUrl, // TODO: Generate thumbnail
        caption: caption || null,
        taken_at: takenAt || new Date().toISOString(),
        file_size_bytes: file.size,
        mime_type: file.type,
      })
      .select()
      .single();

    if (dbError) {
      console.error('Database insert error:', dbError);
      // Clean up uploaded file
      await supabase.storage.from('user-photos').remove([fileName]);
      return NextResponse.json({ error: dbError.message }, { status: 500 });
    }

    return NextResponse.json({
      photo: photoRecord,
      message: 'Photo uploaded successfully',
    });
  } catch (error: any) {
    console.error('Photo upload error:', error);
    return NextResponse.json(
      { error: error.message || 'Internal server error' },
      { status: 500 }
    );
  }
}
