# iOS Photo Upload Implementation Guide

## ✅ Implementation Complete

### Files Created

**Models:**
- `Photo.swift` - Photo data model with user info
- Codable structure matching Supabase database schema

**Services:**
- `PhotoService.swift` - Upload, fetch, and delete photos
  - Compresses images to JPEG (80% quality)
  - Validates file size (5MB limit)
  - Upload progress tracking
  - Supabase Storage integration

**Views:**
- `PhotoUploadView.swift` - Camera and photo library picker
  - Native camera integration
  - PhotosPicker for library selection
  - Image preview and caption input
  - Progress indicator during upload
- `PhotoGridView.swift` - Responsive photo grid (3 columns)
  - Loading states
  - Empty state messaging
  - Error handling with retry
- `PhotoCardView.swift` - Individual photo display
  - User avatar and name
  - Like/comment counts
  - Delete option (owner only)
  - Async image loading

**Permissions:**
- `Info.plist` updated with camera and photo library usage descriptions

## 📱 How to Use in Your App

### 1. Add Photo Upload Button

In any view (webcams, mountain details, etc.):

```swift
import SwiftUI

struct WebcamView: View {
    let mountainId: String
    let webcamId: String

    @State private var showingUpload = false

    var body: some View {
        VStack {
            // Your existing webcam content

            Button {
                showingUpload = true
            } label: {
                Label("Upload Photo", systemImage: "camera.fill")
            }
            .sheet(isPresented: $showingUpload) {
                PhotoUploadView(mountainId: mountainId, webcamId: webcamId)
            }
        }
    }
}
```

### 2. Display Photo Grid

Show all photos for a mountain or webcam:

```swift
import SwiftUI

struct MountainPhotosView: View {
    let mountainId: String

    var body: some View {
        VStack {
            Text("Community Photos")
                .font(.title2)
                .fontWeight(.bold)

            PhotoGridView(mountainId: mountainId, webcamId: nil)
        }
    }
}
```

### 3. Example Integration with Webcams

```swift
struct WebcamsView: View {
    @State private var showingPhotos = false
    @State private var showingUpload = false

    var body: some View {
        VStack {
            // Webcam content

            HStack {
                Button("View Photos") {
                    showingPhotos = true
                }

                Button("Upload Photo") {
                    showingUpload = true
                }
            }
        }
        .sheet(isPresented: $showingPhotos) {
            PhotoGridView(mountainId: "baker", webcamId: "summit-cam")
        }
        .sheet(isPresented: $showingUpload) {
            PhotoUploadView(mountainId: "baker", webcamId: "summit-cam")
        }
    }
}
```

## 🎨 User Experience

### Upload Flow

1. User taps "Upload Photo" button
2. Modal sheet presents two options:
   - **Take Photo** - Opens camera
   - **Choose from Library** - Opens Photos app picker
3. User selects/takes photo
4. Preview shown with optional caption field
5. User taps "Upload" in navigation bar
6. Progress bar shows upload status (0-100%)
7. Photo uploaded to Supabase Storage
8. Database record created
9. Sheet dismisses automatically

### Photo Display

- **Grid Layout**: 3 columns of square photos
- **Photo Card**: Shows image, user, caption, likes/comments
- **Owner Actions**: Delete button (with confirmation)
- **Loading**: Skeleton loader while fetching
- **Empty State**: Friendly message when no photos
- **Error State**: Error message with retry button

## 🔒 Permissions Required

The app automatically requests these permissions:

**Camera** (`NSCameraUsageDescription`):
- Requested when user taps "Take Photo"
- Description: "Take photos of mountain conditions to share with the community."

**Photo Library** (`NSPhotoLibraryUsageDescription`):
- Requested when user taps "Choose from Library"
- Description: "Choose photos from your library to share mountain conditions with the community."

Users must grant permission before they can upload photos.

## 🔐 Security & Validation

### Client-Side Validation

- ✅ Image compression (80% JPEG quality)
- ✅ File size check (5MB maximum)
- ✅ Authentication check (must be logged in)
- ✅ Preview before upload

### Server-Side Validation

- ✅ File type validation (images only)
- ✅ File size limit enforcement
- ✅ User authentication required
- ✅ Owner verification for delete

### Storage Structure

Photos are stored in Supabase Storage:
```
user-photos/
  {user-id}/
    {mountain-id}/
      {timestamp}-{random}.jpg
```

This structure:
- Organizes photos by user and mountain
- Prevents filename conflicts
- Makes it easy to find/delete user's photos
- Enforces ownership via Supabase RLS

## 📊 Features

### Implemented

✅ Camera capture
✅ Photo library selection
✅ Image compression
✅ Caption input
✅ Upload progress tracking
✅ Photo grid display
✅ Async image loading
✅ Owner-only delete
✅ Like/comment counts display
✅ User profile links

### Future Enhancements (Optional)

- [ ] Thumbnail generation
- [ ] Photo editing (crop, filter, rotate)
- [ ] Multiple photo upload
- [ ] Photo search/filter
- [ ] Photo reporting/moderation
- [ ] HEIC to JPEG conversion
- [ ] Photo metadata (location, exif data)

## 🧪 Testing Checklist

### Camera Upload

- [ ] Tap "Upload Photo" → "Take Photo"
- [ ] Camera permission requested (first time)
- [ ] Camera opens successfully
- [ ] Take photo
- [ ] Preview shows correctly
- [ ] Add caption (optional)
- [ ] Upload completes
- [ ] Photo appears in grid

### Library Upload

- [ ] Tap "Upload Photo" → "Choose from Library"
- [ ] Photo library permission requested (first time)
- [ ] Photos app opens
- [ ] Select photo
- [ ] Preview shows correctly
- [ ] Add caption (optional)
- [ ] Upload completes
- [ ] Photo appears in grid

### Photo Display

- [ ] Grid shows 3 columns
- [ ] Photos load correctly
- [ ] User avatars and names display
- [ ] Like/comment counts shown
- [ ] Caption displays if present
- [ ] Empty state when no photos

### Delete

- [ ] Menu button appears on owned photos only
- [ ] Tap menu → Delete
- [ ] Confirmation dialog appears
- [ ] Confirm deletion
- [ ] Photo removed from grid
- [ ] Photo removed from storage

## 🐛 Troubleshooting

**Error: "bucket 'user-photos' not found"**
- You need to create the storage bucket in Supabase Dashboard
- See `/PHOTO_UPLOAD_SETUP.md` for instructions

**Camera doesn't open**
- Check Info.plist has `NSCameraUsageDescription`
- Verify user granted camera permission in Settings
- Test on physical device (simulator camera is limited)

**Photos not uploading**
- Check user is authenticated
- Verify Supabase URL and key in AppConfig.swift
- Check file size (must be under 5MB)
- Check network connection

**Photos not displaying**
- Verify storage bucket is public
- Check RLS policies allow SELECT
- Verify `is_approved` column is true (auto-approved by default)

**Delete not working**
- Verify ownership check (only owner can delete)
- Check RLS policy allows DELETE for owner
- Check Supabase Storage permissions

## 💡 Tips

1. **Test on Real Device**: Camera functionality requires a physical device
2. **Image Compression**: 80% JPEG quality balances size and quality well
3. **Progress Feedback**: Always show upload progress for better UX
4. **Error Messages**: Provide clear, actionable error messages
5. **Async Loading**: Use AsyncImage for automatic loading and caching

## 🚀 Next Steps

After implementing photo upload:

1. **Add to Navigation**: Add upload buttons to webcam and mountain pages
2. **Test Thoroughly**: Test both camera and library on real device
3. **Integrate Comments**: Users can comment on photos (Phase 3)
4. **Add Likes**: Users can like photos (Phase 3)
5. **Photo Details**: Tap photo to see full-size with all comments/likes

## 📝 Code Examples

### Simple Integration

```swift
// In WebcamsView or similar
@State private var showingUpload = false

var body: some View {
    VStack {
        // Existing content

        Button("Upload Photo") {
            showingUpload = true
        }
        .sheet(isPresented: $showingUpload) {
            PhotoUploadView(
                mountainId: selectedMountainId,
                webcamId: selectedWebcamId
            )
        }
    }
}
```

### With Photo Grid

```swift
struct CommunityPhotosSection: View {
    let mountainId: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Community Photos")
                .font(.title2)
                .fontWeight(.bold)

            PhotoGridView(mountainId: mountainId, webcamId: nil)
                .frame(height: 400)
        }
        .padding()
    }
}
```

The iOS photo upload system is now complete and ready to use!
