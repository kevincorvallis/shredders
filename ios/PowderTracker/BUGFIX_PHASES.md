# PookieBSnow Bug Fix Phases

This document outlines the bugs discovered in the iOS app and organizes them into phases for systematic fixing via Ralph Loop.

---

## Overview

**Total Issues Found:** 16
**Critical:** 2
**High:** 2
**Medium:** 9
**Low:** 3

---

## Phase 1: Critical Memory & UX Blockers ✅ COMPLETE
*Estimated Time: 30-45 minutes*

These bugs can cause app crashes, memory leaks, or completely block users from completing signup.

### 1.1 Timer Memory Leak in PookieBSnowIntroView ✅ FIXED
**Severity:** CRITICAL
**File:** `Views/PookieBSnowIntroView.swift` (Line 657)

**Problem:**
```swift
Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
    guard showIntro else {
        timer.invalidate()
        return
    }
    // ...
}
```
- Timer reference is never stored
- Timer continues running even after intro is dismissed
- Causes permanent memory leak and battery drain

**Fix:**
1. Add a `@State private var heartTimer: Timer?` property
2. Store the timer reference when created
3. Add `.onDisappear { heartTimer?.invalidate() }`
4. Also invalidate in `dismissWithHaptic()`

---

### 1.2 Silent Onboarding Failure (No Error Display) ✅ FIXED
**Severity:** CRITICAL
**File:** `Views/Onboarding/OnboardingContainerView.swift` (Lines 110-128)

**Problem:**
```swift
} catch {
    await MainActor.run {
        isCompleting = false
    }
    HapticFeedback.error.trigger()
    // ERROR IS SILENTLY DISCARDED - USER SEES NOTHING
}
```
- When `completeOnboarding()` fails, error is swallowed
- User stuck on screen with no feedback
- No retry option

**Fix:**
1. Add `@State private var errorMessage: String? = nil`
2. Add `@State private var showError = false`
3. Set error message in catch block
4. Add `.alert("Error", isPresented: $showError)` with retry button
5. Show meaningful error message to user

---

## Phase 2: Data Integrity & Error Handling ✅ COMPLETE
*Estimated Time: 30-40 minutes*

These bugs can cause data loss or leave users in broken states.

### 2.1 Avatar Upload Fails Silently ✅ FIXED
**Severity:** HIGH
**File:** `Views/Onboarding/OnboardingProfileSetupView.swift` (Lines 156-161)

**Problem:**
```swift
} catch {
    await MainActor.run {
        isUploadingAvatar = false
        onContinue()  // Proceeds anyway!
    }
    HapticFeedback.error.trigger()
}
```
- Avatar upload failure is ignored
- User thinks photo uploaded when it didn't
- Comment literally says "Continue anyway"

**Fix:**
1. Add `@State private var avatarError: String? = nil`
2. Show error alert when upload fails
3. Give user option to retry or skip
4. Don't auto-proceed on failure

---

### 2.2 Race Condition in Onboarding Completion ✅ ADDRESSED (Error handling added)
**Severity:** HIGH
**File:** `Views/Onboarding/OnboardingContainerView.swift` (Lines 110-120)

**Problem:**
```swift
try await authService.updateOnboardingProfile(profile)  // Step 1
try await authService.completeOnboarding()              // Step 2
```
- If Step 1 succeeds but Step 2 fails, profile is saved but user isn't marked complete
- User may be stuck in limbo state
- No rollback mechanism

**Fix:**
1. Wrap both operations in a single transaction if possible
2. Or: Add validation that Step 1 succeeded before Step 2
3. Add rollback logic if Step 2 fails
4. Consider combining into single API call

---

### 2.3 No Retry Logic for Profile Updates ✅ FIXED
**Severity:** MEDIUM
**File:** `Services/AuthService.swift` (Lines 702-748)

**Problem:**
- Network failures cause immediate onboarding failure
- No automatic retry for transient errors
- Poor UX on flaky connections

**Fix:**
1. Add simple retry wrapper with 2-3 attempts
2. Add exponential backoff (1s, 2s, 4s)
3. Show "Retrying..." message to user
4. Only fail after all retries exhausted

---

## Phase 3: Layout & Responsive Design ✅ COMPLETE
*Estimated Time: 45-60 minutes*

These bugs cause UI overflow, clipping, or broken layouts on certain devices.

### 3.1 OnboardingProfileSetupView Missing ScrollView ✅ FIXED
**Severity:** MEDIUM
**File:** `Views/Onboarding/OnboardingProfileSetupView.swift`

**Problem:**
```swift
VStack(spacing: .spacingXL) {
    // No ScrollView wrapper
    Spacer()
    // Content...
    Spacer()
}
```
- Content overflows on iPhone SE / 12 mini
- Keyboard pushes content off screen
- Buttons may be hidden behind home indicator

**Fix:**
1. Wrap entire `VStack` in `ScrollView`
2. Remove `Spacer()` calls and use proper padding
3. Add `.safeAreaInset(edge: .bottom)` for button
4. Test on iPhone SE simulator

---

### 3.2 PookieBSnowWelcomeView Hardcoded Frame Height ✅ FIXED
**Severity:** MEDIUM
**File:** `Views/Onboarding/PookieBSnowWelcomeView.swift` (Line 65)

**Problem:**
```swift
.frame(minHeight: UIScreen.main.bounds.height - 100)
```
- Uses `UIScreen.main.bounds` which ignores safe area
- Hardcoded `-100` is arbitrary
- Breaks on landscape, iPad, and split-screen

**Fix:**
1. Use `GeometryReader` to get actual available space
2. Account for safe area insets
3. Remove arbitrary `-100` offset
4. Test on iPad and landscape

---

### 3.3 OnboardingAboutYouView Layout Issues ✅ FIXED (Added safeAreaInset for buttons)
**Severity:** MEDIUM
**File:** `Views/Onboarding/OnboardingAboutYouView.swift`

**Problem:**
- Similar to ProfileSetupView - no ScrollView
- Fixed spacing doesn't adapt to screen size
- Selection buttons may be cut off on small screens

**Fix:**
1. Add `ScrollView` wrapper
2. Ensure all content is accessible on iPhone SE
3. Test with Dynamic Type at largest sizes

---

### 3.4 OnboardingPreferencesView Layout Issues ✅ FIXED (Added safeAreaInset for buttons)
**Severity:** MEDIUM
**File:** `Views/Onboarding/OnboardingPreferencesView.swift`

**Problem:**
- Mountain picker and pass type buttons need scrolling
- Long lists may overflow
- No visible scrollbar for users

**Fix:**
1. Ensure proper `ScrollView` usage
2. Add scroll indicators
3. Test with many mountains in picker

---

### 3.5 Inconsistent Spacing (Design System Violations)
**Severity:** LOW
**Files:** Multiple onboarding views

**Problem:**
```swift
.padding(.bottom, 24)   // Hardcoded
.padding(.bottom, 32)   // Hardcoded
// vs
.padding(.bottom, .spacingXL)  // Design system token
```
- Mix of hardcoded values and design tokens
- Inconsistent with 8pt grid
- Doesn't adapt for accessibility

**Fix:**
1. Replace all hardcoded padding with design tokens
2. Use `.spacingS`, `.spacingM`, `.spacingL`, `.spacingXL`, `.spacingXXL`
3. Follow 8pt grid consistently

---

## Phase 4: Keyboard & Input Handling ✅ COMPLETE
*Estimated Time: 20-30 minutes*

These bugs cause friction when users interact with text fields.

### 4.1 No Keyboard Dismissal Strategy ✅ FIXED
**Severity:** LOW
**File:** `Views/Onboarding/OnboardingProfileSetupView.swift`

**Problem:**
```swift
TextField("How should we call you?", text: $displayName)
    .textFieldStyle(.plain)
    // NO: .submitLabel(.continue)
    // NO: .onSubmit { }
```
- No way to dismiss keyboard via return key
- User must tap outside to dismiss
- Minor but frustrating UX issue

**Fix:**
1. Add `.submitLabel(.continue)` to TextField
2. Add `.onSubmit { focusNextField() }` handler
3. Add `@FocusState` for keyboard management
4. Consider adding "Done" button in toolbar

---

### 4.2 TextField Not Auto-Focused on Appear ✅ FIXED
**Severity:** LOW
**File:** `Views/Onboarding/OnboardingProfileSetupView.swift`

**Problem:**
- User must manually tap text field to start typing
- Keyboard doesn't auto-appear

**Fix:**
1. Add `@FocusState private var isNameFocused: Bool`
2. Add `.focused($isNameFocused)` to TextField
3. Set `isNameFocused = true` in `.onAppear`

---

## Phase 5: Code Quality & Consistency ✅ COMPLETE
*Estimated Time: 20-30 minutes*

These are minor issues that improve code quality and prevent future bugs.

### 5.1 Missing AuthService in OnboardingAboutYouView ✅ FIXED
**Severity:** LOW
**File:** `Views/Onboarding/OnboardingAboutYouView.swift`

**Problem:**
```swift
struct OnboardingAboutYouView: View {
    @Binding var profile: OnboardingProfile
    let onContinue: () -> Void
    let onSkip: () -> Void
    // Missing: let authService: AuthService
}
```
- Inconsistent with sibling views
- May need auth service for future features

**Fix:**
1. Add `let authService: AuthService` parameter
2. Update call site in `OnboardingContainerView`
3. Keep consistent API across all onboarding views

---

### 5.2 User ID Fallback Logic Could Be Clearer ✅ FIXED
**Severity:** LOW
**File:** `Views/Onboarding/OnboardingProfileSetupView.swift` (Line 142)

**Problem:**
```swift
guard let userId = authService.currentUser?.id.uuidString ?? authService.userProfile?.authUserId else {
```
- Fallback order is confusing
- `currentUser?.id` vs `userProfile?.authUserId` may return different things

**Fix:**
1. Prefer `userProfile?.authUserId` as primary source
2. Add comment explaining the fallback order
3. Consider asserting they match in debug builds

---

### 5.3 Profile Data Not Pre-Populated on Re-Entry (DEFERRED)
**Severity:** LOW
**File:** `Views/Onboarding/OnboardingProfileSetupView.swift`

**Problem:**
- If user leaves onboarding and returns, data may be lost
- Only falls back to `authService.userProfile`

**Status:** Deferred to future enhancement - requires UserDefaults integration for partial state persistence.

**Fix:**
1. Store partial onboarding state in UserDefaults
2. Restore on re-entry
3. Clear after successful completion

---

## Phase 6: Testing & Verification
*Estimated Time: 30-45 minutes*

After fixing bugs, verify on all device sizes.

### 6.1 Device Testing Checklist

Test on these simulators:
- [ ] iPhone SE (3rd generation) - smallest screen
- [ ] iPhone 15 Pro - standard
- [ ] iPhone 15 Pro Max - large screen
- [ ] iPad Pro 11" - tablet layout

### 6.2 Flow Testing Checklist

- [ ] Fresh signup with email/password
- [ ] Signup with Apple Sign In
- [ ] Complete full onboarding flow
- [ ] Skip onboarding flow
- [ ] Cancel and restart onboarding
- [ ] Network error during onboarding
- [ ] Avatar upload success
- [ ] Avatar upload failure

### 6.3 Layout Testing Checklist

- [ ] Rotate device during onboarding
- [ ] Enable Dynamic Type (largest size)
- [ ] Enable Reduce Motion accessibility
- [ ] Enable Bold Text accessibility
- [ ] Test with keyboard visible

---

## Quick Reference: Files to Modify

| Phase | Files |
|-------|-------|
| 1 | `PookieBSnowIntroView.swift`, `OnboardingContainerView.swift` |
| 2 | `OnboardingProfileSetupView.swift`, `OnboardingContainerView.swift`, `AuthService.swift` |
| 3 | `OnboardingProfileSetupView.swift`, `PookieBSnowWelcomeView.swift`, `OnboardingAboutYouView.swift`, `OnboardingPreferencesView.swift` |
| 4 | `OnboardingProfileSetupView.swift` |
| 5 | `OnboardingAboutYouView.swift`, `OnboardingProfileSetupView.swift` |
| 6 | Testing only - no code changes |

---

## Ralph Loop Instructions

When running the Ralph Loop, use these prompts for each phase:

### Phase 1 Prompt:
```
Fix the critical bugs in Phase 1 of BUGFIX_PHASES.md:
1. Fix the timer memory leak in PookieBSnowIntroView.swift
2. Add error display and retry to OnboardingContainerView.swift
Build after each fix to verify.
```

### Phase 2 Prompt:
```
Fix the data integrity bugs in Phase 2 of BUGFIX_PHASES.md:
1. Handle avatar upload failures with user feedback
2. Fix race condition in onboarding completion
3. Add retry logic for profile updates
Build after each fix to verify.
```

### Phase 3 Prompt:
```
Fix the layout bugs in Phase 3 of BUGFIX_PHASES.md:
1. Add ScrollView to OnboardingProfileSetupView
2. Fix hardcoded frame height in PookieBSnowWelcomeView
3. Fix layout issues in OnboardingAboutYouView and OnboardingPreferencesView
4. Replace hardcoded spacing with design tokens
Test on iPhone SE simulator after fixes.
```

### Phase 4 Prompt:
```
Fix keyboard handling in Phase 4 of BUGFIX_PHASES.md:
1. Add proper keyboard dismissal
2. Add auto-focus to text fields
3. Add submit handlers
```

### Phase 5 Prompt:
```
Fix code quality issues in Phase 5 of BUGFIX_PHASES.md:
1. Add authService to OnboardingAboutYouView for consistency
2. Clarify user ID fallback logic
3. Add partial state persistence for onboarding
```

### Phase 6 Prompt:
```
Run through the testing checklist in Phase 6 of BUGFIX_PHASES.md.
Test on iPhone SE, iPhone 15 Pro, and iPad simulators.
Report any remaining issues found.
```

---

## Success Criteria

The signup/onboarding flow is considered fixed when:

1. ✅ No memory leaks in intro screen
2. ✅ Errors are displayed to users with retry options
3. ✅ Avatar upload failures show feedback
4. ✅ All screens scroll properly on iPhone SE
5. ✅ Keyboard handling is smooth
6. ✅ Onboarding completes successfully
7. ✅ Profile data is saved correctly
8. ✅ No layout overflow on any device size

---

*Last Updated: January 2025*
*Created for PookieBSnow by Kevin & Beryl (and Brock 🐕)*
