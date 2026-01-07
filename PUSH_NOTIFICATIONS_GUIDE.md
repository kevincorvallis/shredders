# Push Notifications & Alert Subscriptions Guide

## ✅ Implementation Complete

### Backend Infrastructure

**Alert Subscriptions API:**
- `GET /api/alerts/subscriptions` - Fetch user's subscriptions
- `POST /api/alerts/subscriptions` - Create/update subscription
- `DELETE /api/alerts/subscriptions` - Remove subscription

**Push Token Registration API:**
- `POST /api/push/register` - Register device token with APNs
- `DELETE /api/push/register` - Unregister device token

**APNs Service:**
- `/src/lib/push/apns.ts` - Apple Push Notification service integration
- `sendWeatherAlert()` - Send weather alert notification
- `sendPowderAlert()` - Send powder alert notification
- `sendBulkPushNotifications()` - Batch send to multiple devices

**Cron Jobs:**
- `/api/cron/check-weather-alerts` - Runs every 15 minutes
- `/api/cron/check-powder-alerts` - Runs daily at 6 AM

### iOS Components

**Services:**
- `PushNotificationManager.swift` - Main push notification handler
- `AlertSubscriptionService.swift` - Manage alert subscriptions

**Models:**
- `AlertSubscription.swift` - Subscription data model

**Views:**
- `AlertSettingsView.swift` - Configure alerts for a mountain
- `PushNotificationSetupView.swift` - Enable push notifications

**App Integration:**
- `PowderTrackerApp.swift` - AppDelegate for push notification callbacks

---

## 🔔 How Push Notifications Work

### Flow Overview

1. **User enables notifications** → iOS requests permission
2. **APNs generates device token** → iOS receives unique token
3. **App registers token with backend** → Server stores token in database
4. **User subscribes to mountain alerts** → Server creates subscription record
5. **Cron jobs monitor conditions** → Every 15 min (weather) or daily (powder)
6. **Conditions trigger alerts** → Server finds subscribed users
7. **Server sends to APNs** → Apple delivers notification to device
8. **User receives notification** → Can tap to open app

### Cron Job Details

**Weather Alerts (Every 15 minutes):**
```
Schedule: */15 * * * *
```
- Fetches all mountains with active weather subscriptions
- Checks NOAA API for new alerts (issued in last 24 hours)
- Groups alerts by user and mountain
- Sends push notifications to subscribed devices

**Powder Alerts (Daily at 6 AM):**
```
Schedule: 0 6 * * *
```
- Fetches all mountains with active powder subscriptions
- Checks 24h snowfall against user thresholds
- Only sends if powder score > 7
- Sends notifications to users with met thresholds

---

## 📱 iOS Setup Required

### 1. Apple Developer Console Setup

**Generate APNs Auth Key:**
1. Go to [Apple Developer](https://developer.apple.com/account/resources/authkeys/list)
2. Click "+" to create a new key
3. Name: "Shredders APNs Key"
4. Enable: "Apple Push Notifications service (APNs)"
5. Click "Continue" → "Register"
6. **Download the .p8 file** (only shown once!)
7. Note your **Key ID** and **Team ID**

**Configure App Identifier:**
1. Go to [Identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Find your app (com.shredders.powdertracker)
3. Ensure "Push Notifications" capability is checked
4. Click "Save"

### 2. Xcode Project Setup

**Enable Push Notifications Capability:**
1. Open project in Xcode
2. Select PowderTracker target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Push Notifications"
6. Verify capability appears in list

**Update Info.plist (already done):**
```xml
<!-- No special keys required for push notifications -->
```

### 3. Environment Variables

Add to `.env.local`:
```bash
# APNs Configuration
APNS_KEY_ID=ABC123XYZ
APNS_TEAM_ID=TEAMID1234
APNS_KEY_PATH=/path/to/AuthKey_ABC123XYZ.p8
APNS_PRODUCTION=false  # Use true for production
APNS_BUNDLE_ID=com.shredders.powdertracker

# Cron Secret (for securing cron endpoints)
CRON_SECRET=your-secret-here
```

**Important:**
- Store the .p8 file securely (e.g., `/opt/keys/` on server)
- Never commit the .p8 file to git
- Use `APNS_PRODUCTION=false` for development (sandbox)
- Use `APNS_PRODUCTION=true` for production

---

## 🎯 Usage Examples

### iOS: Request Push Permission

```swift
// In settings or onboarding flow
Button("Enable Notifications") {
    Task {
        try await PushNotificationManager.shared.requestAuthorization()
    }
}
```

### iOS: Subscribe to Mountain Alerts

```swift
// When viewing mountain details
struct MountainDetailView: View {
    let mountainId: String
    @State private var showingAlertSettings = false

    var body: some View {
        VStack {
            // Mountain content

            Button("Alert Settings") {
                showingAlertSettings = true
            }
        }
        .sheet(isPresented: $showingAlertSettings) {
            AlertSettingsView(
                mountainId: mountainId,
                mountainName: "Mt. Baker"
            )
        }
    }
}
```

### iOS: Check Subscription Status

```swift
let isSubscribed = try await AlertSubscriptionService.shared.isSubscribed(to: "baker")

if isSubscribed {
    // Show "Subscribed" badge
} else {
    // Show "Subscribe" button
}
```

### Backend: Send Manual Notification

```typescript
import { sendPowderAlert } from '@/lib/push/apns';

// Send powder alert
await sendPowderAlert(deviceToken, {
  mountainName: 'Mt. Baker',
  snowfallInches: 12,
  mountainId: 'baker',
});
```

---

## 🔐 Security & Privacy

### Backend Security

**Cron Job Protection:**
- All cron endpoints require `Bearer ${CRON_SECRET}` authorization
- Only Vercel Cron can call these endpoints
- Set `CRON_SECRET` in environment variables

**Device Token Protection:**
- Tokens stored with user association in database
- RLS policies ensure users can only manage own tokens
- Inactive tokens are soft-deleted (is_active=false)

**Subscription Privacy:**
- Users can only subscribe to public mountains
- Subscriptions are user-specific
- No sharing of subscription data

### iOS Security

**Token Handling:**
- Device tokens are ephemeral and can change
- App re-registers token on each launch
- Tokens are invalidated when app is uninstalled

**Permission Prompts:**
- User must explicitly grant notification permission
- Permission can be revoked in Settings anytime
- App gracefully handles permission denial

---

## 📊 Database Schema

### Tables Used

**alert_subscriptions:**
- `id` - UUID primary key
- `user_id` - FK to users table
- `mountain_id` - FK to mountains
- `weather_alerts` - Boolean (default: true)
- `powder_alerts` - Boolean (default: true)
- `powder_threshold` - Integer (default: 6 inches)
- `created_at`, `updated_at` - Timestamps

**push_notification_tokens:**
- `id` - UUID primary key
- `user_id` - FK to users table
- `device_token` - String (APNs token)
- `platform` - Enum ('ios', 'web')
- `device_id` - String (unique per device)
- `app_version` - String (optional)
- `os_version` - String (optional)
- `is_active` - Boolean (default: true)
- `last_used_at` - Timestamp
- `created_at` - Timestamp

---

## 🧪 Testing

### Testing on iOS Simulator

**Limitations:**
- iOS Simulator **cannot** register for push notifications
- APNs tokens can only be generated on physical devices
- Use physical iPhone/iPad for testing

**Workaround for Development:**
1. Use Xcode console to test notification handling
2. Simulate notification via Xcode: Debug → Simulate Remote Notifications
3. Create test `.apns` file for payload

### Testing on Physical Device

**Development Mode (Sandbox APNs):**
1. Set `APNS_PRODUCTION=false`
2. Build app to physical device
3. Grant notification permission
4. Check Xcode console for device token
5. Subscribe to mountain alerts
6. Trigger cron job manually or wait for schedule

**Trigger Cron Job Manually:**
```bash
curl -X POST https://your-app.vercel.app/api/cron/check-weather-alerts \
  -H "Authorization: Bearer ${CRON_SECRET}"
```

### Production Testing

**Before Going Live:**
1. ✅ APNs Auth Key configured
2. ✅ Push Notifications capability enabled
3. ✅ Set `APNS_PRODUCTION=true`
4. ✅ Test on TestFlight build
5. ✅ Verify cron jobs run on schedule
6. ✅ Test all notification types (weather, powder)

---

## 🐛 Troubleshooting

### Device Token Not Registered

**Check:**
- Is user authenticated?
- Did user grant notification permission?
- Is device physical (not simulator)?
- Check Xcode console for errors
- Verify API endpoint is reachable

**Solution:**
```swift
// Force re-register
await PushNotificationManager.shared.checkAuthorizationStatus()
```

### Notifications Not Received

**Check:**
- Is device token active in database?
- Is user subscribed to mountain?
- Are cron jobs running? (Check Vercel Logs)
- Is `APNS_PRODUCTION` set correctly?
- Check APNs auth key is valid

**Solution:**
- Review server logs for APNs errors
- Verify notification payload format
- Check APNs feedback service for invalid tokens

### Cron Jobs Not Running

**Check:**
- Is `vercel.json` deployed?
- Are cron schedules valid?
- Is `CRON_SECRET` set?
- Check Vercel dashboard → Deployments → Cron Jobs

**Solution:**
```bash
# Check cron job status
vercel env ls

# View cron logs
vercel logs --since 1h | grep cron
```

### APNs Connection Errors

**Common Errors:**
- `InvalidProviderToken` - Check key file path and format
- `BadDeviceToken` - Token is invalid or app uninstalled
- `DeviceTokenNotForTopic` - Bundle ID mismatch

**Solution:**
- Regenerate APNs auth key
- Verify bundle ID matches
- Check .p8 file permissions

---

## 💡 Best Practices

### Performance

1. **Batch Notifications:** Send to multiple devices in parallel (max 100/batch)
2. **Cache Subscriptions:** Query subscriptions once per cron run
3. **Rate Limiting:** Avoid sending same alert multiple times to same user
4. **Token Cleanup:** Remove inactive tokens after 30 days

### UX

1. **Clear Prompts:** Explain why notifications are useful before requesting permission
2. **Settings Access:** Provide easy way to manage subscriptions
3. **Notification Content:** Keep titles concise, bodies descriptive
4. **Deep Linking:** Navigate to relevant content when notification tapped

### Reliability

1. **Error Handling:** Catch and log all APNs errors
2. **Retry Logic:** Retry failed notifications with exponential backoff
3. **Token Rotation:** Handle token updates gracefully
4. **Monitoring:** Track notification delivery rates

---

## 🚀 Next Steps

After setting up push notifications:

1. **APNs Setup:** Generate auth key and configure environment
2. **Testing:** Test on physical device with sandbox APNs
3. **Monitoring:** Set up alerts for failed notifications
4. **Analytics:** Track opt-in rates and engagement
5. **Refinement:** Adjust cron schedules based on usage
6. **Expansion:** Add more alert types (lift status, parking)

---

## 📝 Code Locations

### Backend (Next.js)
```
/src/app/api/alerts/subscriptions/route.ts
/src/app/api/push/register/route.ts
/src/app/api/cron/check-weather-alerts/route.ts
/src/app/api/cron/check-powder-alerts/route.ts
/src/lib/push/apns.ts
```

### iOS Services
```
/ios/PowderTracker/PowderTracker/Services/PushNotificationManager.swift
/ios/PowderTracker/PowderTracker/Services/AlertSubscriptionService.swift
```

### iOS Models
```
/ios/PowderTracker/PowderTracker/Models/AlertSubscription.swift
```

### iOS Views
```
/ios/PowderTracker/PowderTracker/Views/Alerts/AlertSettingsView.swift
/ios/PowderTracker/PowderTracker/Views/Alerts/PushNotificationSetupView.swift
```

### Configuration
```
/vercel.json (cron schedules)
/package.json (node-apn dependency)
```

---

## ✨ Summary

Push notifications are now fully integrated! Users can:

- **Enable** push notifications in app settings
- **Subscribe** to weather and powder alerts per mountain
- **Customize** powder alert threshold (inches of fresh snow)
- **Receive** real-time notifications for severe weather
- **Get notified** when fresh snow meets their threshold
- **Manage** subscriptions per mountain

The system includes:
- ✅ APNs integration with Apple servers
- ✅ Automated monitoring via cron jobs
- ✅ Secure device token registration
- ✅ User-specific alert subscriptions
- ✅ Deep linking from notifications
- ✅ Badge count management
- ✅ Production-ready error handling

**Phase 5 complete!** 🎉

Next: Phase 6 (Batched Social Data Endpoint)