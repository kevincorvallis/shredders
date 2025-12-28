# ⚠️ Add Skeleton Files to Xcode Project

The skeleton Swift files exist in the filesystem but need to be added to your Xcode project.

## Quick Fix (2 minutes)

### Step-by-Step:

1. **Open Xcode**
   ```bash
   cd /Users/kevin/Downloads/shredders/ios
   open PowderTracker/PowderTracker.xcodeproj
   ```

2. **In Xcode Project Navigator** (left sidebar):
   - Expand `PowderTracker` → `Views` → `Components`
   - You should see existing folders like `TripAdviceCard.swift`, etc.

3. **Right-click on the `Components` folder**
   - Select **"Add Files to 'PowderTracker'..."**

4. **Navigate to the Skeletons folder**:
   - In the file picker, navigate to:
     `PowderTracker/Views/Components/Skeletons`
   - You should see 4 files:
     - `SkeletonView.swift`
     - `DashboardSkeleton.swift`
     - `ForecastSkeleton.swift`
     - `ListSkeleton.swift`

5. **Select all 4 files** (Cmd+A or click each while holding Cmd)

6. **IMPORTANT - Check these settings**:
   - ✅ **"Add to targets: PowderTracker"** - MUST be checked
   - ❌ **"Copy items if needed"** - MUST be unchecked (files are already there)
   - ✅ **"Create groups"** - Should be selected

7. **Click "Add"**

8. **Verify in Project Navigator**:
   - You should now see `Skeletons` folder under `Components`
   - All 4 files should be visible and have PowderTracker target membership

9. **Build the project** (Cmd+B)
   - Errors should be gone!

---

## Visual Guide

```
PowderTracker (Project Navigator)
└── PowderTracker
    └── Views
        └── Components
            ├── ConditionsCard.swift
            ├── TripAdviceCard.swift
            └── Skeletons  ← Should see this folder after adding
                ├── SkeletonView.swift
                ├── DashboardSkeleton.swift
                ├── ForecastSkeleton.swift
                └── ListSkeleton.swift
```

---

## Troubleshooting

### If files don't appear:
1. Make sure you're in the **PowderTracker.xcodeproj** (not xcworkspace)
2. Try **File → Add Files to "PowderTracker"** from menu bar
3. Navigate to the Skeletons folder and add files

### If build still fails:
1. **Clean Build Folder**: Product → Clean Build Folder (Cmd+Shift+K)
2. **Delete Derived Data**:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
3. **Rebuild**: Cmd+B

### If you see duplicate files:
1. Remove them from project (delete references only, not files)
2. Re-add following steps above

---

## Files Located At:

```
/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Components/Skeletons/
├── SkeletonView.swift          (2.9 KB)
├── DashboardSkeleton.swift     (5.3 KB)
├── ForecastSkeleton.swift      (1.6 KB)
└── ListSkeleton.swift          (5.4 KB)
```

All files verified to exist! ✅

---

## After Adding Files

Your build should succeed and you'll see:
- No more "Cannot find 'ForecastViewSkeleton' in scope" errors
- No more "Cannot find 'HistoryChartSkeleton' in scope" errors
- Beautiful skeleton screens when loading data!

---

## Alternative: Command Line (Advanced)

If you prefer command line, install xcodeproj gem:

```bash
gem install xcodeproj
```

Then run this Ruby script:

```ruby
#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('PowderTracker/PowderTracker.xcodeproj')
target = project.targets.first
components_group = project.main_group['PowderTracker']['Views']['Components']
skeletons_group = components_group.new_group('Skeletons')

files = [
  'SkeletonView.swift',
  'DashboardSkeleton.swift',
  'ForecastSkeleton.swift',
  'ListSkeleton.swift'
]

files.each do |file|
  file_ref = skeletons_group.new_reference(file)
  target.add_file_references([file_ref])
end

project.save
```

But the GUI method above is simpler! 😊
