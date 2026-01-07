#!/bin/bash

# Script to add arrival time feature files to Xcode project

cd /Users/kevin/Downloads/shredders/ios/PowderTracker

echo "Adding arrival time files to Xcode project..."

# Check if files exist
FILES=(
    "PowderTracker/Models/ArrivalTime.swift"
    "PowderTracker/Views/Components/ArrivalTimeCard.swift"
    "PowderTracker/Views/Components/QuickArrivalTimeBanner.swift"
)

echo ""
echo "Files to add:"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file (NOT FOUND)"
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "MANUAL STEPS TO ADD FILES TO XCODE:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. Open Xcode and navigate to PowderTracker project"
echo ""
echo "2. Add ArrivalTime.swift to Models group:"
echo "   - Right-click on 'Models' folder → 'Add Files to PowderTracker...'"
echo "   - Navigate to: PowderTracker/Models/"
echo "   - SELECT: ArrivalTime.swift"
echo "   - UNCHECK 'Copy items if needed'"
echo "   - CHECK 'Create groups'"
echo "   - SELECT target: PowderTracker"
echo "   - Click 'Add'"
echo ""
echo "3. Add UI components to Components group:"
echo "   - Right-click on 'Views/Components' folder → 'Add Files to PowderTracker...'"
echo "   - Navigate to: PowderTracker/Views/Components/"
echo "   - Hold Cmd and SELECT:"
echo "     • ArrivalTimeCard.swift"
echo "     • QuickArrivalTimeBanner.swift"
echo "   - UNCHECK 'Copy items if needed'"
echo "   - CHECK 'Create groups'"
echo "   - SELECT target: PowderTracker"
echo "   - Click 'Add'"
echo ""
echo "4. Build the project (Cmd+B) to verify everything compiles"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
