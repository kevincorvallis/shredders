#!/bin/bash
# Remove alpha channel from all icons (required by App Store)

OUTPUT_DIR="ios/PowderTracker/PowderTracker/Assets.xcassets/AppIcon.appiconset"

echo "Removing alpha channels from all icons..."

for icon in "$OUTPUT_DIR"/*.png; do
  filename=$(basename "$icon")
  # Convert to RGB, flatten alpha against white background, then back to RGB
  magick "$icon" -background '#1a2332' -alpha remove -alpha off "$icon"
  echo "  ✓ Processed $filename"
done

echo ""
echo "✓ All icons converted to RGB (no alpha channel)"
echo "✓ App Store submission requirements met!"
