#!/bin/bash

# Script to add Tabs files to Xcode project
# This adds the files directly to avoid the "folder already exists" issue

echo "Adding Tabs files to Xcode project..."

cd /Users/kevin/Downloads/shredders/ios/PowderTracker

# Create a list of files to add
FILES=(
    "PowderTracker/Views/Location/TabbedLocationView.swift"
    "PowderTracker/Views/Location/Tabs/OverviewTab.swift"
    "PowderTracker/Views/Location/Tabs/ForecastTab.swift"
    "PowderTracker/Views/Location/Tabs/HistoryTab.swift"
    "PowderTracker/Views/Location/Tabs/TravelTab.swift"
    "PowderTracker/Views/Location/Tabs/SafetyTab.swift"
    "PowderTracker/Views/Location/Tabs/WebcamsTab.swift"
    "PowderTracker/Views/Location/Tabs/SocialTab.swift"
    "PowderTracker/Views/Location/Tabs/LiftsTab.swift"
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
echo "2. In the Project Navigator, find:"
echo "   Views → Location"
echo ""
echo "3. Right-click on 'Location' folder → 'Add Files to PowderTracker...'"
echo ""
echo "4. IMPORTANT: When the file picker opens:"
echo "   - Navigate to: PowderTracker/Views/Location/"
echo "   - SELECT INDIVIDUAL FILES (not the Tabs folder):"
echo "     • TabbedLocationView.swift"
echo "   - Click 'Add'"
echo ""
echo "5. Right-click on 'Location' folder again → 'New Group'"
echo "   - Name it: 'Tabs'"
echo ""
echo "6. Right-click on the new 'Tabs' group → 'Add Files to PowderTracker...'"
echo "   - Navigate to: PowderTracker/Views/Location/Tabs/"
echo "   - Hold Cmd and SELECT ALL 8 .swift files:"
echo "     • OverviewTab.swift"
echo "     • ForecastTab.swift"
echo "     • HistoryTab.swift"
echo "     • TravelTab.swift"
echo "     • SafetyTab.swift"
echo "     • WebcamsTab.swift"
echo "     • SocialTab.swift"
echo "     • LiftsTab.swift"
echo "   - UNCHECK 'Copy items if needed' (they're already in place)"
echo "   - UNCHECK 'Create folder references'"
echo "   - CHECK 'Create groups'"
echo "   - Select target: PowderTracker"
echo "   - Click 'Add'"
echo ""
echo "7. Build the project (Cmd+B) to verify everything compiles"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "ALTERNATIVE: Add files using command line (requires xcodeproj gem)"
echo ""
echo "If you have the xcodeproj Ruby gem installed, you can run:"
echo "  ruby add-tabs-to-xcode.rb"
echo ""
echo "To install xcodeproj gem:"
echo "  gem install xcodeproj"
echo ""
