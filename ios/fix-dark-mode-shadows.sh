#!/bin/bash

# Fix black shadows to use adaptive color
cd /Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker/Views

FILES=(
    "Components/BestPowderTodayCard.swift"
    "Components/MountainTimelineCard.swift"
    "Components/MountainCardRow.swift"
    "Components/SnowDepthChart.swift"
    "Components/SnowTimelineView.swift"
    "Components/SnowSummarySection.swift"
    "Components/MountainConditionsCard.swift"
    "Components/ConditionsCard.swift"
    "Components/LiftStatusCard.swift"
    "Location/SnowDepthSection.swift"
    "Location/LocationMapSection.swift"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Fixing shadows in $file..."
        # Replace .black.opacity with Color(.label).opacity in shadow calls
        sed -i '' 's/\.shadow(color: \.black\.opacity/\.shadow(color: Color(.label).opacity/g' "$file"
        sed -i '' 's/color: \.black\.opacity/color: Color(.label).opacity/g' "$file"
    fi
done

echo "✅ Fixed dark mode shadows!"
