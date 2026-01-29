# PowderTracker Design System

A comprehensive design system for the PowderTracker iOS app, following Apple Human Interface Guidelines and modern SwiftUI best practices.

## Quick Start

```swift
import SwiftUI

// Use design tokens for consistent spacing
VStack(spacing: .spacingM) {
    Text("Mountain Name")
        .cardTitle()

    Text("85")
        .heroNumber()
}
.standardCard()
```

---

## Spacing System (8pt Grid)

All spacing uses multiples of 8pt for visual consistency.

| Token | Value | Usage |
|-------|-------|-------|
| `.spacingXS` | 4pt | Micro-spacing within grouped elements |
| `.spacingS` | 8pt | Tight spacing between related items |
| `.spacingM` | 12pt | Default card padding (recommended) |
| `.spacingL` | 16pt | Section padding, between-card spacing |
| `.spacingXL` | 20pt | Major section breaks |
| `.spacingXXL` | 24pt | Hero sections, screen margins |

```swift
VStack(spacing: .spacingM) {
    // content
}
.padding(.spacingL)
```

---

## Corner Radius

| Token | Value | Usage |
|-------|-------|-------|
| `.cornerRadiusTiny` | 4pt | Progress bars, tiny indicators |
| `.cornerRadiusMicro` | 6pt | Small pills and badges |
| `.cornerRadiusButton` | 8pt | Buttons, action items |
| `.cornerRadiusSmall` | 10pt | Compact cards, input fields |
| `.cornerRadiusCard` | 12pt | Standard cards (default) |
| `.cornerRadiusHero` | 16pt | Hero/featured cards |
| `.cornerRadiusBubble` | 18pt | Chat bubbles |
| `.cornerRadiusPill` | 20pt | Pills, large rounded elements |

### Concentric Radius

For nested elements, use concentric radius calculation:

```swift
// Child radius = Parent radius - padding
let childRadius = CGFloat.concentricRadius(parent: .cornerRadiusCard, padding: .spacingM)
```

---

## Typography

### View Modifiers

| Modifier | Font | Weight | Usage |
|----------|------|--------|-------|
| `.heroNumber()` | Large Title | Bold, Rounded | Powder scores, big numbers |
| `.sectionHeader()` | Headline | Semibold | Section titles |
| `.cardTitle()` | Title 3 | Semibold | Card headings |
| `.metric()` | Subheadline | Semibold | Stat labels |
| `.badge()` | Caption 2 | Bold | Small badges |
| `.metricValue()` | Subheadline | Semibold, Rounded, Monospaced | Numeric values |

```swift
Text("85")
    .heroNumber()  // Large, bold, rounded for scores

Text("Powder Score")
    .metric()  // Smaller label

Text("24\"")
    .metricValue()  // Monospaced digits prevent layout shift
```

### Animated Numbers

```swift
Text("\(score)")
    .animatedNumber()  // Uses .contentTransition(.numericText())
```

---

## Cards & Containers

### Card Modifiers

```swift
// Standard card (most common)
content.standardCard()

// Hero card (featured content)
content.heroCard()

// List item card (compact)
content.listCard()

// Status pill with color
Text("OPEN").statusPill(color: .green)
```

### Glassmorphic Cards

```swift
// Glass background with blur
content.glassBackground()

// Full glass card with border and shadow
content.glassCard()
```

---

## Shadows

### Basic Shadows

```swift
view.cardShadow()   // Subtle (radius: 6, opacity: 0.08)
view.heroShadow()   // Elevated (radius: 12, opacity: 0.12)
```

### Adaptive Shadow (Dark Mode)

```swift
@Environment(\.colorScheme) var colorScheme

view.adaptiveShadow(colorScheme: colorScheme)
```

### Glow Effect

```swift
view.glowEffect(color: .blue, radius: 8)
```

---

## Colors

### Status Colors

```swift
// Powder score color (0-10 scale)
Color.forPowderScore(8.5)  // Green (≥8), Yellow (6-8), Orange (4-6), Red (<4)

// Lift percentage
Color.forLiftPercentage(75)  // Green (≥80%), Yellow (50-80%), etc.

// Temperature (Fahrenheit)
Color.forTemperature(28)  // Blue (<20), Cyan (20-32), Green (32-40), Orange (≥40)

// Wind speed (mph)
Color.forWindSpeed(15)  // Green (<10), Yellow (10-20), Orange (20-30), Red (≥30)

// Snow depth (inches)
Color.forSnowDepth(85)  // Green (≥100), Blue (60-100), Yellow (30-60), Orange (<30)
```

### Adaptive Colors

Always use system colors for dark mode compatibility:

```swift
Color(UIColor.systemGreen)  // ✓ Adapts to dark mode
Color.green  // ✗ May not adapt properly
```

---

## Animations

### Spring Presets

| Animation | Response | Damping | Usage |
|-----------|----------|---------|-------|
| `.standardSpring` | 0.3s | 0.7 | General UI interactions |
| `.bouncy` | 0.4s | 0.6 | Playful (cards, buttons) |
| `.snappy` | 0.25s | 0.8 | Quick changes (toggles) |
| `.smooth` | 0.5s | 0.85 | Elegant (modals, sheets) |
| `.interactive` | 0.15s | 0.86 | Immediate feedback |

```swift
withAnimation(.bouncy) {
    isFavorite.toggle()
}
```

### Accessibility-Safe Animations

```swift
// Respects "Reduce Motion" setting
view.accessibleAnimation(.bouncy, value: someValue)
view.accessibleSpring(response: 0.3, dampingFraction: 0.7)
```

---

## Icons (SkiIcon)

Semantic icon system using SF Symbols:

### Categories

- **Weather**: `.snowfall`, `.temperature`, `.wind`, `.storm`
- **Mountain**: `.mountain`, `.trail`, `.terrain`, `.trees`
- **Lifts**: `.lift`, `.liftOpen`, `.liftClosed`, `.gondola`
- **Actions**: `.favorite`, `.share`, `.navigate`, `.refresh`
- **Status**: `.open`, `.closed`, `.trendingUp`, `.trendingDown`

### Usage

```swift
// As a view
SkiIconView(icon: .snowfall, size: 24)

// Get SF Symbol name
Image(systemName: SkiIcon.mountain.systemName)

// With default color
SkiIconView(icon: .liftOpen, useDefaultColor: true)  // Green
```

### Animated Weather Icons

```swift
AnimatedSnowflakeIcon()
AnimatedWindIcon()
AnimatedSunIcon()
AnimatedWeatherIcon(condition: "snow")
```

---

## Buttons

### Glassmorphic Button Styles

```swift
Button("Primary Action") { }
    .buttonStyle(.glassmorphic)

Button("Secondary Action") { }
    .buttonStyle(.glassmorphicSecondary)
```

### Navigation Button (with haptic)

```swift
Button("Go to Detail") { }
    .buttonStyle(.navigation)
```

---

## Haptic Feedback

```swift
// Trigger haptics
HapticFeedback.selection()   // Tab changes, picker selections
HapticFeedback.light()       // Card taps, minor interactions
HapticFeedback.medium()      // Button presses, toggles
HapticFeedback.success()     // Favorite added, action completed
HapticFeedback.warning()     // Limit reached, validation error
HapticFeedback.error()       // Action failed, network error

// Automatically respects "Reduce Haptics" setting
```

---

## Gradients

### Preset Gradients

```swift
LinearGradient.powderBlue      // Blue to purple (snow conditions)
LinearGradient.sunnyDay        // Yellow to orange (clear weather)
LinearGradient.freshSnow       // White to light blue (powder)
LinearGradient.nightSki        // Dark blue to purple (evening)
```

### Gradient Pills

```swift
Text("POWDER DAY")
    .gradientPill(gradient: .powderBlue)

Text("85%")
    .gradientStatusPill(color: .green)
```

---

## Loading States

### Skeleton Views

```swift
SkeletonRoundedRect(height: 100)
SkeletonCircle(size: 40)
SkeletonText(width: 120)
```

### Shimmer Effect

```swift
view.shimmerPlaceholder(isLoading: isLoading)
view.loadingPlaceholder(isLoading: isLoading)
```

---

## Sheet Presentation

```swift
.sheet(isPresented: $showSheet) {
    SheetContent()
        .modernSheetStyle()  // Drag indicator, corner radius, material background
}

// Interactive sheet (can tap through)
.modernSheetStyleInteractive()
```

---

## Scroll Effects

### Scroll Transition

```swift
ForEach(items) { item in
    ItemCard(item: item)
        .scrollTransition { content, phase in
            content
                .opacity(phase.isIdentity ? 1 : 0.8)
                .scaleEffect(phase.isIdentity ? 1 : 0.95)
        }
}
```

### Velocity-Based Blur

```swift
ScrollView {
    content
}
.velocityBlur()  // Blurs content on fast scroll
```

---

## Accessibility

### Reduce Motion Support

```swift
// Check setting
if !UIAccessibility.isReduceMotionEnabled {
    // Perform animation
}

// Or use accessibility-safe modifiers
view.accessibleAnimation(.bouncy, value: value)
view.respectsReduceMotion()
```

### Accessibility Labels

```swift
Image(systemName: "star.fill")
    .accessibilityLabel("Favorite")
    .accessibilityHint("Double tap to remove from favorites")
```

---

## Best Practices

1. **Always use design tokens** - Never use magic numbers for spacing/radius
2. **Use system colors** - Ensures dark mode compatibility
3. **Respect accessibility** - Check Reduce Motion before animating
4. **Use semantic icons** - SkiIcon provides consistent iconography
5. **Apply haptics thoughtfully** - Use appropriate feedback types
6. **Test both themes** - Verify light and dark mode appearance

---

## File Reference

- `Utilities/DesignSystem.swift` - All design tokens and helpers
- `Utilities/HapticFeedback.swift` - Haptic feedback system
- `Views/Components/SkeletonView.swift` - Loading skeletons
