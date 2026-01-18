# Powder Score Algorithm Documentation

## Overview
The Powder Score is a comprehensive 0-10 rating that evaluates skiing/snowboarding conditions based on multiple weighted factors. The algorithm uses a three-tier scoring system (Primary, Secondary, Tertiary) with additional modifiers.

## Core Formula
```
Final Score = (Primary × 0.60) + (Secondary × 0.25) + (Tertiary × 0.15) + Modifiers
```

Each category is scored 0-10 internally, then weighted according to its importance.

---

## Primary Factors (60% of total score)

### 1. 24h Snowfall (40% of Primary = 24% of total)
**Most important factor for powder quality**

| Snowfall Amount | Score |
|----------------|-------|
| 0"             | 0     |
| ≤3"            | 4     |
| ≤6"            | 6     |
| ≤12"           | 8     |
| 18"+           | 10    |

**Implementation:** Linear interpolation between breakpoints
- Perfect powder day: 12"+ of fresh snow

### 2. Snow Density (30% of Primary = 18% of total)
**Estimates snow quality based on temperature and humidity**

| Conditions | Water Content | Score | Description |
|-----------|---------------|-------|-------------|
| Temp >32°F OR Humidity >85% | >12% | 2 | Heavy, wet snow |
| Temp 28-32°F, Humidity 70-80% | 8-12% | 5 | Medium density |
| Temp 25-32°F, Humidity <70% | 5-8% | 8 | Light powder |
| Temp <25°F, Humidity <60% | <5% | 10 | Champagne powder |

**Implementation:** Estimated from available temperature and humidity data
- Ideal: Cold, dry conditions produce the lightest powder

### 3. Freshness (30% of Primary = 18% of total)
**How recently the snow fell**

| Time Window | Score | Logic |
|------------|-------|-------|
| 0-6 hours | 10 | 24h snowfall ≥ 2× (48h - 24h) |
| 6-12 hours | 8 | 24h snowfall ≥ (48h - 24h) |
| 12-24 hours | 6 | 24h snowfall > 0 |
| 24-48 hours | 4 | (48h - 24h) > 0 |
| 48-72 hours | 2 | 72h snowfall > 0 |
| 72+ hours | 0 | No recent snow |

**Implementation:** Analyzes the ratio of 24h vs 48h snowfall to estimate timing
- Perfect: Snow fell within the last 6 hours

---

## Secondary Factors (25% of total score)

### 1. Wind Speed (40% of Secondary = 10% of total)
**Wind affects powder quality and skiability**

| Wind Speed (mph) | Score | Conditions |
|-----------------|-------|------------|
| 0-5 | 10 | Calm, perfect |
| 5-15 | 7 | Light winds |
| 15-25 | 4 | Moderate winds |
| 25+ | 1 | Strong winds |

**Implementation:** Uses wind gusts if available (gust × 0.8)
- High winds create wind-loaded slopes and poor visibility

### 2. Temperature (35% of Secondary = 8.75% of total)
**Ideal temperature for powder preservation**

| Temperature (°F) | Score | Quality |
|-----------------|-------|---------|
| <15 | 10 | Cold & dry (champagne) |
| 15-25 | 8 | Ideal range |
| 25-32 | 5 | Good |
| 32+ | 2 | Warm (risk of wet snow) |

**Implementation:** Direct scoring based on current temperature
- Ideal range: 15-25°F for best snow quality

### 3. Aspect (25% of Secondary = 6.25% of total)
**Sun exposure and wind loading by slope direction**

| Aspect | Score | Characteristics |
|--------|-------|----------------|
| North | 10 | Best preservation, no sun |
| NE/NW | 8 | Good, minimal sun |
| East/West | 5 | Moderate sun exposure |
| SE/SW | 3 | More sun exposure |
| South | 1 | Maximum sun, faster melt |

**Implementation:** Currently uses neutral score (7) - can be enhanced with wind direction data
- North-facing slopes hold powder longer

---

## Tertiary Factors (15% of total score)

### 1. Base Depth (30% of Tertiary = 4.5% of total)
**Overall snowpack depth**

| Base Depth (inches) | Score | Coverage |
|--------------------|-------|----------|
| <24" | 3 | Limited base |
| 24-48" | 6 | Good coverage |
| 48-72" | 8 | Deep base |
| 72"+ | 10 | Excellent base |

**Implementation:** Direct measurement from SNOTEL data
- Deeper base = fewer hazards, better skiing

### 2. Sky Conditions (35% of Tertiary = 5.25% of total)
**Cloud cover and visibility**

| Condition | Cloud Cover | Score |
|-----------|-------------|-------|
| Overcast/Snowing | ≥70% | 10 |
| Partly Cloudy | 40-70% | 6 |
| Bluebird/Clear | <40% | 3 |

**Implementation:** Based on NOAA sky cover percentage
- Overcast preserves powder; sunny days melt faster (but better visibility)

### 3. Crowd Factor (35% of Tertiary = 5.25% of total)
**Expected crowd levels**

| Day & Time | Score | Expected Crowds |
|-----------|-------|-----------------|
| Weekday + Early (<9am) | 10 | Minimal crowds |
| Weekday | 7 | Light crowds |
| Weekend + Early (<8am) | 5 | Moderate crowds |
| Weekend Midday | 2 | Peak crowds |

**Implementation:** Real-time calculation based on current day/hour
- First tracks get untracked powder

---

## Modifiers (Applied After Base Calculation)

These adjust or cap the final score:

### 1. No New Snow in 72h+
- **Condition:** `snowfall24h === 0 AND snowfall48h === 0`
- **Effect:** Cap score at 3 maximum
- **Reason:** Old, tracked-out snow

### 2. High Winds
- **Condition:** Wind > 30mph sustained
- **Effect:** −2 penalty
- **Reason:** Dangerous conditions, poor visibility, wind crust

### 3. Rain Event
- **Condition:** Rain risk score < 4 (freezing level below summit)
- **Effect:** Cap score at 2 maximum
- **Reason:** Rain-damaged snow, wet conditions

### 4. Storm Cycling (Bonus)
- **Condition:** 48h snowfall > 24"
- **Effect:** +1 bonus
- **Reason:** Multiple storm waves = continuous fresh snow

---

## Score Interpretation

| Score | Verdict | Recommendation |
|-------|---------|----------------|
| 8-10 | SEND IT! Epic powder conditions! | Drop everything and go |
| 6-7.9 | Great day for skiing - fresh snow awaits! | Excellent conditions |
| 4-5.9 | Decent conditions - groomed runs will be good | Good skiing |
| 1-3.9 | Consider waiting for better conditions | Marginal |

---

## Data Sources

1. **SNOTEL Stations** (USDA)
   - Snow depth
   - 24h, 48h, 7-day snowfall
   - Temperature (backup)

2. **NOAA Weather.gov** (Gridded Data)
   - Current temperature
   - Wind speed and gusts
   - Humidity
   - Sky cover
   - Visibility
   - Precipitation probability

3. **Open-Meteo API**
   - Freezing level (for rain risk)
   - Rain/snow line calculations

4. **Real-time Calculations**
   - Crowd factor (day/time)
   - Snow density estimation
   - Freshness timing

---

## Example Calculation

### Perfect Powder Day
```
Conditions:
- 12" fresh snow (24h)
- 15" total (48h)
- Temperature: 20°F
- Humidity: 55%
- Wind: 8 mph
- Base: 60"
- Overcast, weekday 7am

Primary (60%):
  Snowfall: 8 × 0.24 = 1.92
  Density: 10 × 0.18 = 1.80
  Freshness: 10 × 0.18 = 1.80
  Total: 5.52

Secondary (25%):
  Wind: 7 × 0.10 = 0.70
  Temp: 10 × 0.0875 = 0.875
  Aspect: 7 × 0.0625 = 0.4375
  Total: 2.01

Tertiary (15%):
  Base: 8 × 0.045 = 0.36
  Sky: 10 × 0.0525 = 0.525
  Crowd: 10 × 0.0525 = 0.525
  Total: 1.41

Base Score: 5.52 + 2.01 + 1.41 = 8.94
Modifiers: None
Final Score: 8.9 → "SEND IT! Epic powder conditions!"
```

---

## Algorithm Updates

**Version:** 2.0 (December 2025)
**Changes:**
- Restructured to three-tier weighted system
- Added snow density estimation
- Added freshness timing analysis
- Added crowd factor (time-based)
- Added comprehensive modifiers
- Improved rain risk integration

**Previous Version:** 1.0
- Simple weighted average of 5-7 factors
- Less sophisticated scoring
