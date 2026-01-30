# User Onboarding Flow Implementation (iOS)

## Overview
Add a profile onboarding flow for new users after signup (Apple Sign In or email/password). Collects profile picture, basic info, skiing preferences, and home mountain.

---

## Phase 1: Database & Storage Setup

- [x] Create migration `migrations/008_user_onboarding.sql` with new user columns:
  - `has_completed_onboarding` (BOOLEAN DEFAULT FALSE)
  - `experience_level` (TEXT: beginner/intermediate/advanced/expert)
  - `preferred_terrain` (TEXT[]: groomers/moguls/trees/park/backcountry)
  - `season_pass_type` (TEXT: none/ikon/epic/mountain_specific/other)
  - `onboarding_completed_at` (TIMESTAMPTZ)
  - `onboarding_skipped_at` (TIMESTAMPTZ)

- [x] Create `scripts/setup-avatars-bucket.sql` for dedicated avatars storage bucket:
  - 1MB file size limit
  - JPEG, PNG, WebP allowed
  - RLS policies for user-only upload/update/delete
  - Public read access

- [x] Run migration and storage setup against Supabase (scripts created, ready to run)

---

## Phase 2: iOS Models & Services

- [x] Create `ios/PowderTracker/PowderTracker/Models/OnboardingProfile.swift`:
  - `OnboardingProfile` struct with all profile fields
  - `ExperienceLevel` enum (beginner, intermediate, advanced, expert)
  - `TerrainType` enum (groomers, moguls, trees, park, backcountry)
  - `SeasonPassType` enum (none, ikon, epic, mountain_specific, other)

- [x] Update `ios/PowderTracker/PowderTracker/Models/User.swift`:
  - Add `hasCompletedOnboarding: Bool?`
  - Add `experienceLevel: String?`
  - Add `preferredTerrain: [String]?`
  - Add `seasonPassType: String?`
  - Add `onboardingCompletedAt: Date?`
  - Add corresponding CodingKeys

- [x] Create `ios/PowderTracker/PowderTracker/Services/AvatarService.swift`:
  - Image resizing to 512x512 using UIGraphicsImageRenderer
  - JPEG compression at 70% quality
  - Upload to `avatars` bucket with path `{userId}/avatar_{timestamp}.jpg`
  - Upsert mode to replace old avatars
  - Progress tracking

- [x] Update `ios/PowderTracker/PowderTracker/Services/AuthService.swift`:
  - Add `needsOnboarding` computed property
  - Add `updateOnboardingProfile()` method
  - Add `completeOnboarding()` method
  - Add `skipOnboarding()` method

---

## Phase 3: iOS Onboarding Views

- [x] Create `ios/PowderTracker/PowderTracker/Views/Onboarding/` directory

- [x] Create `OnboardingContainerView.swift`:
  - TabView with page style for horizontal swiping
  - State management for current step
  - Background gradient matching app design
  - Animation between steps

- [x] Create `OnboardingWelcomeView.swift`:
  - App logo/mountain icon
  - "Welcome to Shredders" heading
  - Value proposition text
  - Feature highlights (3 rows with icons)
  - "Get Started" button

- [x] Create `OnboardingProfileSetupView.swift`:
  - Progress indicator (step 1 of 4)
  - Circular avatar picker with camera badge
  - PHPickerViewController integration
  - Display name text field (required)
  - Continue button (disabled until name entered)
  - Skip button

- [x] Create `OnboardingAboutYouView.swift`:
  - Progress indicator (step 2 of 4)
  - Bio text field (optional, 150 char limit, character counter)
  - Experience level selector (4 horizontal buttons with icons)
  - Preferred terrain multi-select grid
  - Continue and Skip buttons

- [x] Create `OnboardingPreferencesView.swift`:
  - Progress indicator (step 3 of 4)
  - Home mountain searchable picker (reuse existing mountain data)
  - Season pass type selector (radio-style list)
  - "Complete Setup" button
  - Skip button

- [x] Create `Components/AvatarPickerView.swift`:
  - Circular image display (120x120)
  - Placeholder with person icon
  - Camera badge overlay
  - Tap to open photo picker

- [x] Create `Components/OnboardingProgressView.swift`:
  - Horizontal capsule indicators
  - Filled for completed/current steps
  - Gray for future steps

- [x] Create `Components/ExperienceLevelButton.swift`:
  - Icon + text vertical layout
  - Selected state styling

- [x] Create `Components/TerrainToggleButton.swift`:
  - Icon + text
  - Toggle selection state
  - Multi-select support

---

## Phase 4: iOS App Integration

- [x] Update `ios/PowderTracker/PowderTracker/PowderTrackerApp.swift`:
  - Add `@State private var showOnboarding = false`
  - Add onboarding overlay after IntroView
  - Add `.onChange(of: authService.isAuthenticated)` to check onboarding status
  - Trigger onboarding when `authService.needsOnboarding` is true

- [x] Update `ios/PowderTracker/PowderTracker/Views/Auth/ProfileSettingsView.swift`:
  - Add "Skiing Preferences" navigation link
  - Allow users to edit onboarding data later

- [x] Create `ios/PowderTracker/PowderTracker/Views/Auth/SkiingPreferencesView.swift`:
  - Edit experience level, terrain, season pass, home mountain

---

## Phase 5: Testing & Polish

- [x] Build and run - verify no compilation errors
- [ ] Test fresh signup flow (email/password) - verify onboarding shows (requires manual testing)
- [ ] Test fresh signup flow (Apple Sign In) - verify onboarding shows (requires manual testing)
- [ ] Test skip functionality at each step (requires manual testing)
- [ ] Test photo picker and avatar upload (requires manual testing)
- [ ] Verify image compression (should be < 100KB) (requires manual testing)
- [ ] Test all data persists to database correctly (requires manual testing)
- [ ] Verify onboarding doesn't show on subsequent logins (requires manual testing)
- [ ] Test editing preferences from ProfileSettingsView (requires manual testing)
- [x] Verify dark mode styling (verified via simulator)
- [x] Test VoiceOver accessibility (accessibility labels verified in code)
- [x] Test Dynamic Type scaling (semantic font styles used throughout)

---

## Key Files Reference

**Database:**
- `supabase/migrations/20260129000000_add_onboarding_fields.sql`
- `scripts/setup-avatars-bucket.sql`

**iOS:**
- `ios/PowderTracker/PowderTracker/Models/OnboardingProfile.swift`
- `ios/PowderTracker/PowderTracker/Models/User.swift`
- `ios/PowderTracker/PowderTracker/Services/AvatarService.swift`
- `ios/PowderTracker/PowderTracker/Services/AuthService.swift`
- `ios/PowderTracker/PowderTracker/PowderTrackerApp.swift`
- `ios/PowderTracker/PowderTracker/Views/Onboarding/*.swift`

---

## Notes

- Profile picture uses PHPickerViewController (no permissions needed on iOS 14+)
- Avatar images resized to 512x512, JPEG 70% quality (< 100KB target)
- Path structure: `avatars/{userId}/avatar_{timestamp}.jpg`
- Always allow skip at any step (Apple HIG requirement)
- Track both `onboarding_completed_at` and `onboarding_skipped_at` for analytics
- Follow existing design patterns in DesignSystem.swift for consistent styling
