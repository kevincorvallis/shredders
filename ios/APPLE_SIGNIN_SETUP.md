# Sign in with Apple Setup Guide

## ✅ Already Completed (in code)

1. **iOS App**:
   - ✅ Added Sign in with Apple capability to `PowderTracker.entitlements`
   - ✅ Created `SignInWithAppleButton` view component
   - ✅ Updated `AuthService` with `signInWithApple()` method
   - ✅ Added Apple sign-in button to LoginView and SignupView
   - ✅ Implemented secure nonce generation and SHA256 hashing
   - ✅ Auto-creates user profile for new Apple sign-in users

## 📋 Required: Supabase Dashboard Configuration

You need to configure Supabase to accept Apple OAuth:

### 1. Enable Apple Provider in Supabase

1. Go to https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe
2. Navigate to **Authentication** → **Providers**
3. Find **Apple** in the provider list
4. Toggle **Enable Sign in with Apple**

### 2. Configure Apple Provider Settings

You'll need to set these values from Apple Developer:

**Required fields:**
- **Services ID** (from Apple Developer Console)
- **Team ID** (from Apple Developer Console)
- **Key ID** (from Apple Developer Console)
- **Private Key** (from Apple Developer Console - .p8 file)

### 3. Get Apple Credentials

#### A. Create an App ID
1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Click **+** to create new identifier
3. Select **App IDs** → Continue
4. Select **App** → Continue
5. Description: "PowderTracker"
6. Bundle ID: `com.shredders.powdertracker` (Explicit)
7. Capabilities: Check **Sign In with Apple**
8. Click **Continue** → **Register**

#### B. Create a Services ID
1. In Apple Developer, click **+** to create new identifier
2. Select **Services IDs** → Continue
3. Description: "PowderTracker Web Auth"
4. Identifier: `com.shredders.powdertracker.signin` (or your choice)
5. Check **Sign In with Apple**
6. Click **Configure**
7. Primary App ID: Select the App ID you just created
8. Website URLs:
   - Domains: `nmkavdrvgjkolreoexfe.supabase.co`
   - Return URLs: `https://nmkavdrvgjkolreoexfe.supabase.co/auth/v1/callback`
9. Click **Save** → **Continue** → **Register**
10. **Copy the Services ID** - you'll need this for Supabase

#### C. Create a Key
1. In Apple Developer, go to **Keys** section
2. Click **+** to create a new key
3. Key Name: "PowderTracker Supabase Auth"
4. Check **Sign In with Apple**
5. Click **Configure**
6. Primary App ID: Select your App ID
7. Click **Save** → **Continue** → **Register**
8. **Download the .p8 key file** (you can only download once!)
9. **Copy the Key ID** shown on the confirmation page

#### D. Get Your Team ID
1. Go to https://developer.apple.com/account
2. Look for **Team ID** in the Membership section (10 characters, like `ABCD123456`)

### 4. Enter Credentials in Supabase

Back in Supabase Dashboard:

1. **Services ID**: Paste the Services ID from step B.10
2. **Team ID**: Paste your Team ID from step D.2
3. **Key ID**: Paste the Key ID from step C.9
4. **Private Key**: Open the .p8 file in a text editor and paste the entire contents (including BEGIN/END lines)
5. Click **Save**

### 5. Configure Redirect URL (Optional)

If you want Apple sign-in to work on the web app too:

1. In your Next.js app, update environment variables:
   ```bash
   NEXT_PUBLIC_APPLE_REDIRECT_URI=https://nmkavdrvgjkolreoexfe.supabase.co/auth/v1/callback
   ```

2. Add Apple sign-in button to web login page (similar to iOS implementation)

## 🧪 Testing

### Simulator Testing (Requires Setup)

**Common Error:** `Authorization failed: Error Domain=AKAuthenticationError Code=-7026`

This happens because the simulator needs a signed-in Apple ID:

1. **In iOS Simulator**: Settings → Sign in to your iPhone
2. Sign in with your Apple ID (can be a test account)
3. Now the "Sign in with Apple" button will work

**Note:** Simulator may still fail if Supabase Apple provider isn't configured yet.

### Device Testing (Recommended)

1. Build and run on a **physical iPhone/iPad**
2. Tap "Sign In"
3. Tap the "Sign in with Apple" button
4. Authenticate with Face ID/Touch ID
5. The app should:
   - Create a Supabase auth session
   - Auto-create a user profile in the `users` table
   - Navigate to the home screen

### Testing Before Supabase Configuration

If you get `Error Code=1000` or authentication errors:
- This is **expected** until you complete the Supabase configuration (steps 1-4 above)
- The app code is ready, but Supabase needs to accept Apple OAuth
- Follow the configuration steps, then test again

## 🔍 Troubleshooting

**Error: "Invalid client"**
- Check that your Services ID matches exactly what you entered in Supabase
- Verify the redirect URL is correct: `https://nmkavdrvgjkolreoexfe.supabase.co/auth/v1/callback`

**Error: "Invalid token"**
- Verify the .p8 private key was pasted correctly (including BEGIN/END lines)
- Check that the Key ID matches the key you created

**Error: "Team not found"**
- Verify your Team ID is correct (10 characters)
- Make sure you're using the Apple Developer account that owns the app

**Profile not created**
- Check Supabase logs for errors
- Verify the `users` table exists and has correct RLS policies
- Check that the username generation logic handles cases where email is not provided

## 📱 Production Checklist

Before App Store submission:

- [ ] Test Sign in with Apple on a physical device
- [ ] Verify "Sign in with Apple" button follows Apple's design guidelines
- [ ] Test account deletion flow (Apple requires this)
- [ ] Add "Delete Account" option in Settings
- [ ] Test with multiple Apple IDs
- [ ] Verify email/name are properly requested and used
- [ ] Test "Hide My Email" feature (Apple's privacy feature)

## 🔐 Security Notes

- **Nonce**: A random string is generated for each sign-in attempt and hashed with SHA256 before sending to Apple
- **ID Token**: Apple returns a JWT token that's verified by Supabase
- **User Data**: Only email and full name are requested (minimal permissions)
- **Profile Creation**: Automatically creates a username from email or generates one from user ID
