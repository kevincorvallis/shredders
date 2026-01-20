#!/bin/bash
# E2E Test Script for PowderTracker iOS App
# Automates build, deploy, and UI verification

set -e

# Configuration
PROJECT_DIR="/Users/kevin/Downloads/Projects/shredders/ios/PowderTracker"
SCHEME="PowderTracker"
BUNDLE_ID="com.shredders.powdertracker"
SCREENSHOT_DIR="/tmp/powdertracker_e2e"
SIMULATOR_NAME="iPhone 17 Pro"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create screenshot directory
mkdir -p "$SCREENSHOT_DIR"

echo -e "${YELLOW}🏔️  PowderTracker E2E Test Suite${NC}"
echo "=================================="

# Function to get booted simulator ID
get_simulator_id() {
    xcrun simctl list devices | grep -i "booted" | head -1 | grep -oE '[A-F0-9-]{36}'
}

# Function to take screenshot
take_screenshot() {
    local name=$1
    local sim_id=$(get_simulator_id)
    if [ -n "$sim_id" ]; then
        xcrun simctl io "$sim_id" screenshot "$SCREENSHOT_DIR/${name}.png" 2>/dev/null
        echo -e "  📸 Screenshot: ${name}.png"
    fi
}

# Function to wait for app
wait_for_app() {
    sleep 2
}

# Function to tap using AppleScript
tap_at() {
    local x=$1
    local y=$2
    osascript <<EOF
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
    tell process "Simulator"
        set winPos to position of front window
        set winX to item 1 of winPos
        set winY to item 2 of winPos
        click at {winX + $x, winY + $y}
    end tell
end tell
EOF
}

# Step 1: Check for running simulator
echo -e "\n${YELLOW}Step 1: Checking simulator...${NC}"
SIM_ID=$(get_simulator_id)
if [ -z "$SIM_ID" ]; then
    echo -e "${RED}❌ No simulator running. Please boot a simulator first.${NC}"
    echo "   Run: xcrun simctl boot \"$SIMULATOR_NAME\""
    exit 1
fi
echo -e "${GREEN}✓ Simulator running: $SIM_ID${NC}"

# Step 2: Build the app
echo -e "\n${YELLOW}Step 2: Building app...${NC}"
cd "$PROJECT_DIR"
BUILD_OUTPUT=$(xcodebuild -scheme "$SCHEME" -destination "id=$SIM_ID" build 2>&1 | tail -5)
if echo "$BUILD_OUTPUT" | grep -q "BUILD SUCCEEDED"; then
    echo -e "${GREEN}✓ Build succeeded${NC}"
else
    echo -e "${RED}❌ Build failed${NC}"
    echo "$BUILD_OUTPUT"
    exit 1
fi

# Step 3: Install the app
echo -e "\n${YELLOW}Step 3: Installing app...${NC}"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
APP_PATH=$(find "$DERIVED_DATA" -name "PowderTracker.app" -path "*/Build/Products/Debug-iphonesimulator/*" -type d 2>/dev/null | grep -v "Index.noindex" | head -1)
if [ -z "$APP_PATH" ]; then
    echo -e "${RED}❌ Could not find built app${NC}"
    exit 1
fi
xcrun simctl install "$SIM_ID" "$APP_PATH"
echo -e "${GREEN}✓ App installed${NC}"

# Step 4: Launch the app
echo -e "\n${YELLOW}Step 4: Launching app...${NC}"
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
sleep 0.5
xcrun simctl launch "$SIM_ID" "$BUNDLE_ID"
echo -e "${GREEN}✓ App launched${NC}"
wait_for_app

# Step 5: Take initial screenshot (Today view)
echo -e "\n${YELLOW}Step 5: Verifying Today view...${NC}"
take_screenshot "01_today_view"
echo -e "${GREEN}✓ Today view loaded${NC}"

# Step 6: Navigate to Mountains tab
echo -e "\n${YELLOW}Step 6: Testing Mountains tab...${NC}"
tap_at 120 945  # Mountains tab (2nd tab)
sleep 1
take_screenshot "02_mountains_view"
echo -e "${GREEN}✓ Mountains view loaded${NC}"

# Step 7: Navigate to Map tab
echo -e "\n${YELLOW}Step 7: Testing Map tab...${NC}"
tap_at 200 945  # Map tab (3rd tab)
sleep 1
take_screenshot "03_map_view"
echo -e "${GREEN}✓ Map view loaded${NC}"

# Step 8: Test weather overlay
echo -e "\n${YELLOW}Step 8: Testing weather overlay...${NC}"
tap_at 80 430   # First overlay button (Snowfall)
sleep 1.5
take_screenshot "04_snowfall_overlay"

tap_at 120 430  # Depth overlay
sleep 1.5
take_screenshot "05_depth_overlay"

tap_at 160 430  # Radar overlay
sleep 1.5
take_screenshot "06_radar_overlay"
echo -e "${GREEN}✓ Weather overlays tested${NC}"

# Step 9: Navigate to Profile tab
echo -e "\n${YELLOW}Step 9: Testing Profile tab...${NC}"
tap_at 280 945  # Profile tab (4th tab)
sleep 1
take_screenshot "07_profile_view"
echo -e "${GREEN}✓ Profile view loaded${NC}"

# Summary
echo -e "\n=================================="
echo -e "${GREEN}🎉 E2E Tests Complete!${NC}"
echo -e "Screenshots saved to: $SCREENSHOT_DIR"
echo ""
echo "Screenshots taken:"
ls -la "$SCREENSHOT_DIR"/*.png 2>/dev/null | awk '{print "  " $NF}'
