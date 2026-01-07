# Testing Sign In with Apple - Quick Guide

## The Errors You're Seeing

```
MCPasscodeManager passcode set check is not supported on this device.
Authorization failed: Error Domain=AKAuthenticationError Code=-7026
ASAuthorizationController credential request failed with error: Code=1000
```

**These are normal!** They happen because:
1. The iOS Simulator doesn't have an Apple ID signed in
2. Supabase Apple OAuth provider hasn't been configured yet

## ✅ What Works Right Now

You can test the app using **email/password authentication** which is fully functional:

1. Run the app in simulator or device
2. Tap "Sign In" → Scroll past the Apple button
3. Use the email/password form below
4. Create an account or sign in

**Email/password auth is fully working** - the Supabase backend is configured and ready!

## 🍎 To Test Sign in with Apple

### Option 1: Simulator (Quick but Limited)

1. **In iOS Simulator menu**: Device → Erase All Content and Settings
2. **Open Settings app** in simulator
3. Tap "Sign in to your iPhone" at the top
4. Sign in with **any Apple ID** (your personal one or a test account)
5. Now run the app and try Sign in with Apple

**This will still fail until Supabase is configured** (see below), but it gets past the `-7026` error.

### Option 2: Physical Device (Recommended)

1. Connect your iPhone/iPad via cable
2. In Xcode, select your device from the target menu
3. Click Run (⌘R)
4. The device is already signed into iCloud, so it will work better
5. Try Sign in with Apple - it will show better error messages

**Note:** Still needs Supabase configuration to fully work.

## 🔧 To Fully Enable Sign in with Apple

You need to configure 2 things:

### 1. Apple Developer Console (5-10 minutes)

Create these 3 items at https://developer.apple.com/account:

**A. App ID**
- Identifier → App IDs → Create new
- Bundle ID: `com.shredders.powdertracker`
- Enable "Sign In with Apple" capability

**B. Services ID**
- Identifier → Services IDs → Create new
- Identifier: `com.shredders.powdertracker.signin`
- Configure domains: `nmkavdrvgjkolreoexfe.supabase.co`
- Return URL: `https://nmkavdrvgjkolreoexfe.supabase.co/auth/v1/callback`

**C. Key**
- Keys → Create new key
- Enable "Sign In with Apple"
- Download the .p8 file (you can only download once!)
- Save the Key ID shown

### 2. Supabase Dashboard (2 minutes)

1. Go to https://supabase.com/dashboard/project/nmkavdrvgjkolreoexfe
2. Authentication → Providers → Apple
3. Toggle **Enable**
4. Enter:
   - Services ID (from B above)
   - Team ID (from your Apple Developer account homepage)
   - Key ID (from C above)
   - Private Key (paste entire contents of .p8 file)
5. Click **Save**

## 🎯 Recommended Testing Order

1. **Start with email/password** (works now)
   - Test signup, login, logout
   - Test profile updates
   - Verify everything works

2. **Configure Apple Sign In later** (optional but nice to have)
   - Follow the setup guide when you're ready
   - It's a nice-to-have feature, not required

## 📱 Current Working Features

Without Sign in with Apple configured, you can test:

✅ Email/password signup
✅ Email/password login
✅ User profile creation
✅ Profile updates (display name, bio)
✅ Session persistence
✅ Logout functionality
✅ Profile view with stats
✅ Settings page

## 🐛 Ignore These Errors for Now

These are safe to ignore until you configure Apple Sign In:

- `MCPasscodeManager passcode set check is not supported`
- `AKAuthenticationError Code=-7026`
- `AuthorizationError Code=1000`

They don't affect email/password authentication or any other app functionality.

## 💡 Pro Tip

If you want to skip Sign in with Apple for now:

1. You can comment out the button in LoginView.swift and SignupView.swift
2. Or just scroll past it and use email/password
3. Add Apple Sign In later when you're ready to configure it

The email/password flow is production-ready and fully functional!
