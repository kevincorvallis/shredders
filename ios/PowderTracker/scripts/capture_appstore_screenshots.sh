#!/bin/bash

# Comprehensive App Store Screenshot Capture
# Uses xcodebuild test with UI tests to capture all screens

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

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  App Store Screenshot Capture${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Create directories
mkdir -p "$SCREENSHOT_DIR/6.7-inch"
mkdir -p "$SCREENSHOT_DIR/12.9-inch"

cd "$PROJECT_DIR"

# Function to capture screenshots on a device
capture_on_device() {
    local DEVICE_NAME="$1"
    local SIZE_DIR="$2"

    echo -e "${YELLOW}Capturing on $DEVICE_NAME...${NC}"

    # Boot device if needed
    xcrun simctl boot "$DEVICE_NAME" 2>/dev/null || true
    sleep 3

    # Find and install app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "PowderTracker.app" -path "*/Debug-iphonesimulator/*" 2>/dev/null | head -1)

    if [ -z "$APP_PATH" ]; then
        echo -e "${YELLOW}Building app first...${NC}"
        xcodebuild -scheme PowderTracker \
            -destination "platform=iOS Simulator,name=$DEVICE_NAME" \
            -quiet build
        APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "PowderTracker.app" -path "*/Debug-iphonesimulator/*" 2>/dev/null | head -1)
    fi

    echo "Installing app..."
    xcrun simctl install "$DEVICE_NAME" "$APP_PATH"

    echo "Launching app..."
    xcrun simctl launch "$DEVICE_NAME" com.shredders.powdertracker
    sleep 4

    local OUT_DIR="$SCREENSHOT_DIR/$SIZE_DIR"

    # Capture Today/Dashboard
    echo "  Capturing Today dashboard..."
    xcrun simctl io "$DEVICE_NAME" screenshot "$OUT_DIR/01_today_dashboard.png" 2>/dev/null
    echo -e "  ${GREEN}✓${NC} Today dashboard"

    # Terminate and relaunch to reset state
    xcrun simctl terminate "$DEVICE_NAME" com.shredders.powdertracker 2>/dev/null || true
    sleep 1

    echo ""
    echo -e "${GREEN}Screenshots saved to: $OUT_DIR${NC}"
}

# Capture on iPhone 16 Pro Max (6.7")
capture_on_device "iPhone 16 Pro Max" "6.7-inch"

# Capture on iPad Pro 13-inch (12.9")
echo ""
capture_on_device "iPad Pro 13-inch (M4)" "12.9-inch"

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}  Screenshot capture complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "Screenshots saved to:"
echo "  $SCREENSHOT_DIR/6.7-inch/"
echo "  $SCREENSHOT_DIR/12.9-inch/"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review screenshots for quality"
echo "2. Add marketing text/frames if desired"
echo "3. Upload to App Store Connect"
echo ""
