# Component Demo Guide

Quick guide to preview and test all new UI components.

---

## iOS Components

### 1. Enhanced Auth View

**Preview in Xcode:**
```swift
#Preview("Login") {
    EnhancedUnifiedAuthView()
        .environment(AuthService.shared)
}
```

**Features to Test:**
- Tap between Login/Signup modes
- Type in email field (watch icon animations)
- Type password (watch real-time validation)
- Toggle password visibility
- Submit with invalid data (see error banner)
- Success animation on valid submission

**Animation Timeline:**
- 0.0s: Page loads
- 0.0-0.6s: Header fades in from top
- 0.2-0.8s: Form elements fade in from bottom
- On submit: Success overlay scales in

---

### 2. Onboarding Flow

**Preview in Xcode:**
```swift
#Preview {
    OnboardingView(isPresented: .constant(true))
}
```

**Features to Test:**
- Swipe between pages (TabView)
- Watch icon scale + rotate animations
- Try Skip button (top right)
- Navigate with Back/Next buttons
- Observe snowflake animations
- Check final "Get Started" button

**Pages:**
1. Welcome (blue gradient)
2. Track Conditions (cyan gradient)
3. Smart Alerts (amber gradient)
4. Join the Crew (emerald gradient)

---

### 3. Events View (Sample Events Preview)

**Preview in Xcode:**
```swift
#Preview {
    EventsView()
        .environment(AuthService.shared)
}
```

**Features to Test:**
- Non-authenticated state displays sample events
- Ski trail difficulty badges with icons:
  - 🟢 **Green** circle (Beginner)
  - 🟦 **Blue** square (Intermediate)
  - ◆ **Black** diamond (Advanced)
  - ◆◆ **Double Black** diamonds (Expert)
  - 🟢🟦◆ **All Levels** combined icons
- Carpool availability badges (green with seat count)
- Tap event card → "Sign in to view & join" overlay
- Hero section with CTA buttons
- Departure time and location info

**Sample Events:**
1. "First Tracks Friday" @ Snoqualmie (Green)
2. "Powder Day at Baker!" @ Mt. Baker (Blue)
3. "Backside Bowls Session" @ Stevens Pass (Black)
4. "Steep Chutes & Cliffs" @ Crystal (Double Black)
5. "Group Day - All Welcome!" @ Whistler (All Levels)

**Try This:**
1. View without logging in → See sample events
2. Tap any event → Overlay appears
3. Check all 5 difficulty badge types
4. Verify carpool indicators show correctly

---

## Web Components

### 3. Enhanced Login Page

**URL:** `http://localhost:3000/auth/login`

**Features to Test:**
- Background orb animations (subtle pulse)
- Logo glow effect (hover to see)
- Type in email field (blue border on focus)
- Toggle password visibility (eye icon)
- Submit with wrong credentials (error slides in)
- Loading state (spinner in button)
- Link to signup page

**Animations:**
- Page load: Fade in + slide up (0.6s)
- Logo: Scale + rotate (0.6s spring)
- Orbs: Continuous pulse (8-10s loop)
- Error: Slide in from top (0.3s)

---

### 4. Enhanced Signup Page

**URL:** `http://localhost:3000/auth/signup`

**Features to Test:**
- All login features plus:
- Username sanitization (try spaces/capitals)
- Display name field (optional)
- Password requirements panel (expands when typing)
- Real-time requirement checks (green checkmarks)
- Confirm password matching (border turns green/red)
- Button disabled until all requirements met
- Requirements grid (2 columns)

**Password Requirements:**
- 12+ characters
- Uppercase letter
- Lowercase letter
- Number
- Special character

**Try This:**
1. Type weak password: "test"
   - Requirements stay red
   - Button disabled
2. Type strong password: "MyP@ssw0rd123"
   - Requirements turn green
   - Button enabled
3. Mismatch confirm password
   - Border turns red
   - Error message appears

---

### 5. Welcome Flow

**Import in any page:**
```tsx
import { WelcomeFlow } from '@/components/WelcomeFlow';

export default function HomePage() {
  const [showWelcome, setShowWelcome] = useState(true);

  return (
    <>
      {showWelcome && (
        <WelcomeFlow
          onComplete={() => setShowWelcome(false)}
          userName="Shredder"
        />
      )}
      {/* Your page content */}
    </>
  );
}
```

**Features to Test:**
- Snowflake falling animation
- Background orb animations
- Slide transitions between steps (swipe or click Next)
- Back button (appears after step 1)
- Skip button (top right)
- Progress indicators (4 dots at top)
- Icon animations (scale + entrance)
- Final "Get Started" button

**Animation Timeline:**
- 0.0s: Background fades in
- 0.1s: Snowflakes start falling
- 0.2s: Icon scales in with rotation
- 0.4s: Title fades in
- 0.6s: Description fades in
- Continuous: Orbs pulse, snowflakes fall

---

### 7. Events Page (Sample Events Preview)

**URL:** `http://localhost:3000/events` (logged out)

**Features to Test:**
- Non-authenticated view with sample events
- Ski trail difficulty badges with icons:
  - 🟢 **Green** circle (Beginner)
  - 🟦 **Blue** square (Intermediate)
  - ◆ **Black** diamond (Advanced)
  - ◆◆ **Double Black** diamonds (Expert)
  - 🟢🟦◆ **All Levels** combined icons
- Hover over event → "Sign in to view & join" overlay
- Hero section explaining feature
- Carpool availability badges
- CTA buttons (Sign in, Create account, Get started)

**Sample Events:**
1. "First Tracks Friday" @ Snoqualmie (Green)
2. "Powder Day at Baker!" @ Mt. Baker (Blue)
3. "Backside Bowls Session" @ Stevens Pass (Black)
4. "Steep Chutes & Cliffs" @ Crystal (Double Black)
5. "Group Day - All Welcome!" @ Whistler (All Levels)

**Try This:**
1. Log out of the app
2. Visit `/events` directly
3. Hover over each sample event card
4. Click anywhere → Redirects to login
5. Verify all 5 difficulty badge types render with icons
6. Check carpool badges show seat counts

---

## Quick Test Script

### iOS (Xcode)
1. Open `PowderTracker.xcodeproj`
2. Navigate to `EnhancedUnifiedAuthView.swift`
3. Click "Preview" canvas
4. Interact with live preview
5. Switch to `OnboardingView.swift`
6. Test onboarding flow
7. Switch to `EventsView.swift`
8. Test sample events (ensure not authenticated)

### Web (Browser)
1. Start dev server: `npm run dev`
2. Visit `http://localhost:3000/auth/login`
3. Test all form interactions
4. Visit `/auth/signup`
5. Test password validation
6. Log out and visit `/events`
7. Test sample events with difficulty badges
8. Add WelcomeFlow to home page temporarily
9. Test onboarding flow

---

## Visual Checklist

### iOS Auth View
- [ ] Gradient background visible
- [ ] Logo has glow effect
- [ ] Mountain icon centered
- [ ] Text fields have icons
- [ ] Password toggle works
- [ ] Requirements grid shows (signup)
- [ ] Error banner appears on error
- [ ] Success overlay shows on success
- [ ] Apple Sign In button present

### iOS Onboarding
- [ ] Dark gradient background
- [ ] Snowflakes falling
- [ ] Icon has gradient circle
- [ ] Icon animates on page change
- [ ] Progress dots update
- [ ] Skip button top right
- [ ] Back button shows after page 1
- [ ] "Get Started" on last page

### iOS Events View
- [ ] Hero section with gradient border
- [ ] 5 sample events displayed
- [ ] Green circle badge (Beginner)
- [ ] Blue square badge (Intermediate)
- [ ] Black diamond badge (Advanced)
- [ ] Double black diamond badge (Expert)
- [ ] Combined icons badge (All Levels)
- [ ] Carpool badges with seat count
- [ ] Tap overlay shows "Sign in to view & join"
- [ ] Sign in CTA buttons work

### Web Login
- [ ] Animated orbs in background
- [ ] Logo glow visible
- [ ] Fields focus blue
- [ ] Password toggle works
- [ ] Error slides in from top
- [ ] Button has gradient
- [ ] Loading spinner shows
- [ ] Links work

### Web Signup
- [ ] All login checks plus:
- [ ] Requirements panel expands
- [ ] Checkmarks turn green
- [ ] Confirm password border changes
- [ ] Username sanitizes input
- [ ] Button enables when valid
- [ ] Grid layout (2 columns)

### Web Welcome Flow
- [ ] Full screen overlay
- [ ] Dark background gradient
- [ ] Snowflakes falling
- [ ] Orbs pulsing
- [ ] Progress indicators
- [ ] Slide animation works
- [ ] Skip button works
- [ ] Back/Next navigation

### Web Events Page
- [ ] Hero section with gradient background
- [ ] 5 sample events displayed
- [ ] Green circle badge (Beginner)
- [ ] Blue square badge (Intermediate)
- [ ] Black diamond badge (Advanced)
- [ ] Double black diamond badge (Expert)
- [ ] Combined icons badge (All Levels)
- [ ] Carpool badges with seat count
- [ ] Hover overlay shows "Sign in to view & join"
- [ ] Sign in CTA buttons work
- [ ] Bottom "Get started free" CTA

---

## Common Issues & Fixes

### iOS

**Issue**: Animations don't play
**Fix**: Check that Preview is in "Live" mode, not "Static"

**Issue**: Snowflakes don't move
**Fix**: Verify timer is publishing on `.main` runloop

**Issue**: Keyboard doesn't show
**Fix**: Use device simulator, not canvas preview

### Web

**Issue**: Backdrop blur not visible
**Fix**: Some browsers need `-webkit-backdrop-filter`

**Issue**: Animations stutter
**Fix**: Check browser GPU acceleration settings

**Issue**: Orbs not animating
**Fix**: Verify framer-motion is installed: `npm list framer-motion`

**Issue**: TypeScript errors
**Fix**: Run `npm install` to ensure types are installed

---

## Performance Testing

### iOS
```swift
// In View body
.onAppear {
    let start = CACurrentMediaTime()
    // ... animations
    let end = CACurrentMediaTime()
    print("Animation setup: \(end - start)s")
}
```

### Web
```tsx
// In useEffect
useEffect(() => {
  const start = performance.now();
  // ... animations
  const end = performance.now();
  console.log(`Animation setup: ${end - start}ms`);
}, []);
```

**Targets:**
- iOS: < 16ms (60fps)
- Web: < 16ms (60fps)
- Initial load: < 200ms

---

## Screenshot Locations

For documentation/marketing:

### iOS
1. Xcode > Product > Take Screenshot
2. Or: Simulator > File > Save Screen
3. Saves to: Desktop by default

### Web
1. Browser DevTools > Device Mode
2. Set iPhone 13 Pro resolution
3. Right-click > Save as PNG

**Recommended Screenshots:**
- Login page (clean state)
- Signup page (with validation)
- Onboarding page 1 (welcome)
- Onboarding page 4 (social)
- Success overlay
- Error state

---

## Comparison Testing

### A/B Test Setup
```swift
// iOS
@AppStorage("useEnhancedUI") var useEnhanced = Bool.random()

if useEnhanced {
    EnhancedUnifiedAuthView()
} else {
    UnifiedAuthView()
}
```

```tsx
// Web
const useEnhanced = Math.random() > 0.5;

if (useEnhanced) {
  return <EnhancedLoginPage />;
} else {
  return <OldLoginPage />;
}
```

**Metrics to Track:**
- Conversion rate
- Time to completion
- Error rate
- User preference (survey)

---

## Developer Notes

### iOS
- Uses existing `DesignSystem.swift` utilities
- No external dependencies needed
- Compatible with iOS 16.0+
- Dark mode colors automatically adapt

### Web
- Requires `framer-motion` (already installed)
- Tailwind CSS for styling
- Next.js 16.0+ compatible
- Works on all modern browsers

### Customization Points
- Brand colors: Search for `#1e40af` and `#2563eb`
- Animation timing: Search for `duration: 0.6`
- Icon sizes: Adjust `w-16 h-16` or `font(.system(size: 54))`
- Spacing: Use design system tokens

---

## Next Steps After Testing

1. **Collect Feedback**: Ask team for initial impressions
2. **Fix Issues**: Address any bugs found during testing
3. **Optimize**: Profile animation performance
4. **Document**: Take screenshots for release notes
5. **Deploy**: Roll out gradually (10% → 50% → 100%)

---

## Need Help?

- **iOS Issues**: Check Xcode console for errors
- **Web Issues**: Check browser console (F12)
- **Animation Issues**: Reduce `willChange` properties
- **Performance**: Use Instruments (iOS) or Lighthouse (Web)

For detailed documentation, see `UI_ENHANCEMENTS.md`
