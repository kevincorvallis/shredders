#!/bin/bash

# App Store Screenshot Capture Script
# Run this AFTER dismissing the location permission dialog in Simulator

set -e

SCREENSHOT_DIR="/Users/kevin/Downloads/Projects/shredders/ios/PowderTracker/AppStore/Screenshots"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  App Store Screenshot Capture${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Check if simulator is booted
if ! xcrun simctl list devices | grep -q "iPhone 16 Pro Max.*Booted"; then
    echo -e "${YELLOW}Booting iPhone 16 Pro Max...${NC}"
    xcrun simctl boot "iPhone 16 Pro Max"
    sleep 5
fi

# Set nice status bar
echo -e "${YELLOW}Setting status bar...${NC}"
xcrun simctl status_bar "iPhone 16 Pro Max" override --time "9:41" --batteryState charged --batteryLevel 100

# Create directories
mkdir -p "$SCREENSHOT_DIR/6.7-inch"

echo ""
echo -e "${GREEN}Ready to capture screenshots!${NC}"
echo ""
echo "Instructions:"
echo "1. Make sure the app is running in Simulator"
echo "2. If you see the location permission dialog, tap 'Allow While Using App'"
echo "3. Navigate to each tab and press Enter here to capture"
echo ""

capture_screenshot() {
    local name="$1"
    local filename="$2"

    echo -e "${YELLOW}Capturing: $name${NC}"
    read -p "Navigate to $name and press Enter..."

    xcrun simctl io "iPhone 16 Pro Max" screenshot "$SCREENSHOT_DIR/6.7-inch/$filename.png"
    echo -e "${GREEN}✓ Saved: $filename.png${NC}"
    echo ""
}

# Capture each screen
capture_screenshot "Today Dashboard" "01_today_dashboard"
capture_screenshot "Mountains List" "02_mountains_list"
capture_screenshot "Mountain Detail (tap a mountain)" "03_mountain_detail"
capture_screenshot "Map View" "04_map_view"
capture_screenshot "Events List" "05_events_list"
capture_screenshot "Profile" "06_profile"

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Screenshots captured!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Files saved to: $SCREENSHOT_DIR/6.7-inch/"
ls -la "$SCREENSHOT_DIR/6.7-inch/"
