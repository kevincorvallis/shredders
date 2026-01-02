# Where to Find the New Features

## 🎯 Quick Answer

**Radial Dashboard**: Tap the "Radial View" toggle button at the top
**Lift Line Predictor**: Scroll down - it's right below the main card

---

## 📱 Step-by-Step Guide

### Finding the Radial Dashboard

1. **Run the app** (Cmd+R in Xcode)
2. **Tap any mountain** from the list
3. **Look at the very top** of the screen
4. You'll see **two pill-shaped buttons**:
   ```
   [At a Glance]  [Radial View]
   ```
5. **Tap "Radial View"** (the right button)
6. **Watch the animation!** The card slides out and the radial dashboard slides in

**What you'll see:**
- Center: Big powder score number (pulsing)
- Inner ring: Snow accumulation (blue segments for 24h/48h/72h)
- Middle ring: Weather (temperature on left, wind on right)
- Outer ring: Lifts (top) and roads (bottom)
- Tap any ring to see expanded details!

---

### Finding the Lift Line Predictor

1. **From the same mountain detail screen**
2. **Scroll down** just a little bit
3. **Right below** the main visualization (radial or glance card)
4. You'll see a card with:
   ```
   ┌─────────────────────────────────────┐
   │ Lift Line Forecast    [AI PREDICTED]│
   │                                     │
   │  [Icon] BUSY                        │
   │         Overall Mountain            │
   │         ~12 min typical wait        │
   │                                     │
   │  [Busyness meter with 6 bars]       │
   │                                     │
   │  ℹ️ Epic powder conditions •        │
   │     Weekend crowds                  │
   │                                     │
   │  [Show Lift-by-Lift Predictions ▼] │
   └─────────────────────────────────────┘
   ```

5. **Tap "Show Lift-by-Lift Predictions"** to see detailed breakdown:
   - Main Express Lifts
   - Powder/Summit Lifts
   - Beginner Area
   - Side/Alternative Lifts
   - Gondola/Enclosed Lifts

**⚠️ Important Note**:
The Lift Line Predictor only shows if the mountain has lift status data. If you don't see it, try a different mountain.

---

## 🧪 Test Mountains

Mountains most likely to have all features:
- **Mt. Baker** ✅
- **Crystal Mountain** ✅
- **Stevens Pass** ✅
- **Snoqualmie** ✅

---

## 🔍 Full Screen Layout

Here's what you should see when viewing a mountain:

```
┌─────────────────────────────────────────┐
│ ← [Mountain Name]                       │ Navigation bar
├─────────────────────────────────────────┤
│                                         │
│ [At a Glance] [Radial View] ← TOGGLE!  │ Line 36
│                                         │
├─────────────────────────────────────────┤
│                                         │
│   MAIN VISUALIZATION                    │ Lines 40-48
│   (Either At a Glance OR Radial)        │ Switch with toggle!
│                                         │
│   Default: At a Glance Card             │
│   ┌───────────────────────────────────┐ │
│   │ ⭐ POWDER SCORE: 8.5               │ │
│   │      "Epic"                       │ │
│   ├───────┬─────────┬────────────────┤ │
│   │ SNOW  │ WEATHER │ LIFTS          │ │
│   │ 12"   │ 28°F    │ 88% open       │ │
│   │ 85"   │ 15 mph  │ 10/11          │ │
│   │ Fresh │ Calm    │ Open           │ │
│   └───────┴─────────┴────────────────┘ │
│                                         │
│   Tap "Radial View" to see rings! ↑    │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│   LIFT LINE PREDICTOR                   │ Lines 50-54
│   ┌───────────────────────────────────┐ │
│   │ Lift Line Forecast  [AI PREDICTED]│ │
│   │                                   │ │
│   │ [Icon] BUSY                       │ │
│   │        Overall Mountain           │ │
│   │        ~12 min typical wait       │ │
│   │                                   │ │
│   │ [Busyness meter ████░░]           │ │
│   │                                   │ │
│   │ ℹ️ Epic powder • Weekend crowds   │ │
│   │                                   │ │
│   │ [Show Lift-by-Lift Predictions ▼] │ │
│   └───────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│   [Show More Details ▼]                 │ Lines 57-75
│                                         │
├─────────────────────────────────────────┤
│        (Scroll down to see)             │
│                                         │
│   When expanded:                        │
│   • Snow Depth Section                  │
│   • Weather Conditions                  │
│   • Map                                 │
│   • Road Conditions                     │
│   • Webcams                             │
│                                         │
└─────────────────────────────────────────┘
```

---

## 🎬 What to Expect

### At a Glance View (Default)
- **Loads first** when you open a mountain
- Compact card with 3 columns
- Tap any column (Snow, Weather, Lifts) to expand it
- Shows powder score at top
- Most info visible without scrolling

### Radial View (Tap Toggle)
- **Slides in** when you tap "Radial View"
- Animated rings that fill up based on conditions
- Pulsing powder score in center
- Tap any ring to see details below
- Very visual and dynamic!

### Lift Line Predictor
- **Always visible** (if mountain has lift data)
- Shows overall busyness at the top
- Tap "Show Lift-by-Lift Predictions" for breakdown
- Each lift type has:
  - Estimated wait time
  - Busyness level (Empty → Packed)
  - Color-coded indicator
  - Reason for prediction
  - Confidence score

---

## 🐛 Troubleshooting

### "I don't see the toggle buttons!"
- Make sure you're on a **mountain detail screen** (not the main list)
- They're at the **very top**, right below the navigation bar
- Try scrolling all the way to the top

### "I don't see the Lift Line Predictor!"
- It only shows if the mountain has lift status data
- Try a different mountain (Mt. Baker, Crystal, Stevens)
- Check the API - the mountain might not have live lift data yet

### "The radial dashboard looks weird!"
- It might be loading - wait a second for the animation
- Try running on a device instead of simulator for better performance
- Make sure you tapped "Radial View" (not "At a Glance")

### "Nothing is showing up!"
- Check that the app built successfully (Cmd+B)
- Try cleaning build folder (Shift+Cmd+K) then rebuild
- Make sure you're connected to the internet (data loads from API)

---

## 💡 Pro Tips

1. **Try both views!** Radial and Glance offer different perspectives on the same data
2. **Tap everything!** Most sections are interactive
3. **Watch the animations!** The radial dashboard has smooth entry animations
4. **Check different times!** The lift line predictor changes based on time of day
5. **Try weekends vs weekdays!** The predictions adapt to day of week

---

## 🎥 Expected Behavior

When you switch views:
1. **Tap "Radial View"** button
2. Current card **slides out to the left** (with fade)
3. Radial dashboard **slides in from the right** (with fade)
4. Rings **animate from 0% → full** (takes ~1 second)
5. Powder score **pulses** in the center

---

**If you're still not seeing them, try:**
1. Pull to refresh on the mountain detail screen
2. Close and reopen the app
3. Try a different mountain
4. Check Xcode console for any errors

Need more help? The code is in `/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views/Location/LocationView.swift` starting at line 35.
