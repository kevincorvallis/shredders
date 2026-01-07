# Manual Steps to Add Tabs Files to Xcode

The automated script had path duplication issues. Here are the **manual steps** that will work:

## ✅ Steps to Add Files to Xcode

### 1. Open Xcode
- Open `PowderTracker.xcodeproj` in Xcode

### 2. Clean Up Existing References (if any)
- In Project Navigator, find `Views → Location`
- If you see `TabbedLocationView.swift` with a red icon (missing file), **delete** it (select and press Delete key, choose "Remove Reference")
- If you see a `Tabs` folder with red icons, **delete** it (Remove Reference)

### 3. Add Files Individually (Not as Folder)

#### Step 3A: Add TabbedLocationView.swift
1. Right-click on `Location` folder → **Add Files to "PowderTracker"...**
2. Navigate to: `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Location/`
3. **SELECT ONLY**: `TabbedLocationView.swift`
4. **IMPORTANT**: UNCHECK "Copy items if needed"
5. **IMPORTANT**: SELECT "Create groups" (NOT "Create folder references")
6. Click **Add**

#### Step 3B: Create Tabs Group
1. Right-click on `Location` folder → **New Group**
2. Name it: **Tabs**

#### Step 3C: Add Tab Files to Tabs Group
1. Right-click on the new `Tabs` group → **Add Files to "PowderTracker"...**
2. Navigate to: `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Location/Tabs/`
3. **Hold Cmd and SELECT ALL 8 files**:
   - OverviewTab.swift
   - ForecastTab.swift
   - HistoryTab.swift
   - TravelTab.swift
   - SafetyTab.swift
   - WebcamsTab.swift
   - SocialTab.swift
   - LiftsTab.swift
4. **IMPORTANT**: UNCHECK "Copy items if needed"
5. **IMPORTANT**: SELECT "Create groups"
6. Ensure **PowderTracker** target is checked
7. Click **Add**

### 4. Verify in Project Navigator

You should now see:
```
Views
└── Location
    ├── TabbedLocationView.swift (in Location group)
    ├── LocationView.swift
    ├── LocationViewModel.swift
    └── Tabs (group)
        ├── OverviewTab.swift
        ├── ForecastTab.swift
        ├── HistoryTab.swift
        ├── TravelTab.swift
        ├── SafetyTab.swift
        ├── WebcamsTab.swift
        ├── SocialTab.swift
        └── LiftsTab.swift
```

All files should have **NO red icons**.

### 5. Build the Project
1. Clean Build Folder: **Cmd+Shift+K**
2. Build: **Cmd+B**
3. You should see: **Build Succeeded**

---

## ❌ Common Mistakes to Avoid

1. **Don't drag the Tabs folder** directly into Xcode - this creates folder references instead of groups
2. **Don't check "Copy items if needed"** - files are already in the correct location
3. **Don't select "Create folder references"** - use "Create groups" instead
4. **Don't add files from the wrong location** - make sure you're in the correct directory

---

## 🐛 Troubleshooting

### If you still see red file icons:
1. Select the red file
2. Open File Inspector (right panel, first tab)
3. Under "Location", click the folder icon
4. Navigate to the actual file location
5. Select the file

### If build fails with "file not found":
1. Select the file in Project Navigator
2. Press Delete → Choose "Remove Reference" (NOT "Move to Trash")
3. Re-add the file using steps above

---

## ✅ Alternative: Command Line Cleanup

If you want to start fresh, run this in Terminal:

```bash
cd /Users/kevin/Downloads/shredders/ios/PowderTracker

# Remove all traces of Tabs files from project
ruby -e "
require 'xcodeproj'
proj = Xcodeproj::Project.open('PowderTracker.xcodeproj')
target = proj.targets.find { |t| t.name == 'PowderTracker' }
location = proj.main_group['PowderTracker']['Views']['Location']

# Remove TabbedLocationView
if ref = location.files.find { |f| f.path&.include?('TabbedLocationView') }
  ref.remove_from_project
end

# Remove Tabs group
if tabs = location['Tabs']
  tabs.clear
  tabs.remove_from_project
end

proj.save
puts '✅ Cleaned up project'
"

# Now follow the manual steps above
```

---

**Then follow the manual steps 3A, 3B, 3C above.**
