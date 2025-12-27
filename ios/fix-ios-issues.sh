#!/bin/bash

# Fix iOS Build Issues
# This script fixes:
# 1. Interface orientation requirements
# 2. Swift concurrency warnings (already fixed in code)

set -e

echo "🔧 Fixing iOS Build Issues..."

PROJECT_FILE="/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj/project.pbxproj"

# Backup the project file
echo "📦 Creating backup..."
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Fix orientation support for iPhone
# Change from Portrait-only to Portrait + Landscape
echo "🔄 Fixing interface orientations..."

# Use sed to replace the orientation settings
sed -i '' 's/INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = UIInterfaceOrientationPortrait;/INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone = "UIInterfaceOrientationPortrait UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight";/g' "$PROJECT_FILE"

echo "✅ Orientation settings updated"
echo ""
echo "Changes made:"
echo "  - iPhone now supports: Portrait, Landscape Left, Landscape Right"
echo ""
echo "Backup saved to: ${PROJECT_FILE}.backup"
echo ""
echo "Next steps:"
echo "  1. Open the project in Xcode"
echo "  2. Clean build folder (Cmd+Shift+K)"
echo "  3. Build the project (Cmd+B)"
echo ""
echo "If you need to revert:"
echo "  cp ${PROJECT_FILE}.backup $PROJECT_FILE"
echo ""
echo "✅ Done!"
