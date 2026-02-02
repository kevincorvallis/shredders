#!/bin/bash

# Archive PowderTracker for App Store Upload
# Creates an archive ready for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ARCHIVE_DIR="$PROJECT_DIR/Archives"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_PATH="$ARCHIVE_DIR/PowderTracker_${TIMESTAMP}.xcarchive"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  PowderTracker Archive Builder${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Create archive directory
mkdir -p "$ARCHIVE_DIR"

cd "$PROJECT_DIR"

echo -e "${YELLOW}Step 1: Checking signing identity...${NC}"

# Check for distribution certificate
DIST_CERT=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1)
DEV_CERT=$(security find-identity -v -p codesigning | grep "Apple Development" | head -1)

if [ -n "$DIST_CERT" ]; then
    echo -e "${GREEN}✓ Found Apple Distribution certificate${NC}"
    SIGNING_IDENTITY="Apple Distribution"
elif [ -n "$DEV_CERT" ]; then
    echo -e "${YELLOW}⚠ Only Apple Development certificate found${NC}"
    echo "  For App Store upload, you'll need an Apple Distribution certificate."
    echo "  Proceeding with Development certificate for testing..."
    SIGNING_IDENTITY="Apple Development"
else
    echo -e "${RED}✗ No valid signing certificate found${NC}"
    echo "  Please install an Apple Development or Distribution certificate."
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 2: Building archive...${NC}"
echo "  This may take a few minutes..."
echo ""

# Create archive
xcodebuild archive \
    -scheme PowderTracker \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    2>&1 | grep -E "(Build|Archive|error:|warning:|\*\*)" | head -30

if [ -d "$ARCHIVE_PATH" ]; then
    echo ""
    echo -e "${GREEN}✓ Archive created successfully!${NC}"
    echo ""
    echo -e "${BLUE}Archive location:${NC}"
    echo "  $ARCHIVE_PATH"
    echo ""

    # Get archive info
    INFO_PLIST="$ARCHIVE_PATH/Info.plist"
    if [ -f "$INFO_PLIST" ]; then
        VERSION=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleShortVersionString" "$INFO_PLIST" 2>/dev/null || echo "Unknown")
        BUILD=$(/usr/libexec/PlistBuddy -c "Print :ApplicationProperties:CFBundleVersion" "$INFO_PLIST" 2>/dev/null || echo "Unknown")
        echo -e "${BLUE}Archive details:${NC}"
        echo "  Version: $VERSION"
        echo "  Build: $BUILD"
    fi

    echo ""
    echo -e "${YELLOW}Step 3: Next steps to upload to App Store...${NC}"
    echo ""
    echo "Option A: Using Xcode Organizer (Recommended)"
    echo "  1. Open Xcode"
    echo "  2. Window > Organizer (Cmd+Shift+O)"
    echo "  3. Select PowderTracker archive"
    echo "  4. Click 'Distribute App'"
    echo "  5. Select 'App Store Connect'"
    echo "  6. Follow the prompts"
    echo ""
    echo "Option B: Using Transporter app"
    echo "  1. Export IPA: xcodebuild -exportArchive -archivePath '$ARCHIVE_PATH' -exportPath '$ARCHIVE_DIR' -exportOptionsPlist ExportOptions.plist"
    echo "  2. Open Transporter app (from App Store)"
    echo "  3. Drag the .ipa file to upload"
    echo ""
    echo "Option C: Using altool (command line)"
    echo "  xcrun altool --upload-app -f path/to/app.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD"
    echo ""

    # Open in Finder
    echo -e "${YELLOW}Opening archive in Finder...${NC}"
    open "$ARCHIVE_DIR"

else
    echo ""
    echo -e "${RED}✗ Archive failed${NC}"
    echo "  Check the output above for errors."
    exit 1
fi

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Archive ready for distribution!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
