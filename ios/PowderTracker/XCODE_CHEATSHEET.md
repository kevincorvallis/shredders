# PowderTracker iOS Development Cheat Sheet

## Quick Start - Auto Login Setup (One Time)

The app supports automatic login during development. Set it up once:

1. **Open Scheme Editor**: `⌘<` (or Product → Scheme → Edit Scheme)
2. **Select**: Run → Arguments tab
3. **Add Environment Variables** (click + under Environment Variables):
   - `DEBUG_EMAIL` = `your-email@example.com`
   - `DEBUG_PASSWORD` = `your-password`
4. **Done!** The app will auto-login on every build.

> **Note**: Your credentials are stored in `xcuserdata/` which is gitignored - they won't be committed.

You'll see this in the console when it works:
```
🔐 [DEBUG] Auto-login enabled, signing in as your-email@example.com...
🔐 [DEBUG] Auto-login successful!
```

---

## Xcode Keyboard Shortcuts

### Building & Running
| Action | Shortcut |
|--------|----------|
| Build | `⌘B` |
| Run | `⌘R` |
| Stop | `⌘.` |
| Clean Build Folder | `⌘⇧K` |
| Clean + Build | `⌘⇧K` then `⌘B` |
| Build for Testing | `⌘⇧U` |
| Run Tests | `⌘U` |

### Navigation
| Action | Shortcut |
|--------|----------|
| Open Quickly (find any file) | `⌘⇧O` |
| Go to Definition | `⌃⌘Click` or `⌘Click` |
| Go Back | `⌃⌘←` |
| Go Forward | `⌃⌘→` |
| Show/Hide Navigator | `⌘0` |
| Show/Hide Debug Area | `⌘⇧Y` |
| Show/Hide Inspector | `⌥⌘0` |
| Jump to Line | `⌘L` |
| Find in Project | `⌘⇧F` |
| Find in File | `⌘F` |
| Replace in File | `⌥⌘F` |

### Editing
| Action | Shortcut |
|--------|----------|
| Comment/Uncomment | `⌘/` |
| Indent | `⌘]` |
| Outdent | `⌘[` |
| Duplicate Line | `⌘D` |
| Move Line Up | `⌥⌘[` |
| Move Line Down | `⌥⌘]` |
| Fix All Issues | `⌃⌥⌘F` |
| Re-indent Selection | `⌃I` |
| Show Completions | `⌃Space` |

### Debugging
| Action | Shortcut |
|--------|----------|
| Toggle Breakpoint | `⌘\` |
| Step Over | `F6` |
| Step Into | `F7` |
| Step Out | `F8` |
| Continue | `⌃⌘Y` |
| Pause | `⌃⌘Y` |

---

## Terminal Commands

### Simulator Management
```bash
# List all simulators
xcrun simctl list devices

# Boot a simulator
xcrun simctl boot "iPhone 16 Pro"

# Shutdown simulator
xcrun simctl shutdown booted

# Erase simulator (reset to clean state)
xcrun simctl erase booted

# Take screenshot
xcrun simctl io booted screenshot ~/Desktop/screenshot.png

# Record video
xcrun simctl io booted recordVideo ~/Desktop/recording.mp4

# Open URL in simulator
xcrun simctl openurl booted "powdertracker://mountains/stevens"

# Install app
xcrun simctl install booted /path/to/App.app

# Uninstall app
xcrun simctl uninstall booted com.shredders.powdertracker

# Stream logs
xcrun simctl spawn booted log stream --predicate 'process CONTAINS "PowderTracker"'
```

### Building from Command Line
```bash
# Build for simulator
xcodebuild -scheme PowderTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# Clean build
xcodebuild -scheme PowderTracker clean

# Build and run tests
xcodebuild -scheme PowderTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test

# Archive for release
xcodebuild -scheme PowderTracker \
  -configuration Release \
  -archivePath ./build/PowderTracker.xcarchive \
  archive
```

### Derived Data
```bash
# Clear derived data (fixes weird build issues)
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clear just this project's derived data
rm -rf ./build
```

---

## Common Issues & Fixes

### "No such module" Error
```bash
# 1. Clean build folder
⌘⇧K

# 2. Close Xcode, delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 3. Re-open and build
```

### Package Resolution Failed
```bash
# Reset package caches
File → Packages → Reset Package Caches
```

### Simulator Won't Launch
```bash
# Kill simulator processes
killall Simulator
xcrun simctl shutdown all

# Then re-run from Xcode
```

### Code Signing Issues
```bash
# In Xcode:
# 1. Select project in navigator
# 2. Signing & Capabilities tab
# 3. Check "Automatically manage signing"
# 4. Select your team
```

### SwiftUI Preview Not Working
1. Clean build: `⌘⇧K`
2. Resume preview: Click "Resume" or press `⌥⌘P`
3. If still broken, restart Xcode

---

## Debug Tips

### Print Statements
```swift
// Basic print (shows in console)
print("Debug: \(variable)")

// With file/line info
print("[\(#file):\(#line)] \(variable)")

// Conditional (DEBUG only)
#if DEBUG
print("Debug info: \(sensitiveData)")
#endif
```

### Breakpoint Actions
1. Right-click a breakpoint → Edit Breakpoint
2. Add actions:
   - **Log Message**: Print without stopping
   - **Shell Command**: Run scripts
   - **Sound**: Audio notification
3. Check "Automatically continue" to not pause

### View Hierarchy Debugger
- While running, click: **Debug → View Debugging → Capture View Hierarchy**
- Or click the layers icon in the debug bar

### Network Debugging
- Use **Charles Proxy** or **Proxyman** to inspect API calls
- Or add to your code:
```swift
URLSession.shared.configuration.protocolClasses?.insert(URLProtocol.self, at: 0)
```

---

## Environment Variables Reference

| Variable | Purpose |
|----------|---------|
| `DEBUG_EMAIL` | Auto-login email |
| `DEBUG_PASSWORD` | Auto-login password |
| `OPENWEATHERMAP_API_KEY` | Weather API key |

Set in: **Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables**

---

## Useful Xcode Settings

### Enable Build Timing
```
Xcode → Settings → General → Show build operation timing summary
```

### Faster Builds
1. Use **Rosetta** for M1/M2 if packages don't support ARM
2. Enable **Parallel Builds**: Build Settings → parallelize build
3. Disable **Debug Information Format** in Debug: `DWARF` instead of `DWARF with dSYM`

### Better Code Completion
```
Xcode → Settings → Text Editing → Display → Code folding ribbon
```

---

## Project-Specific Commands

### Run E2E Tests
```bash
cd ios/PowderTracker
./scripts/e2e_test.sh
```

### Deep Links for Testing
```bash
# Open mountain detail
xcrun simctl openurl booted "powdertracker://mountains/stevens"

# Open event
xcrun simctl openurl booted "powdertracker://events/EVENT_ID"

# Open invite
xcrun simctl openurl booted "https://shredders-bay.vercel.app/events/invite/TOKEN"
```

---

## Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│  BUILD & RUN                                            │
│  ⌘B = Build    ⌘R = Run    ⌘. = Stop    ⌘⇧K = Clean   │
├─────────────────────────────────────────────────────────┤
│  NAVIGATION                                             │
│  ⌘⇧O = Open Quickly    ⌘⇧F = Find in Project          │
│  ⌘0 = Toggle Navigator    ⌘⇧Y = Toggle Debug          │
├─────────────────────────────────────────────────────────┤
│  EDITING                                                │
│  ⌘/ = Comment    ⌃I = Re-indent    ⌘D = Duplicate     │
├─────────────────────────────────────────────────────────┤
│  DEBUGGING                                              │
│  ⌘\ = Breakpoint    F6 = Step Over    ⌃⌘Y = Continue  │
└─────────────────────────────────────────────────────────┘
```
