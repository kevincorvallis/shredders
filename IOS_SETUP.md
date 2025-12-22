# iOS App Setup - Weather.gov Integration

## File Added But Needs Xcode Project Update

The `WeatherGovLinksView.swift` file has been created but needs to be added to the Xcode project.

### Quick Fix (2 minutes):

1. **Open Xcode:**
   ```bash
   open ios/PowderTracker/PowderTracker.xcodeproj
   ```

2. **Add the file:**
   - In Xcode, right-click on the `Views` folder
   - Select "Add Files to 'PowderTracker'..."
   - Navigate to: `ios/PowderTracker/PowderTracker/Views/WeatherGovLinksView.swift`
   - Check "Copy items if needed" (should be unchecked if already in folder)
   - Click "Add"

3. **Build and run:**
   - Select a simulator (iPhone 16 Pro recommended)
   - Press Cmd+B to build
   - Press Cmd+R to run

### Alternative: Use xcodegen (Automated)

If you have `xcodegen` installed:
```bash
cd ios/PowderTracker
xcodegen generate
```

This will regenerate the project file with all Swift files automatically included.

## Features Now Available in iOS App

Once the file is added to the project, the iOS app will have:

### WeatherGovLinksView
- **Location:** Integrated into DashboardView
- **Features:**
  - Weather alerts display with severity colors
  - Quick links to weather.gov pages
  - Native iOS design
  - Auto-refresh with mountain data

### API Endpoints Used:
- `/api/mountains/[mountainId]/alerts` - Weather alerts
- `/api/mountains/[mountainId]/weather-gov-links` - Deep links

### User Flow:
1. Open app and select mountain
2. Scroll to "NOAA Weather.gov" section
3. View any active alerts
4. Tap links to open in Safari:
   - Detailed Forecast
   - Hourly Graph
   - Active Alerts
   - Forecast Discussion

## Testing

After adding the file:
1. Build succeeds ✓
2. Run on simulator
3. Select a mountain
4. Scroll to see Weather.gov section
5. Tap any link to verify Safari integration
6. Check alerts appear when active

## Troubleshooting

**If build still fails:**
- Clean build folder: Cmd+Shift+K
- Restart Xcode
- Verify file is in target membership

**If WeatherGovLinksView not showing:**
- Check `DashboardView.swift` line 44
- Ensure `@AppStorage("selectedMountainId")` has a valid mountain ID
- Check network connectivity

## Integration Complete

All code is ready - just needs the one-time Xcode project file update!
