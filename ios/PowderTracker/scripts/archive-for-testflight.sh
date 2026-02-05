#!/bin/bash

# Archive and upload PowderTracker to TestFlight
# Usage: ./scripts/archive-for-testflight.sh [--upload]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SCHEME="PowderTracker"
ARCHIVE_PATH="$PROJECT_DIR/build/PowderTracker.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/Export"

cd "$PROJECT_DIR"

echo "🎿 PowderTracker TestFlight Archive Script"
echo "==========================================="
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf build/
mkdir -p build

# Create archive
echo "📦 Creating archive..."
xcodebuild archive \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic \
    | xcbeautify || xcodebuild archive \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS' \
    -allowProvisioningUpdates \
    CODE_SIGN_STYLE=Automatic

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "❌ Archive failed - no archive created"
    exit 1
fi

echo "✅ Archive created at: $ARCHIVE_PATH"
echo ""

# Check if we should upload
if [ "$1" == "--upload" ]; then
    echo "📤 Uploading to App Store Connect..."

    # Create export options plist
    cat > "$PROJECT_DIR/build/ExportOptions.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>teamID</key>
    <string>4F8Q446767</string>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
EOF

    xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$PROJECT_DIR/build/ExportOptions.plist" \
        -exportPath "$EXPORT_PATH" \
        -allowProvisioningUpdates \
        | xcbeautify || xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportOptionsPlist "$PROJECT_DIR/build/ExportOptions.plist" \
        -exportPath "$EXPORT_PATH" \
        -allowProvisioningUpdates

    echo ""
    echo "✅ Upload complete! Check App Store Connect for your build."
else
    echo "💡 To upload to TestFlight, run:"
    echo "   ./scripts/archive-for-testflight.sh --upload"
    echo ""
    echo "   Or open the archive in Xcode:"
    echo "   open $ARCHIVE_PATH"
fi

echo ""
echo "📱 Next steps:"
echo "   1. Go to App Store Connect: https://appstoreconnect.apple.com"
echo "   2. Select your app"
echo "   3. Go to TestFlight tab"
echo "   4. Your build should appear (may take 5-15 minutes to process)"
echo "   5. Add testers or create a public link"
