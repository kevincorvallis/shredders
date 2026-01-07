# Photo Upload Setup Guide

## ✅ Already Completed (in code)

1. **Backend API Routes**:
   - ✅ `POST /api/photos/upload` - Upload photos to Supabase Storage
   - ✅ `GET /api/mountains/[mountainId]/photos` - Fetch photos for a mountain
   - ✅ `GET /api/photos/[photoId]` - Get specific photo
   - ✅ `DELETE /api/photos/[photoId]` - Delete photo (owner only)

2. **Web Components**:
   - ✅ `PhotoUploadModal` - Upload modal with file picker and preview
   - ✅ `PhotoGrid` - Display grid of photos
   - ✅ `PhotoCard` - Individual photo card with like/comment counts

3. **Database Schema**:
   - ✅ `user_photos` table already exists (from earlier setup)
   - ✅ RLS policies ready in schema

## 📋 Required: Supabase Storage Bucket Setup

You need to create the storage bucket in Supabase:

### Option 1: Via Supabase Dashboard (Easiest)

1. Go to https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe
2. Click **Storage** in the left sidebar
3. Click **Create a new bucket**
4. Configure the bucket:
   - **Name**: `user-photos`
   - **Public bucket**: ✅ **Enabled** (photos are publicly viewable)
   - **File size limit**: `5242880` (5MB)
   - **Allowed MIME types**: `image/jpeg, image/png, image/webp, image/heic`
5. Click **Create bucket**

### Option 2: Via SQL Editor (Advanced)

1. Go to **SQL Editor** in Supabase Dashboard
2. Create a new query
3. Copy and paste the contents of `/scripts/setup-storage-bucket.sql`
4. Click **Run**

The SQL file creates:
- Storage bucket with size limit and MIME type restrictions
- RLS policies for viewing, uploading, updating, and deleting photos
- User-specific folder structure (`users/{user-id}/photos/...`)

### Verify Setup

After creating the bucket, verify:

1. Go to **Storage** → **user-photos**
2. Check **Policies** tab - should see 4 policies:
   - ✅ Anyone can view photos
   - ✅ Authenticated users can upload
   - ✅ Users can update their own photos
   - ✅ Users can delete their own photos

## 🎨 Adding Photo Upload to Web Pages

### Example: Add to Webcam Page

```tsx
import { PhotoUploadModal } from '@/components/photos/PhotoUploadModal';
import { PhotoGrid } from '@/components/photos/PhotoGrid';
import { useState } from 'react';

function WebcamPage({ mountainId, webcamId }) {
  const [showUpload, setShowUpload] = useState(false);

  return (
    <div>
      {/* Your existing webcam content */}

      {/* Add upload button */}
      <button onClick={() => setShowUpload(true)}>
        Upload Photo
      </button>

      {/* Photo grid */}
      <PhotoGrid mountainId={mountainId} webcamId={webcamId} />

      {/* Upload modal */}
      {showUpload && (
        <PhotoUploadModal
          mountainId={mountainId}
          webcamId={webcamId}
          onClose={() => setShowUpload(false)}
          onUploadComplete={() => {
            // Refresh photo grid
            setShowUpload(false);
          }}
        />
      )}
    </div>
  );
}
```

### Example: Add to Mountain Detail Page

```tsx
import { PhotoGrid } from '@/components/photos/PhotoGrid';

function MountainPage({ mountainId }) {
  return (
    <div>
      {/* Existing mountain info */}

      {/* All photos for this mountain */}
      <section>
        <h2>Recent Photos</h2>
        <PhotoGrid mountainId={mountainId} />
      </section>
    </div>
  );
}
```

## 🔒 Security Features

### Storage RLS Policies

**View**: Anyone can view photos (bucket is public)
- Allows all users to see photos without authentication
- Good for social sharing and discovery

**Upload**: Only authenticated users
- Must be logged in to upload
- Files are stored in `users/{user-id}/` folder structure
- Prevents anonymous uploads

**Update/Delete**: Owner only
- Users can only modify their own photos
- Folder structure enforces ownership (`users/{user-id}/...`)

### API Route Protection

- Upload route checks `auth.getUser()` - must be authenticated
- Delete route verifies ownership before allowing deletion
- File size validated (5MB limit)
- MIME type validated (images only)

## 📱 User Experience

### Upload Flow

1. User clicks "Upload Photo" button
2. Modal opens with drag-and-drop file picker
3. User selects image (validated: type, size)
4. Preview shown with caption input
5. User adds optional caption
6. Clicks "Upload" - progress shown
7. Photo uploaded to Storage + record created in DB
8. Modal closes, grid refreshes with new photo

### Photo Display

- Grid layout (1-3 columns based on screen size)
- Each card shows:
  - Photo image
  - User avatar and name (links to profile)
  - Caption (if provided)
  - Like and comment counts
  - Upload date
  - Delete button (for photo owner only)

## 🧪 Testing

1. **Test Upload**:
   - Sign in to the app
   - Navigate to a webcam or mountain page
   - Click upload button
   - Select an image file
   - Add caption (optional)
   - Upload and verify it appears in grid

2. **Test Viewing**:
   - View photos without being logged in
   - Should see all approved photos
   - Can't upload without authentication

3. **Test Delete**:
   - Upload a photo while logged in
   - See delete button on your photos
   - Don't see delete button on others' photos
   - Delete your photo and verify it's removed

## 🐛 Troubleshooting

**Error: "bucket 'user-photos' not found"**
- You haven't created the storage bucket yet
- Follow the setup steps above in Supabase Dashboard

**Error: "new row violates row-level security policy"**
- RLS policies haven't been created
- Run the SQL in `/scripts/setup-storage-bucket.sql`

**Error: "File too large"**
- Image is over 5MB
- Compress the image or choose a smaller file

**Error: "Invalid file type"**
- File is not an image
- Only JPEG, PNG, WebP, and HEIC are allowed

**Photos not appearing**:
- Check browser console for errors
- Verify API route is working: `/api/mountains/[id]/photos`
- Check Supabase Storage dashboard to see if files uploaded

## 🚀 Next Steps

After setting up photos:

1. **Test the upload flow** thoroughly
2. **Add photo upload buttons** to webcam and mountain pages
3. **Integrate comments** (Phase 3) - users can comment on photos
4. **Add likes** (Phase 3) - users can like photos
5. **iOS photo upload** (Phase 2.4) - native camera integration

## 📝 Notes

- Photos are stored in Supabase Storage (like S3 but built-in)
- Public URLs are generated automatically
- Thumbnail generation can be added later (optional)
- Photo moderation via `is_approved` flag (currently auto-approved)
- File structure: `{user-id}/{mountain-id}/{timestamp}-{random}.{ext}`
