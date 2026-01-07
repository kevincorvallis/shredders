# Sign in with Apple - Setup & Troubleshooting Guide

## Current Errors

```
"Please sign in iCloud in settings to use Sign in with Apple"
MCPasscodeManager passcode set check is not supported on this device.
Authorization failed: Error Domain=AKAuthenticationError Code=-7026
ASAuthorizationController credential request failed
```

## Root Causes

1. **iOS Simulator not signed into iCloud** (most common)
2. **Bundle ID mismatch** between Xcode and Apple Developer Console
3. **Sign in with Apple capability not enabled** in Apple Developer Console
4. **Simulator limitations** for authentication testing

---

## ✅ Solution 1: Use Physical Device (RECOMMENDED)

Sign in with Apple **requires a physical device** for proper testing. Simulators have limited support.

### Steps:
1. Connect your iPhone/iPad via USB
2. In Xcode: Product → Destination → Your iPhone
3. Make sure the device is signed into iCloud:
   - Settings → [Your Name] → Make sure you're signed in
4. Build and run: Cmd+R
5. Test Sign in with Apple

---

## ✅ Solution 2: Configure Simulator iCloud (LIMITED SUPPORT)

If you must test on simulator:

### For iOS 15+ Simulators:
1. Open **Simulator** → **Settings**
2. Scroll down → **Sign in to your iPhone**
3. Enter your Apple ID credentials
4. **Important**: Use a real Apple ID, not a test account
5. Restart the simulator
6. Try Sign in with Apple again

### Limitations:
- Simulators don't fully support all Apple ID features
- Biometric authentication won't work
- Some authentication flows may fail randomly
- Physical devices are strongly recommended

---

## ✅ Solution 3: Verify Apple Developer Console Setup

### 1. Check App ID Configuration

Go to [Apple Developer Console](https://developer.apple.com/account/resources/identifiers/list):

1. Select your App ID: **com.shredders.powdertracker**
2. Verify **Sign in with Apple** capability is checked:
   - ✅ **Sign in with Apple** should be ENABLED
   - **Primary App ID**: Should be set (usually itself)
3. Click **Save** if you made changes
4. Wait 5-10 minutes for changes to propagate

### 2. Verify Bundle ID Matches

**In Xcode:**
1. Select PowderTracker target
2. General tab → Bundle Identifier: `com.shredders.powdertracker`

**In Apple Developer Console:**
1. App IDs → Find your app
2. Identifier should match: `com.shredders.powdertracker`

**If they don't match**, update Xcode to match Apple Developer Console.

---

## ✅ Solution 4: Add Development Fallback

Update the SignInWithAppleButton to detect simulator and show a helpful message:

### Detection Code:

```swift
#if targetEnvironment(simulator)
// Running on simulator - Sign in with Apple may not work
private var isSimulator: Bool { true }
#else
// Running on device
private var isSimulator: Bool { false }
#endif
```

I'll add this detection with a helpful message for users.

---

## ✅ Solution 5: Regenerate Provisioning Profile

Sometimes the provisioning profile doesn't include the Sign in with Apple entitlement:

### Steps:
1. In Xcode: PowderTracker target → Signing & Capabilities
2. **Uncheck** "Automatically manage signing"
3. **Check** "Automatically manage signing" again
4. This forces Xcode to regenerate the provisioning profile
5. Clean build folder: Cmd+Shift+K
6. Rebuild: Cmd+B

---

## Testing Checklist

Before testing Sign in with Apple:

### On Simulator:
- [ ] Simulator is running iOS 15 or later
- [ ] Simulator is signed into iCloud (Settings → Sign in)
- [ ] Using a real Apple ID (not test account)
- [ ] Bundle ID matches Apple Developer Console
- [ ] Sign in with Apple capability enabled in console
- [ ] **Note**: Simulator testing is unreliable

### On Physical Device (RECOMMENDED):
- [ ] Device is signed into iCloud (Settings → [Your Name])
- [ ] Device is connected to internet
- [ ] Bundle ID matches Apple Developer Console
- [ ] App is built and installed from Xcode (not TestFlight for first test)
- [ ] Sign in with Apple capability enabled in console
- [ ] Two-factor authentication is enabled on your Apple ID

---

## Error Code Reference

| Error Code | Meaning | Solution |
|------------|---------|----------|
| -7026 | AKAuthenticationError | Device not signed into iCloud, or bundle ID mismatch |
| 1000 | ASAuthorizationError.canceled | User cancelled - No action needed |
| 1001 | ASAuthorizationError.unknown | iCloud sign-in required, or simulator issue |
| 1004 | ASAuthorizationError.notHandled | Capability not configured properly |

---

## Quick Test Script

Test if Sign in with Apple is working:

```bash
# Check if app is properly signed
cd /Users/kevin/Downloads/shredders/ios/PowderTracker
codesign -d --entitlements - PowderTracker.app 2>/dev/null | grep -A 2 "apple"

# Expected output should include:
# <key>com.apple.developer.applesignin</key>
# <array>
#   <string>Default</string>
# </array>
```

---

## Recommended Development Workflow

### For Daily Development:
1. **Use email/password authentication** for quick testing
2. Sign in with Apple has strict requirements and doesn't work well on simulators

### For Sign in with Apple Testing:
1. **Use a physical iPhone/iPad** signed into iCloud
2. Test once per major change, not every build
3. Keep email/password as fallback option

---

## Alternative: Add Email/Password Fallback UI

Since Sign in with Apple is tricky during development, your app already has email/password authentication in `AuthService.swift`. Make sure your login view prominently displays both options:

```
[ Sign in with Apple ]  ← May not work on simulator
        or
[ Email ] [ Password ]  ← Always works
[ Sign In Button ]
```

This way developers can still test the app without needing Sign in with Apple to work.

---

## Next Steps

1. **Immediate**: Test on a physical iPhone signed into iCloud
2. **Short-term**: Verify Apple Developer Console configuration
3. **Long-term**: Add simulator detection and show helpful message

The app code is correct - this is purely an environment/configuration issue.
