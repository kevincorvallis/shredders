# TestFlight Setup Guide for PowderTracker

## Prerequisites

- [ ] Apple Developer Program membership ($99/year)
- [ ] Xcode 15+ installed
- [ ] Signed in to your Apple ID in Xcode (Xcode → Settings → Accounts)

## App Store Connect Setup

### 1. Create App in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in the details:
   - **Platform**: iOS
   - **Name**: PowderTracker
   - **Primary Language**: English (US)
   - **Bundle ID**: `com.shredders.powdertracker`
   - **SKU**: `powdertracker`

### 2. Complete Required App Information

Before you can submit to TestFlight, you need:

- [ ] **Privacy Policy URL** - Required for all apps
- [ ] **App Icon** (1024x1024) - Already in Assets.xcassets
- [ ] **App Description** - Brief description of the app
- [ ] **Category** - Select "Sports" as primary

### 3. Configure Push Notifications (if using)

1. Go to [Apple Developer Portal](https://developer.apple.com) → Certificates, IDs & Profiles
2. Click **Keys** → **+** to create a new key
3. Enable **Apple Push Notifications service (APNs)**
4. Download the `.p8` key file (save it securely!)
5. Note the Key ID shown
6. Configure Supabase with APNs credentials

## Building for TestFlight

### Option A: Using Xcode (Recommended)

1. Open `PowderTracker.xcodeproj` in Xcode
2. Select **PowderTracker** scheme (not widget or tests)
3. Set destination to **Any iOS Device (arm64)**
4. Verify version/build numbers:
   - Select project → General → Version: `1.0.0`
   - Build: `1` (increment for each upload)
5. Go to **Product → Archive**
6. When complete, Organizer opens automatically
7. Click **Distribute App**
8. Select **App Store Connect** → **Upload**
9. Follow prompts (use automatic signing)

### Option B: Using Command Line

```bash
cd ios/PowderTracker

# Create archive only
./scripts/archive-for-testflight.sh

# Create archive and upload
./scripts/archive-for-testflight.sh --upload
```

## Post-Upload Steps

### 1. Wait for Processing

After upload, the build takes 5-15 minutes to process in App Store Connect.

### 2. Complete Export Compliance

When your build appears:
1. Click on the build number
2. Answer the encryption question:
   - If using only HTTPS: Select **No** (exempt)
   - The app uses standard HTTPS encryption only

### 3. Add Test Information

Go to **TestFlight** → **Test Information**:
- [ ] Beta App Description
- [ ] Feedback Email
- [ ] Contact Information

## Adding Testers

### Internal Testers (Team Members)

1. Go to **Users and Access** in App Store Connect
2. Add team members with **App Manager** or **Developer** role
3. In TestFlight, go to **Internal Testing** → **+** to add them
4. They'll receive an email invite immediately

### External Testers (Beta Testers)

1. In TestFlight, go to **External Testing**
2. Create a **New Group** (e.g., "Beta Testers")
3. Add testers by email OR create a **Public Link**

#### Public Link (Easiest)
1. Click your group → **Enable Public Link**
2. Share the link with testers
3. Up to 10,000 testers can join via public link

## Build Versioning

Each TestFlight upload must have a unique build number:

- **Version** (CFBundleShortVersionString): `1.0.0` - User-facing version
- **Build** (CFBundleVersion): `1`, `2`, `3`... - Increment for each upload

To increment build number:
1. In Xcode: Project → General → Build
2. Or edit project.pbxproj: `CURRENT_PROJECT_VERSION`

## Common Issues

### "Missing Compliance" Status
- Answer the export compliance question in App Store Connect
- Usually just "No" for standard HTTPS apps

### "Invalid Binary"
- Check for missing entitlements
- Verify provisioning profiles are up to date
- Ensure all required icons are present

### Upload Errors
- Make sure you're using the latest Xcode
- Try: Xcode → Settings → Accounts → Refresh provisioning profiles
- Check App Store Connect for any notices

## Capabilities Required

Your app uses these capabilities that must be enabled in the Developer Portal:

| Capability | Status | Notes |
|------------|--------|-------|
| Sign in with Apple | ✅ Enabled | Already in entitlements |
| Associated Domains | ✅ Enabled | For deep linking |
| WeatherKit | ✅ Enabled | For weather data |
| Push Notifications | ✅ Enabled | Just added to entitlements |

## Resources

- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Distributing Apps Using TestFlight](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)
