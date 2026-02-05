# Ski Iconic Elements - Usage Guide

Quick reference for using the new ski-themed UI components in PowderTracker.

---

## Import

All components are in the main module, no special imports needed:

```swift
// Components are automatically available in any SwiftUI view
```

---

## Lift Ticket Card Style

Transform any card into an authentic lift ticket with perforated edges.

### Basic Usage
```swift
VStack {
    Text("Mt. Baker")
        .font(.headline)
    Text("Powder Alert!")
        .font(.caption)
}
.padding()
.liftTicketStyle()
```

### With Barcode
```swift
VStack {
    Text("Season Pass")
    Text("2024-2025")
}
.padding()
.liftTicketStyle(showPerforation: true, showBarcode: true)
```

### Without Perforation
```swift
EventCard(event)
    .liftTicketStyle(showPerforation: false)
```

**When to Use:**
- Event cards for special promotions
- Season pass displays
- Ticket purchase confirmations
- Featured mountain cards

---

## Snow Quality Badge

Display current snow conditions with icon and color.

### Standard Size
```swift
SnowQualityBadge(quality: .powder)
```

### Compact (for tight spaces)
```swift
SnowQualityBadge(quality: .groomed, size: .compact)
```

### Large (for emphasis)
```swift
SnowQualityBadge(quality: .packedPowder, size: .large)
```

### Available Qualities
```swift
SnowQuality.powder        // ❄️  Cyan - "Fresh, fluffy snow"
SnowQuality.packedPowder  // 📦 Blue - "Firm, well-packed surface"
SnowQuality.groomed       // ≡  Mint - "Machine-groomed corduroy"
SnowQuality.hardPack      // ▪️  Indigo - "Compressed, firm snow"
SnowQuality.icy           // 💧 Slate - "Hard, icy conditions"
SnowQuality.slushy        // 💦 Purple - "Wet, spring snow"
SnowQuality.variable      // ☁️  Orange - "Mixed conditions"
```

**When to Use:**
- Check-in forms (select snow quality)
- Condition reports on mountain detail pages
- Weather dashboard summary
- Trip report displays

---

## Lift Type Icons

Show chairlift type with status and capacity.

### Basic Lift Icon
```swift
LiftTypeIcon(type: .chairlift)
```

### With Status
```swift
LiftTypeIcon(type: .highSpeedQuad, status: .open, size: 28)
```

### Lift Status Options
```swift
.open      // Green - Lift is operating
.closed    // Red - Lift is closed
.hold      // Orange - Temporarily stopped
.scheduled // Blue - Opens later today
```

### Available Lift Types
```swift
.chairlift      // Basic chairlift
.highSpeedQuad  // 4-person express (with bolt ⚡)
.sixPack        // 6-person express (with bolt ⚡)
.gondola        // Enclosed 8+ capacity (with bolt ⚡)
.bubbleChair    // Chairlift with bubble cover
.tram           // Large aerial tram 100+ (with bolt ⚡)
.surfaceLift    // Rope tow, T-bar
.magicCarpet    // Beginner conveyor belt
.tBar           // T-bar surface lift
.ropeTow        // Rope tow
```

**When to Use:**
- Lifts tab showing all lift statuses
- Mountain detail page (quick lift count)
- Trail map overlays
- Lift status notifications

---

## Trail Feature Badges

Indicate terrain type or special features.

### With Label
```swift
TrailFeatureBadge(feature: .moguls)
```

### Icon Only
```swift
TrailFeatureBadge(feature: .groomed, showLabel: false)
```

### Available Features
```swift
.moguls       // 🔴 Orange - Bumpy terrain
.groomed      // 🔵 Blue - Smooth corduroy
.glades       // 🟢 Green - Tree skiing
.bowls        // 🟦 Cyan - Open bowls
.steeps       // 🔴 Red - Steep terrain
.terrainPark  // 🟣 Purple - Jumps/features
.halfPipe     // 🟣 Purple - Superpipe
.rails        // 🟣 Purple - Rails & boxes
.catTrack     // ⚪ Gray - Flat traverse
.traverse     // ⚪ Gray - Sideways path
```

**When to Use:**
- Trail descriptions
- Run recommendations
- Trail map filters
- Feature highlights on mountain pages

---

## Elevation Badges

Display mountain elevations with proper formatting.

### Summit Elevation
```swift
ElevationBadge(elevation: 10781, type: .summit)
// Shows: "△ 10,781' Summit"
```

### Base Elevation
```swift
ElevationBadge(elevation: 4200, type: .base)
// Shows: "△ 4,200' Base"
```

### Vertical Drop
```swift
ElevationBadge(elevation: 6581, type: .verticalDrop)
// Shows: "↕ 6,581' Vert"
```

### All Three Together
```swift
HStack(spacing: 12) {
    ElevationBadge(elevation: mountain.summitElevation, type: .summit)
    ElevationBadge(elevation: mountain.baseElevation, type: .base)
    ElevationBadge(elevation: mountain.verticalDrop, type: .verticalDrop)
}
```

**When to Use:**
- Mountain stats section
- Mountain comparison grids
- Quick info headers
- Trip planning elevation displays

---

## Chairlift Loading Animation

Replace generic spinners with themed loading indicator.

### Basic Loading
```swift
ChairliftLoadingView()
// Shows: Animated chairlift with "Loading..."
```

### Custom Message
```swift
ChairliftLoadingView("Fetching conditions...")
ChairliftLoadingView("Updating snow report...")
ChairliftLoadingView("Loading webcams...")
```

**When to Use:**
- Data fetching states
- Image loading placeholders
- Initial app launch
- Background refresh indicators

---

## Goggle View Toggle

Toggle between compact and expanded views with ski goggle styling.

### Basic Toggle
```swift
@State private var isCompact = false

GoggleViewToggle(isCompact: $isCompact)
```

### In Toolbar
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        GoggleViewToggle(isCompact: $viewModel.isCompactMode)
    }
}
```

**When to Use:**
- List vs. grid view toggles
- Compact vs. detailed mode
- Map vs. list view switchers
- Filter panel show/hide

---

## Ski Pass Badge

Display season pass information.

### Basic Badge
```swift
SkiPassBadge(passName: "Ikon Pass", resortCount: 50)
```

### Multiple Passes
```swift
VStack(alignment: .leading, spacing: 8) {
    SkiPassBadge(passName: "Ikon Pass", resortCount: 50)
    SkiPassBadge(passName: "Epic Pass", resortCount: 42)
    SkiPassBadge(passName: "Mountain Collective", resortCount: 23)
}
```

**When to Use:**
- Profile settings (linked passes)
- Mountain detail page (valid passes)
- Trip planning (pass suggestions)
- Account management

---

## Enhanced Skill Level Badge

Already existing component, now with authentic ski trail markers.

### Standard Badge
```swift
SkillLevelBadge(level: .intermediate)
// Shows: "🟦 Blue" (blue square)
```

### Icon Only
```swift
SkillLevelBadge(level: .advanced, showLabel: false)
// Shows: "◆" (black diamond only)
```

### Size Variants
```swift
SkillLevelBadge(level: .expert, size: .compact)
SkillLevelBadge(level: .beginner, size: .standard)
SkillLevelBadge(level: .all, size: .large)
```

### Standalone Icon
```swift
SkiTrailIcon(level: .advanced, size: 20)
// Just the diamond icon, no badge background
```

**Skill Levels:**
```swift
.beginner      // 🟢 Green Circle
.intermediate  // 🟦 Blue Square
.advanced      // ◆ Black Diamond
.expert        // ◆◆ Double Black Diamond
.all           // 🟢🟦◆ All three icons
```

---

## Real-World Examples

### Mountain Card with Elevation and Conditions
```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Mt. Baker")
        .font(.title2)
        .fontWeight(.bold)

    HStack(spacing: 12) {
        ElevationBadge(elevation: 10781, type: .summit)
        ElevationBadge(elevation: 4200, type: .base)
        ElevationBadge(elevation: 6581, type: .verticalDrop)
    }

    SnowQualityBadge(quality: .powder, size: .large)

    Text("Epic powder day! 14\" overnight")
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
.padding()
.liftTicketStyle(showBarcode: true)
```

### Event Card with Skill Level
```swift
VStack(alignment: .leading) {
    HStack {
        Text("Backcountry Tour")
            .font(.headline)
        Spacer()
        SkillLevelBadge(level: .expert, size: .compact)
    }

    Text("Saturday, Feb 10 • 7:00 AM")
        .font(.caption)
        .foregroundStyle(.secondary)

    HStack {
        TrailFeatureBadge(feature: .glades, showLabel: false)
        TrailFeatureBadge(feature: .steeps, showLabel: false)
        TrailFeatureBadge(feature: .bowls, showLabel: false)
    }
}
.padding()
.liftTicketStyle()
```

### Lift Status Board
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
    ForEach(lifts) { lift in
        VStack(spacing: 8) {
            LiftTypeIcon(type: lift.type, status: lift.status, size: 32)

            Text(lift.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)

            Text(lift.status == .open ? "Open" : "Closed")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
.padding()
```

### Loading State with Context
```swift
if isLoading {
    ChairliftLoadingView("Checking lift status...")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
} else {
    ConditionsContent()
}
```

### View Mode Toggle in Toolbar
```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        HStack(spacing: 12) {
            GoggleViewToggle(isCompact: $viewModel.isCompactMode)

            Button("Filters") {
                showFilters.toggle()
            }
        }
    }
}
```

---

## Accessibility Notes

All components include:
- ✅ Accessibility labels
- ✅ Descriptive hints
- ✅ Dynamic Type support
- ✅ VoiceOver compatible
- ✅ Color + icon (not color alone)

Example VoiceOver reads:
- `SnowQualityBadge(.powder)` → "Snow quality: Powder, Fresh, fluffy snow"
- `LiftTypeIcon(.gondola, status: .open)` → "Gondola, Open"
- `ElevationBadge(10781, .summit)` → "Summit elevation: 10781 feet"
- `SkillLevelBadge(.expert)` → "Skill level: Expert, double black diamond runs"

---

## Performance Tips

1. **Use size variants** - Don't scale badges with `.scaleEffect()`, use built-in sizes
2. **Reuse instances** - Components are lightweight, but cache in LazyVGrid/List
3. **Avoid nesting** - Don't wrap badges in multiple containers
4. **Prefer enums** - Use `SnowQuality.powder` not string "powder"

---

## Design System Integration

These components follow PowderTracker's design system:

- **8pt Grid** - All padding uses multiples of 4 or 8
- **SF Symbols** - Native icons for system consistency
- **Semantic Colors** - Adapt to light/dark mode automatically
- **Haptic Feedback** - Interactive elements provide tactile response
- **Capsule Shapes** - Consistent with existing badge styles

---

## Testing in Xcode Previews

All components have preview providers. To test in Xcode:

1. Open `/Views/Components/Primitives/SkiIconicElements.swift`
2. Resume preview canvas (Cmd + Option + Return)
3. View all component variations
4. Test light/dark mode toggle
5. Check accessibility inspector

Preview names:
- `#Preview("Lift Ticket Style")`
- `#Preview("Snow Quality")`
- `#Preview("Lift Types")`
- `#Preview("Trail Features")`
- `#Preview("Elevation Badges")`
- `#Preview("Loading & Toggle")`

---

## Questions?

**Where to add these components?**
→ See recommendations in `SKI_ICONIC_ELEMENTS_VERIFICATION.md`

**Can I customize colors?**
→ Yes, but prefer using built-in color schemes for consistency

**Need more lift types?**
→ Add to `LiftType` enum and submit PR

**Performance concerns?**
→ All components are lightweight SwiftUI primitives, no heavy assets

---

**Happy shredding! 🎿**
