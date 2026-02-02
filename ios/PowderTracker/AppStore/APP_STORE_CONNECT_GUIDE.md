# App Store Connect Setup Guide - PowderTracker

Complete step-by-step guide to publishing PowderTracker on the App Store.

---

## Prerequisites Checklist

Before starting, ensure you have:

- [x] Apple Developer Account ($99/year)
- [x] App archive created (see Archives/ folder)
- [x] App icons in all required sizes
- [x] Screenshots for iPhone 6.7" and iPad 12.9"
- [x] Privacy policy URL
- [x] Support URL
- [ ] Apple Distribution certificate (need to create if not present)
- [ ] App Store provisioning profile

---

## Step 1: Create Apple Distribution Certificate (if needed)

Your current signing identity is **Apple Development**. For App Store submission, you need **Apple Distribution**.

1. Go to [Apple Developer Portal](https://developer.apple.com/account/resources/certificates/list)
2. Click the **+** button to create a new certificate
3. Select **Apple Distribution**
4. Follow the CSR creation steps in Keychain Access
5. Download and install the certificate

---

## Step 2: Create App Store Connect Listing

### 2.1 Create New App

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platforms:** iOS
   - **Name:** PowderTracker
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** com.shredders.powdertracker
   - **SKU:** powdertracker-ios-2026 (any unique identifier)
   - **Full Access:** Select your user

### 2.2 App Information Tab

Navigate to **App Information** and fill in:

| Field | Value |
|-------|-------|
| Name | PowderTracker |
| Subtitle | Ski Conditions & Powder Alerts |
| Category | Weather (Primary), Sports (Secondary) |
| Content Rights | Check: Does not contain third-party content |

### 2.3 Pricing and Availability

1. Click **Pricing and Availability**
2. Set **Price:** Free
3. **Availability:** Available in all territories (or select specific)

---

## Step 3: Prepare Version 1.0.0

### 3.1 App Screenshots

Upload screenshots from `AppStore/Screenshots/`:

**iPhone 6.7" Display (Required)**
- Upload: `Screenshots/6.7-inch/*.png`
- Minimum 1, maximum 10 screenshots

**iPad Pro 12.9" Display (Required if iPad support)**
- Upload: `Screenshots/12.9-inch/*.png`

**Screenshot Specifications:**
| Device | Resolution | Format |
|--------|------------|--------|
| iPhone 6.7" | 1290 x 2796 | PNG or JPEG |
| iPad 12.9" | 2048 x 2732 | PNG or JPEG |

**To Capture Clean Screenshots:**

The location permission dialog appears on first app launch. To capture clean screenshots:

```bash
# 1. Set status bar to Apple's traditional 9:41 time
xcrun simctl status_bar "iPhone 16 Pro Max" override --time "9:41"

# 2. Launch the app
xcrun simctl launch "iPhone 16 Pro Max" com.shredders.powdertracker

# 3. In Simulator, tap "Allow While Using App" to dismiss the dialog

# 4. Take screenshots of each tab:
xcrun simctl io "iPhone 16 Pro Max" screenshot ~/Desktop/01_today.png
# Navigate to Mountains tab, then:
xcrun simctl io "iPhone 16 Pro Max" screenshot ~/Desktop/02_mountains.png
# Continue for each tab...

# Or use Cmd+S in Simulator to save to Desktop
```

**Recommended Screenshots:**
1. Today Dashboard - Shows powder scores and daily picks
2. Mountains List - Browse all resorts with conditions
3. Mountain Detail - Detailed conditions, forecast, lifts
4. Map View - Weather overlays (radar, snow, temperature)
5. Events - Trip planning and social features
6. Profile - User preferences and settings

### 3.2 App Description

Copy from `APP_STORE_METADATA.md`:

**Description (copy entire block):**
```
Chase powder like a pro with PowderTracker — your AI-powered guide to the best ski conditions across the Pacific Northwest.

REAL-TIME CONDITIONS
• Live snow depth, new snowfall, and temperature data for 27 ski resorts
• 8-factor Powder Score algorithm tells you exactly where to ski today
• Weather radar, snowfall maps, and wind overlays on an interactive map
• Lift status and trail conditions updated throughout the day

[... see APP_STORE_METADATA.md for full text ...]
```

**Keywords:**
```
ski,snow,powder,conditions,weather,mountain,resort,forecast,snowfall,skiing,snowboard,winter,alerts
```

**Promotional Text:**
```
Fresh powder at Stevens Pass! Check real-time conditions and 7-day forecasts for 27 PNW ski resorts. Plan trips, get alerts, and never miss a powder day.
```

**Support URL:**
```
https://shredders-bay.vercel.app/support
```

**Marketing URL:**
```
https://shredders-bay.vercel.app
```

### 3.3 What's New

```
Welcome to PowderTracker!

• Real-time conditions for 27 Pacific Northwest ski resorts
• 8-factor Powder Score to find the best skiing
• Interactive weather map with radar and snow overlays
• Trip planning with friends - create events, RSVP, share photos
• Smart powder alerts when fresh snow hits
• 7-day forecasts with hourly breakdowns
• Home screen widgets for quick access
• Dark mode support

Chase powder. Shred hard. Repeat.
```

### 3.4 App Review Information

**Contact Information:**
- First Name: Kevin
- Last Name: Lee
- Phone: [Your phone]
- Email: [Your email]

**Demo Account (if login required):**
- Username: reviewer@shredders.app
- Password: [Create a test account]

**Notes for Review:**
```
The app requires location permission to show nearby mountains, but functions fully without it by letting users browse all resorts manually.

Weather data comes from public government APIs (NOAA, SNOTEL) and free weather services (Open-Meteo, RainViewer).

Apple Sign In is the primary authentication method.
```

### 3.5 Version Release

- **Manually release this version** (recommended for first release)
- OR **Automatically release this version**

---

## Step 4: App Privacy

### 4.1 Privacy Policy

Enter URL: `https://shredders-bay.vercel.app/privacy`

### 4.2 Privacy Nutrition Labels

Click **Get Started** and answer:

**Do you or your third-party partners collect data from this app?**
→ Yes

**Data Types Collected:**

| Category | Data Type | Linked | Tracking |
|----------|-----------|--------|----------|
| Contact Info | Email Address | Yes | No |
| Identifiers | User ID | Yes | No |
| Location | Coarse Location | No | No |
| Diagnostics | Crash Data | No | No |
| Usage Data | Product Interaction | No | No |

**Purposes:**
- Email: App Functionality (account management)
- User ID: App Functionality
- Location: App Functionality (nearby mountains)
- Crash Data: Analytics
- Usage Data: Analytics

---

## Step 5: Upload Build

### Option A: Xcode Organizer (Recommended)

1. Open Xcode
2. **Window** → **Organizer** (⇧⌘O)
3. Select the PowderTracker archive
4. Click **Distribute App**
5. Select **App Store Connect**
6. Select **Upload** (not Export)
7. Follow prompts:
   - App Store Connect distribution options: ✓ Upload your app's symbols
   - Signing: Automatically manage signing
8. Wait for upload to complete

### Option B: Transporter App

1. First, export the archive to IPA:
```bash
cd /Users/kevin/Downloads/Projects/shredders/ios/PowderTracker

# Create ExportOptions.plist
cat > Archives/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>4F8Q446767</string>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
EOF

# Export IPA
xcodebuild -exportArchive \
    -archivePath Archives/PowderTracker_*.xcarchive \
    -exportPath Archives/Export \
    -exportOptionsPlist Archives/ExportOptions.plist
```

2. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784) from App Store
3. Sign in with your Apple ID
4. Drag the exported .ipa file to Transporter
5. Click **Deliver**

### Option C: Command Line (altool)

```bash
xcrun altool --upload-app \
    -f path/to/PowderTracker.ipa \
    -t ios \
    -u YOUR_APPLE_ID \
    -p YOUR_APP_SPECIFIC_PASSWORD
```

---

## Step 6: Submit for Review

1. Wait for build to process (5-30 minutes)
2. In App Store Connect, select the build under **Build**
3. Fill in any remaining required fields
4. Click **Add for Review**
5. Answer compliance questions:
   - **Export Compliance:** Yes, uses standard encryption (HTTPS only)
   - **Content Rights:** Yes, you own or have rights to all content
6. Click **Submit for Review**

---

## Step 7: Post-Submission

### Expected Timeline
- **Initial Review:** 24-48 hours (typically)
- **Extended Review:** Up to 7 days (rare)

### If Rejected
1. Read rejection message carefully
2. Common issues:
   - Missing privacy policy
   - Broken links
   - Crashes during review
   - Insufficient app functionality
3. Fix issues and resubmit

### After Approval
1. App will be live within 24 hours (if auto-release)
2. Monitor for crashes in App Store Connect
3. Respond to user reviews
4. Plan for version 1.0.1 based on feedback

---

## Quick Reference Files

| File | Purpose |
|------|---------|
| `AppStore/APP_STORE_METADATA.md` | All text content ready to copy |
| `AppStore/PRIVACY_POLICY.md` | Privacy policy content |
| `AppStore/Screenshots/6.7-inch/` | iPhone screenshots |
| `AppStore/Screenshots/12.9-inch/` | iPad screenshots |
| `Archives/PowderTracker_*.xcarchive` | Build archive |

---

## Checklist

- [ ] Apple Distribution certificate created
- [ ] App Store Connect listing created
- [ ] Screenshots uploaded
- [ ] Description and keywords entered
- [ ] Privacy policy URL added
- [ ] Privacy labels completed
- [ ] Build uploaded
- [ ] Build selected for submission
- [ ] Compliance questions answered
- [ ] Submitted for review
- [ ] App approved and live!

---

*Last updated: January 30, 2026*
