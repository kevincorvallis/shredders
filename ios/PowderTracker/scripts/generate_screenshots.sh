#!/bin/bash

# App Store Screenshot Generator for PowderTracker
# Generates screenshots for all required device sizes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCREENSHOT_DIR="$PROJECT_DIR/AppStore/Screenshots"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Required device sizes for App Store
# iPhone 6.7" - iPhone 15 Pro Max, 16 Pro Max (1290 x 2796)
# iPhone 6.5" - iPhone 11 Pro Max, XS Max (1242 x 2688)
# iPhone 5.5" - iPhone 8 Plus, 7 Plus, 6s Plus (1242 x 2208)
# iPad 12.9" - iPad Pro 12.9" (2048 x 2732)

DEVICES=(
    "iPhone 16 Pro Max:6.7-inch"
    "iPhone 15 Pro:6.1-inch"
    "iPad Pro 13-inch (M4):12.9-inch"
)

# Screens to capture
SCREENS=(
    "Today:today_dashboard"
    "Mountains:mountains_list"
    "Mountain Detail:mountain_detail"
    "Map:map_weather"
    "Events:events_list"
    "Profile:profile"
)

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  App Store Screenshot Generator${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Create screenshot directories
mkdir -p "$SCREENSHOT_DIR"
for device in "${DEVICES[@]}"; do
    size="${device#*:}"
    mkdir -p "$SCREENSHOT_DIR/$size"
done

echo -e "${YELLOW}Building app for screenshots...${NC}"

# Build the app
cd "$PROJECT_DIR"
xcodebuild -scheme PowderTracker \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' \
    -quiet \
    build

echo -e "${GREEN}✓ Build complete${NC}"

# Function to take screenshot
take_screenshot() {
    local device="$1"
    local size="$2"
    local screen_name="$3"
    local filename="$4"

    local output_path="$SCREENSHOT_DIR/$size/${filename}.png"

    echo -e "  Capturing $screen_name on $device..."

    # Take screenshot using simctl
    xcrun simctl io "$device" screenshot "$output_path" 2>/dev/null || {
        echo -e "  ${YELLOW}Warning: Could not capture $screen_name${NC}"
        return 1
    }

    echo -e "  ${GREEN}✓${NC} Saved: $output_path"
}

# Get device UDIDs
get_device_udid() {
    local device_name="$1"
    xcrun simctl list devices | grep "$device_name" | grep -oE '[A-F0-9-]{36}' | head -1
}

echo ""
echo -e "${YELLOW}Starting screenshot capture...${NC}"
echo ""

# For now, capture on the currently booted simulator
BOOTED_DEVICE=$(xcrun simctl list devices | grep "Booted" | grep -oE '[A-F0-9-]{36}' | head -1)

if [ -z "$BOOTED_DEVICE" ]; then
    echo -e "${YELLOW}No simulator booted. Booting iPhone 16 Pro Max...${NC}"
    BOOTED_DEVICE=$(get_device_udid "iPhone 16 Pro Max")
    xcrun simctl boot "$BOOTED_DEVICE" 2>/dev/null || true
    sleep 5
fi

DEVICE_NAME=$(xcrun simctl list devices | grep "$BOOTED_DEVICE" | sed 's/.*(\(.*\)) (.*/\1/' | head -1)
echo -e "Using device: ${BLUE}$DEVICE_NAME${NC} ($BOOTED_DEVICE)"
echo ""

# Install and launch the app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "PowderTracker.app" -path "*/Debug-iphonesimulator/*" | head -1)

if [ -n "$APP_PATH" ]; then
    echo -e "${YELLOW}Installing app...${NC}"
    xcrun simctl install booted "$APP_PATH"

    echo -e "${YELLOW}Launching app...${NC}"
    xcrun simctl launch booted com.shredders.powdertracker
    sleep 3
fi

# Manual screenshot instructions
echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Manual Screenshot Instructions${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo "The app is now running. Please take screenshots manually:"
echo ""
echo "1. Today Tab (Dashboard) - Shows powder scores and recommendations"
echo "2. Mountains Tab - List of mountains with conditions"
echo "3. Mountain Detail - Tap a mountain to see details"
echo "4. Map Tab - Weather map with overlays"
echo "5. Events Tab - Trip planning and events"
echo "6. Profile Tab - User profile and settings"
echo ""
echo "To take a screenshot:"
echo "  xcrun simctl io booted screenshot ~/Desktop/screenshot.png"
echo ""
echo "Or press Cmd+S in Simulator to save to Desktop"
echo ""

# Take automatic screenshots of current state
echo -e "${YELLOW}Taking automatic screenshots of current screen...${NC}"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_DIR="$SCREENSHOT_DIR/6.7-inch"

# Take screenshot of current state
xcrun simctl io booted screenshot "$OUTPUT_DIR/01_current_${TIMESTAMP}.png" 2>/dev/null && \
    echo -e "${GREEN}✓${NC} Saved initial screenshot"

echo ""
echo -e "${GREEN}Screenshots will be saved to:${NC}"
echo "  $SCREENSHOT_DIR"
echo ""
echo -e "${YELLOW}Tip: Run on multiple simulators for different device sizes${NC}"
echo ""

# List devices that should be used
echo -e "${BLUE}Required device sizes for App Store:${NC}"
echo "  • iPhone 6.7\" (iPhone 16 Pro Max) - REQUIRED"
echo "  • iPhone 6.5\" (iPhone 11 Pro Max) - Optional"
echo "  • iPad 12.9\" (iPad Pro) - REQUIRED for iPad"
echo ""
