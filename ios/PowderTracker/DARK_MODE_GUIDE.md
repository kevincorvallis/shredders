# Dark Mode Implementation Guide

## Overview

This guide documents the comprehensive dark mode implementation for PowderTracker iOS app, ensuring perfect visibility and contrast across all UI components.

## Key Improvements Made

### 1. MountainLogoView - Adaptive Logo Display ✅

**File:** `PowderTracker/Views/Components/MountainLogoView.swift`

**Features:**
- **Three rendering styles:**
  - `.circle` - Original circular clipped style
  - `.rounded` - Rounded rectangle with padding
  - `.adaptive` (default) - Smart adaptive container with contrast-aware backgrounds

- **Dark mode adaptations:**
  - Light background (`systemGray5`) in dark mode for logo visibility
  - Very light background (`systemGray6`) in light mode
  - Adaptive borders with subtle contrast
  - Shadows only in light mode
  - Brightness/contrast adjustments for logos

**Usage:**
```swift
// Default adaptive style (recommended)
MountainLogoView(
    logoUrl: mountain.logo,
    color: mountain.color,
    size: 60
)

// Specific style
MountainLogoView(
    logoUrl: mountain.logo,
    color: mountain.color,
    size: 60,
    style: .rounded
)
```

**Color Scheme Handling:**
```swift
@Environment(\.colorScheme) private var colorScheme

private var logoBackground: Color {
    switch colorScheme {
    case .dark:
        return Color(UIColor.systemGray5)  // Light in dark mode
    case .light:
        return Color(UIColor.systemGray6)  // Light gray in light mode
    @unknown default:
        return Color(UIColor.systemBackground)
    }
}
```

## Dark Mode Best Practices

### 1. Use Environment Color Scheme

Always detect the current color scheme:

```swift
@Environment(\.colorScheme) private var colorScheme
```

### 2. Use Semantic Colors

Prefer semantic colors that auto-adapt:

```swift
// ✅ Good - Auto-adapts
Text("Title")
    .foregroundColor(.primary)      // Black in light, white in dark
    .background(Color(UIColor.systemBackground))

// ❌ Avoid - Hardcoded
Text("Title")
    .foregroundColor(.black)
    .background(.white)
```

**Available Semantic Colors:**
- `.primary` - Main text color
- `.secondary` - Secondary text
- `.tertiary` - Tertiary text
- `Color(UIColor.systemBackground)` - Main background
- `Color(UIColor.secondarySystemBackground)` - Content background
- `Color(UIColor.tertiarySystemBackground)` - Grouped content background
- `Color(UIColor.systemGray)` through `Color(UIColor.systemGray6)` - Adaptive grays

### 3. Adaptive Backgrounds for Images

For images with varying colors (logos, photos):

```swift
AsyncImage(url: imageURL) { image in
    image
        .resizable()
        .scaledToFit()
        .padding(12)
} placeholder: {
    ProgressView()
}
.background(
    RoundedRectangle(cornerRadius: 12)
        .fill(colorScheme == .dark
            ? Color(UIColor.systemGray5)
            : Color(UIColor.systemGray6))
)
```

### 4. Borders for Visibility

Add subtle borders to ensure elements are visible:

```swift
.overlay(
    RoundedRectangle(cornerRadius: 12)
        .stroke(
            colorScheme == .dark
                ? Color.white.opacity(0.1)
                : Color.black.opacity(0.05),
            lineWidth: 0.5
        )
)
```

### 5. Adaptive Shadows

Only show shadows in light mode:

```swift
.shadow(
    color: colorScheme == .dark
        ? Color.clear
        : Color.black.opacity(0.1),
    radius: 4,
    y: 2
)
```

### 6. Brightness/Contrast Adjustments

For images that need enhancement in dark mode:

```swift
image
    .brightness(colorScheme == .dark ? 0.05 : 0)
    .contrast(colorScheme == .dark ? 1.05 : 1.0)
```

## Common Patterns

### Pattern 1: Adaptive Card Background

```swift
.background(
    RoundedRectangle(cornerRadius: 16)
        .fill(Color(UIColor.secondarySystemBackground))
)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(
            colorScheme == .dark
                ? Color.white.opacity(0.1)
                : Color.black.opacity(0.05),
            lineWidth: 1
        )
)
```

### Pattern 2: Badge with Adaptive Background

```swift
Text("LIVE")
    .font(.caption2)
    .fontWeight(.bold)
    .foregroundColor(.white)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
        Capsule()
            .fill(colorScheme == .dark
                ? Color.red.opacity(0.8)
                : Color.red)
    )
```

### Pattern 3: Gradient with Adaptive Opacity

```swift
LinearGradient(
    colors: [
        Color(hex: mountain.color)?.opacity(colorScheme == .dark ? 0.3 : 0.2) ?? .blue,
        Color(hex: mountain.color)?.opacity(0.05) ?? .blue.opacity(0.05)
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

## Testing Dark Mode

### In Xcode Previews

Test both light and dark modes:

```swift
#Preview("Light & Dark Comparison") {
    Group {
        MyView()
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")

        MyView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
```

### In Simulator

1. **Toggle dark mode:** Settings → Developer → Dark Appearance
2. **Quick toggle:** Three-finger tap while Accessibility Shortcuts is enabled
3. **Command:** `xcrun simctl ui booted appearance dark`

## Known Issues & Fixes

### Issue: White logos invisible in light mode

**Fix:** Use adaptive backgrounds

```swift
// Before
AsyncImage(url: logoURL)

// After
AsyncImage(url: logoURL) { image in
    image.resizable()
}
.background(Color(UIColor.systemGray6))
```

### Issue: Black text on dark background

**Fix:** Use semantic colors

```swift
// Before
.foregroundColor(.black)

// After
.foregroundColor(.primary)  // Auto-adapts
```

### Issue: Shadows visible in dark mode

**Fix:** Conditional shadows

```swift
.shadow(
    color: colorScheme == .dark ? .clear : .black.opacity(0.1),
    radius: 4
)
```

## Component Checklist

When creating new components, ensure:

- [ ] Import `@Environment(\.colorScheme)` if needed
- [ ] Use semantic colors (`.primary`, `.secondary`, etc.)
- [ ] Test in both light and dark mode previews
- [ ] Add adaptive backgrounds for images/logos
- [ ] Use adaptive borders/shadows
- [ ] Check contrast ratios (4.5:1 for text, 3:1 for UI)
- [ ] Handle AsyncImage failure states
- [ ] Use `Color(UIColor.system*)` for adaptive colors

## Resources

- [Apple HIG - Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- [Apple HIG - Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [SwiftUI Color Documentation](https://developer.apple.com/documentation/swiftui/color)

## Migration Guide

### Updating Existing Components

1. Add color scheme environment variable:
```swift
@Environment(\.colorScheme) private var colorScheme
```

2. Replace hardcoded colors:
```swift
// Before
.background(.white)

// After
.background(Color(UIColor.systemBackground))
```

3. Add adaptive image backgrounds:
```swift
// Before
AsyncImage(url: url)

// After
AsyncImage(url: url) { image in
    image.resizable()
}
.background(logoBackground)
```

4. Test in previews:
```swift
#Preview {
    MyView()
        .preferredColorScheme(.dark)
}
```

## Performance Notes

- Color scheme detection has negligible performance impact
- System colors are optimized by iOS
- Adaptive backgrounds don't affect rendering performance
- Use `@Environment(\.colorScheme)` over multiple calls to `UITraitCollection`

---

**Last Updated:** January 27, 2026
**Author:** Claude Opus 4.5
