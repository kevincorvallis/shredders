# Adding New Component Files to Xcode Project

The following Swift files exist but are not yet added to the Xcode project:
- `MountainStatusView.swift`
- `NavigateButton.swift`
- `SnowfallTableView.swift`

## Quick Fix (Recommended)

1. **Open Xcode:**
   ```bash
   open /Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj
   ```

2. **In Xcode:**
   - Right-click on `Views/Components` folder in the Project Navigator
   - Select "Add Files to PowderTracker..."
   - Navigate to `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Components/`
   - Select these three files (hold ⌘ to multi-select):
     - MountainStatusView.swift
     - NavigateButton.swift
     - SnowfallTableView.swift
   - **Important:** Make sure "Copy items if needed" is UNCHECKED (files are already in the right place)
   - **Important:** Make sure "PowderTracker" target is CHECKED
   - Click "Add"

3. **Build the project:**
   - Press ⌘B or select Product → Build
   - The errors should be resolved

## Alternative: Command Line Fix

If you prefer a command-line approach:

```bash
cd /Users/kevin/Downloads/shredders/ios/PowderTracker
xcodebuild clean build -scheme PowderTracker
```

If errors persist, use the Xcode UI method above.

## Verification

After adding the files, verify they appear in:
- Project Navigator under `PowderTracker/Views/Components/`
- Target Membership (select file → File Inspector → Target Membership → PowderTracker should be checked)
