# Clear Browser Cache to Fix "Failed to Decode Response" Errors

## Issue

If you're seeing "failed to decode response" or "data couldn't be read because it isn't in the correct format" errors, this is likely due to your browser caching old JavaScript code that's incompatible with the new API responses.

## Quick Fix (Recommended)

### 1. Hard Reload in Your Browser

**Chrome/Edge/Brave:**
- **Mac**: `Cmd + Shift + R`
- **Windows/Linux**: `Ctrl + Shift + R`

**Firefox:**
- **Mac**: `Cmd + Shift + R`
- **Windows/Linux**: `Ctrl + F5`

**Safari:**
- **Mac**: `Cmd + Option + R`

### 2. Clear Site Data (If Hard Reload Doesn't Work)

**Chrome/Edge/Brave:**
1. Open DevTools (`F12` or `Cmd+Option+I`)
2. Right-click the reload button
3. Select "Empty Cache and Hard Reload"

**OR**

1. Go to `chrome://settings/siteData`
2. Search for "localhost"
3. Click trash icon to delete
4. Reload the page

**Firefox:**
1. Open DevTools (`F12`)
2. Go to Storage tab
3. Right-click "localhost:3000"
4. Select "Delete All"
5. Reload the page

**Safari:**
1. Safari → Preferences → Advanced
2. Check "Show Develop menu"
3. Develop → Empty Caches
4. Reload the page

## Development Workflow

To avoid cache issues during development:

### 1. Keep DevTools Open

With DevTools open, enable "Disable cache":

**Chrome/Edge/Brave/Firefox:**
1. Open DevTools (`F12`)
2. Go to Network tab
3. Check "Disable cache" checkbox
4. Keep DevTools open while developing

### 2. Use Incognito/Private Mode

Incognito mode doesn't cache aggressively:
- **Chrome/Edge**: `Cmd+Shift+N` (Mac) or `Ctrl+Shift+N` (Windows/Linux)
- **Firefox**: `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
- **Safari**: `Cmd+Shift+N`

### 3. Restart Dev Server

Sometimes the Next.js dev server caches responses:

```bash
# Stop server (Ctrl+C)
# Then restart
npm run dev
```

## Specific Fixes Applied (Already Done)

### ✅ Mountain Detail Pages
- Now use batched `/api/mountains/[id]/all` endpoint
- Proper error handling in `useMountainData` hook
- SWR caching prevents unnecessary requests

### ✅ Patrol Pages
- Enhanced error handling with status codes
- Console logging for debugging
- Better error messages

### ✅ iOS App
- All Swift warnings fixed
- Orientation support enabled
- Concurrency safety implemented

## Verifying the Fix

After clearing cache, check these work without errors:

1. **Main mountain page**: http://localhost:3000/mountains/crystal
2. **Patrol page**: http://localhost:3000/mountains/crystal/patrol
3. **History page**: http://localhost:3000/mountains/crystal/history

### Check Browser Console

Open DevTools Console (`F12` → Console tab) and verify:
- ✅ No red errors
- ✅ Network requests return 200 status
- ✅ JSON responses are valid

### Example Console Output (Good)

```
[Cache MISS] mountain:crystal:all
GET /api/mountains/crystal/all 200 in 1.2s
```

### Example Console Output (Bad - Cache Issue)

```
❌ SyntaxError: Unexpected token < in JSON
❌ Failed to decode response
```

If you see the "Bad" output, you need to clear cache again.

## Still Having Issues?

### 1. Check Which Page Is Failing

Navigate to each page and note which specific page shows the error:
- Main overview: `/mountains/[mountain]`
- Patrol: `/mountains/[mountain]/patrol`
- History: `/mountains/[mountain]/history`
- Webcams: `/mountains/[mountain]/webcams`

### 2. Check Network Tab

1. Open DevTools (`F12`)
2. Go to Network tab
3. Navigate to the failing page
4. Look for red (failed) requests
5. Click on failed request
6. Check the Response tab

### 3. Test API Directly

```bash
# Should return valid JSON
curl http://localhost:3000/api/mountains/crystal/all

# Should validate JSON
curl -s http://localhost:3000/api/mountains/crystal/all | python3 -m json.tool
```

### 4. Check Server Logs

Look at terminal where `npm run dev` is running:
- Should show `200` status codes
- Should NOT show `500` errors
- Should show cache hits/misses

### 5. Nuclear Option (Complete Reset)

If nothing else works:

```bash
# 1. Stop dev server (Ctrl+C)

# 2. Clear Next.js cache
rm -rf .next

# 3. Clear node_modules cache
rm -rf node_modules/.cache

# 4. Restart dev server
npm run dev

# 5. Hard reload browser (Cmd+Shift+R)
```

## Prevention

To prevent cache issues in the future:

1. **Always develop with DevTools open** and "Disable cache" checked
2. **Use Incognito mode** for testing
3. **Hard reload after pulling code** changes from git
4. **Restart dev server** when switching branches

## iOS Build Warnings

The iOS warnings you're seeing are old - the fixes are already in place:

```bash
# Build iOS app with clean build folder
cd ios
xcodebuild -project PowderTracker/PowderTracker.xcodeproj \
           -scheme PowderTracker \
           clean build
```

Expected result: **0 errors, 0 warnings**

If you still see warnings:
1. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/PowderTracker-*`
2. Clean in Xcode: Product → Clean Build Folder (Cmd+Shift+K)
3. Build: Product → Build (Cmd+B)

---

**Latest git commit includes all fixes** - make sure you've pulled latest changes:

```bash
git pull origin main
```
