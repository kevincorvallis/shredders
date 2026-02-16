/**
 * POST /api/photos/upload
 *
 * Upload a photo to Supabase Storage and create database record
 */

import { createClient, createAdminClient } from '@/lib/supabase/server';
import { NextResponse } from 'next/server';
import { withDualAuth } from '@/lib/auth';
import { Errors, handleError } from '@/lib/errors';

/** Detect image type from magic bytes. Returns null if not a recognized image. */
function detectImageType(header: Uint8Array): { mime: string; ext: string } | null {
  // JPEG: FF D8 FF
  if (header[0] === 0xff && header[1] === 0xd8 && header[2] === 0xff) {
    return { mime: 'image/jpeg', ext: 'jpg' };
  }
  // PNG: 89 50 4E 47
  if (header[0] === 0x89 && header[1] === 0x50 && header[2] === 0x4e && header[3] === 0x47) {
    return { mime: 'image/png', ext: 'png' };
  }
  // WebP: RIFF....WEBP
  if (
    header[0] === 0x52 && header[1] === 0x49 && header[2] === 0x46 && header[3] === 0x46 &&
    header[8] === 0x57 && header[9] === 0x45 && header[10] === 0x42 && header[11] === 0x50
  ) {
    return { mime: 'image/webp', ext: 'webp' };
  }
  // HEIC/HEIF: ....ftyp at offset 4
  if (header[4] === 0x66 && header[5] === 0x74 && header[6] === 0x79 && header[7] === 0x70) {
    return { mime: 'image/heic', ext: 'heic' };
  }
  return null;
}

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

    // Validate file size (5MB)
    if (file.size > 5 * 1024 * 1024) {
      return NextResponse.json(
        { error: 'File too large. Maximum size is 5MB.' },
        { status: 400 }
      );
    }

    // Validate file type by reading magic bytes, not trusting client MIME type
    const header = new Uint8Array(await file.slice(0, 12).arrayBuffer());
    const detectedType = detectImageType(header);
    if (!detectedType) {
      return NextResponse.json(
        { error: 'Invalid file type. Only JPEG, PNG, WebP, and HEIC are allowed.' },
        { status: 400 }
      );
    }

    // Sanitize mountainId for use in storage path (alphanumeric, hyphens, underscores only)
    const safeMountainId = mountainId.replace(/[^a-zA-Z0-9_-]/g, '');
    if (!safeMountainId) {
      return handleError(Errors.validationFailed(['Invalid mountainId']));
    }

    // Derive extension from validated type, not client filename
    const fileExt = detectedType.ext;
    const timestamp = Date.now();
    const randomStr = Math.random().toString(36).substring(7);
    const fileName = `${authUser.userId}/${safeMountainId}/${timestamp}-${randomStr}.${fileExt}`;

    // Use user-scoped client for storage (RLS on bucket) if Supabase auth, otherwise admin
    const storageClient = authUser.authMethod === 'supabase'
      ? await createClient()
      : adminClient;

    // Upload to Supabase Storage with validated content type
    const { data: uploadData, error: uploadError } = await storageClient.storage
      .from('user-photos')
      .upload(fileName, file, {
        contentType: detectedType.mime,
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
        mime_type: detectedType.mime,
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
