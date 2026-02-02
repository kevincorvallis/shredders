# App Store Submission Checklist - PowderTracker

**Last Updated:** January 30, 2026

## Quick Status

| Item | Status |
|------|--------|
| App Icons | ✅ Ready |
| Screenshots | ✅ Ready |
| Metadata | ✅ Ready |
| Privacy Policy | ✅ Ready |
| Archive | ✅ Ready |
| Distribution Certificate | ⚠️ Need Apple Distribution cert |
| App Store Connect Listing | 🔲 Pending |

---

## App Icon - READY ✅

### Generated Files
All required iOS app icon sizes have been generated and are App Store compliant:

**iPhone:**
- 20pt (@2x, @3x) - Notifications
- 29pt (@2x, @3x) - Settings
- 40pt (@2x, @3x) - Spotlight
- 60pt (@2x, @3x) - App Icon

**iPad:**
- 20pt (@1x, @2x) - Notifications
- 29pt (@1x, @2x) - Settings
- 40pt (@1x, @2x) - Spotlight
- 76pt (@1x, @2x) - App Icon
- 83.5pt (@2x) - App Icon (iPad Pro)

**App Store:**
- 1024pt (@1x) - App Store Marketing Icon

### Technical Requirements - VERIFIED ✅
- [x] All icons are PNG format
- [x] RGB color space (sRGB)
- [x] NO alpha channel/transparency
- [x] Correct dimensions for each size
- [x] File sizes optimized
- [x] Icons are in AppIcon.appiconset
- [x] Contents.json properly configured

---

## App Store Submission Requirements

### 1. App Information - READY ✅

| Field | Value | Status |
|-------|-------|--------|
| App name | PowderTracker | ✅ |
| Subtitle | Ski Conditions & Powder Alerts | ✅ |
| Privacy policy URL | https://shredders-bay.vercel.app/privacy | ✅ |
| Support URL | https://shredders-bay.vercel.app/support | ✅ |
| Marketing URL | https://shredders-bay.vercel.app | ✅ |
| Primary Category | Weather | ✅ |
| Secondary Category | Sports | ✅ |
| Age Rating | 4+ | ✅ |

**Files:** `ios/PowderTracker/AppStore/APP_STORE_METADATA.md`

### 2. App Screenshots - READY ✅

| Device | Resolution | Status |
|--------|------------|--------|
| iPhone 6.7" | 1290 x 2796 | ✅ Captured |
| iPad 12.9" | 2048 x 2732 | ✅ Captured |

**Files:** `ios/PowderTracker/AppStore/Screenshots/`

**To capture more screenshots:**
```bash
cd ios/PowderTracker
./scripts/capture_appstore_screenshots.sh
```

### 3. App Description - READY ✅

- [x] Description (~1,850 characters)
- [x] Keywords (97 characters)
- [x] Promotional text (156 characters)
- [x] What's new in this version

**Files:** `ios/PowderTracker/AppStore/APP_STORE_METADATA.md`

### 4. Build Requirements - READY ✅

- [x] Archive created (v1.0.0, build 1)
- [x] No compiler errors
- [x] No critical warnings
- [ ] Build uploaded to App Store Connect
- [ ] Build processed and ready
- [ ] Export compliance completed

**Archive location:** `ios/PowderTracker/Archives/`

**To create new archive:**
```bash
cd ios/PowderTracker
./scripts/archive_for_appstore.sh
```

### 5. App Privacy - READY ✅

- [x] PrivacyInfo.xcprivacy file included
- [x] Privacy policy written
- [x] Data collection practices documented
- [x] Third-party SDKs documented
- [ ] Privacy details filled in App Store Connect

**Files:**
- `ios/PowderTracker/PowderTracker/PrivacyInfo.xcprivacy`
- `ios/PowderTracker/AppStore/PRIVACY_POLICY.md`

**Data Collected:**
| Data Type | Linked | Tracking |
|-----------|--------|----------|
| Email | Yes | No |
| User ID | Yes | No |
| Coarse Location | No | No |
| Crash Data | No | No |
| Usage Data | No | No |

### 6. Version Information - READY ✅

- [x] Version number: 1.0.0
- [x] Build number: 1
- [x] Copyright: © 2026 Shredders
- [x] What's new written

### 7. Technical Requirements - READY ✅

- [x] App built with Xcode 26
- [x] Minimum iOS: 17.0
- [x] All device orientations work
- [x] App works on iPhone and iPad
- [x] No crash issues
- [x] Build succeeds without errors

---

## Signing Configuration

**Current Status:**
- ✅ Apple Development certificate: Kevin Lee (7YU96FM828)
- ⚠️ Apple Distribution certificate: **NEEDED**
- Team ID: 4F8Q446767
- Bundle ID: com.shredders.powdertracker

**To create Distribution certificate:**
1. Go to [developer.apple.com/account/resources/certificates](https://developer.apple.com/account/resources/certificates)
2. Click **+** to create new certificate
3. Select **Apple Distribution**
4. Follow CSR creation steps
5. Download and install

---

## Files Reference

```
ios/PowderTracker/
├── AppStore/
│   ├── APP_STORE_METADATA.md      # All text content
│   ├── PRIVACY_POLICY.md          # Privacy policy
│   ├── APP_STORE_CONNECT_GUIDE.md # Step-by-step guide
│   └── Screenshots/
│       ├── 6.7-inch/              # iPhone screenshots
│       └── 12.9-inch/             # iPad screenshots
├── Archives/
│   └── PowderTracker_*.xcarchive  # Build archive
└── scripts/
    ├── archive_for_appstore.sh    # Create archive
    └── capture_appstore_screenshots.sh
```

---

## Next Steps

1. **Create Apple Distribution certificate** (if not present)
2. **Open Xcode Organizer** (Cmd+Shift+O)
3. **Select archive** and click "Distribute App"
4. **Upload to App Store Connect**
5. **Complete listing** using `APP_STORE_CONNECT_GUIDE.md`
6. **Submit for review**

See `ios/PowderTracker/AppStore/APP_STORE_CONNECT_GUIDE.md` for detailed instructions.

---

## Notes

- Icons have been tested and verified to meet App Store requirements
- All icons are RGB with no transparency
- Design is optimized for visibility at all sizes
- Color palette works well in both light and dark mode
- Screenshots captured on iPhone 16 Pro Max and iPad Pro 13"
