#!/bin/bash

# App Store Screenshot Capture Script
# Supports iPhone and iPad screenshots

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOT_DIR="$PROJECT_DIR/AppStore/Screenshots"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Device to use (default: iPhone for 6.7")
DEVICE="${1:-iphone}"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  App Store Screenshot Capture${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Set device-specific variables
case "$DEVICE" in
    iphone|phone)
        SIMULATOR_NAME="iPhone 16 Pro Max"
        SIZE_DIR="6.7-inch"
        ;;
    ipad|tablet)
        SIMULATOR_NAME="iPad Pro 13-inch (M4)"
        SIZE_DIR="12.9-inch"
        ;;
    *)
        echo -e "${RED}Unknown device: $DEVICE${NC}"
        echo "Usage: $0 [iphone|ipad]"
        exit 1
        ;;
esac

echo -e "Device: ${BLUE}$SIMULATOR_NAME${NC}"
echo ""

# Check if simulator is booted
if ! xcrun simctl list devices | grep -q "$SIMULATOR_NAME.*Booted"; then
    echo -e "${YELLOW}Booting $SIMULATOR_NAME...${NC}"
    xcrun simctl boot "$SIMULATOR_NAME" 2>/dev/null || true
    sleep 5
fi

# Set nice status bar
echo -e "${YELLOW}Setting status bar...${NC}"
xcrun simctl status_bar "$SIMULATOR_NAME" override --time "9:41" --batteryState charged --batteryLevel 100 2>/dev/null || true

# Create directories
mkdir -p "$SCREENSHOT_DIR/$SIZE_DIR"

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

    xcrun simctl io "$SIMULATOR_NAME" screenshot "$SCREENSHOT_DIR/$SIZE_DIR/$filename.png"
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
echo "Files saved to: $SCREENSHOT_DIR/$SIZE_DIR/"
ls -la "$SCREENSHOT_DIR/$SIZE_DIR/"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
if [ "$DEVICE" = "iphone" ] || [ "$DEVICE" = "phone" ]; then
    echo "  Run '$0 ipad' to capture iPad screenshots"
fi
echo "  Upload to App Store Connect"
