/**
 * POST /api/photos/upload
 *
 * Upload a photo to Supabase Storage and create database record
 */

import { createClient, createAdminClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

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

    // Parse multipart form data
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const mountainId = formData.get('mountainId') as string;
    const webcamId = formData.get('webcamId') as string | null;
    const caption = formData.get('caption') as string | null;
    const takenAt = formData.get('takenAt') as string | null;

    if (!file) {
      return handleError(Errors.missingField('file'));
    }

    if (!mountainId) {
      return handleError(Errors.missingField('mountainId'));
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
    const fileName = `${authUser.userId}/${mountainId}/${timestamp}-${randomStr}.${fileExt}`;

    // Use user-scoped client for storage (RLS on bucket) if Supabase auth, otherwise admin
    const storageClient = authUser.authMethod === 'supabase'
      ? await createClient()
      : adminClient;

    // Upload to Supabase Storage
    const { data: uploadData, error: uploadError } = await storageClient.storage
      .from('user-photos')
      .upload(fileName, file, {
        contentType: file.type,
        cacheControl: '3600',
        upsert: false,
      });

    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      return handleError(Errors.internalError('Failed to upload photo'));
    }

    // Get public URL
    const {
      data: { publicUrl },
    } = storageClient.storage.from('user-photos').getPublicUrl(fileName);

    // Create database record
    const { data: photoRecord, error: dbError } = await adminClient
      .from('user_photos')
      .insert({
        user_id: userProfile.id,
        mountain_id: mountainId,
        webcam_id: webcamId,
        storage_path: fileName,
        url: publicUrl,
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
      await storageClient.storage.from('user-photos').remove([fileName]);
      return handleError(Errors.databaseError());
    }

    return NextResponse.json({
      photo: photoRecord,
      message: 'Photo uploaded successfully',
    });
  } catch (error) {
    return handleError(error, { endpoint: 'POST /api/photos/upload' });
  }
});
