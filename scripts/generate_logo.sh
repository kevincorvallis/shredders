#!/bin/bash
# Generate professional PowderTracker app icon using ImageMagick

echo "Generating PowderTracker app icon..."

# Create 1024x1024 master icon
magick -size 1024x1024 xc:'#1a2332' \
  \( -size 1024x1024 gradient:'#1a2332-#2a3342' \) -compose Over -composite \
  -fill '#2c4a7c' -stroke none \
  -draw "polygon 280,750 450,280 620,750" \
  -fill '#4a7ba7' -stroke none \
  -draw "polygon 200,750 512,200 824,750" \
  -fill '#6ba3d0' -stroke none \
  -draw "polygon 280,500 380,400 420,520" \
  -fill '#ffffff' -stroke none \
  -draw "polygon 392,350 512,200 632,350 592,380 432,380 392,350" \
  -fill none -stroke '#3dd68c' -strokewidth 18 \
  -draw "path 'M 720,380 Q 620,480 520,580 Q 470,630 420,680'" \
  -fill none -stroke '#50e8a0' -strokewidth 12 \
  -draw "path 'M 715,385 Q 615,485 515,585 Q 465,635 415,685'" \
  -fill none -stroke '#70ffb4' -strokewidth 8 \
  -draw "path 'M 710,390 Q 610,490 510,590 Q 460,640 410,690'" \
  /Users/kevin/Downloads/shredders/logo_master.png

echo "✓ Master icon saved: logo_master.png (1024x1024)"

# Generate all required iOS app icon sizes
SIZES=(
  "20:AppIcon-20.png"
  "40:AppIcon-20@2x.png:AppIcon-20@2x-ipad.png"
  "60:AppIcon-20@3x.png"
  "29:AppIcon-29.png"
  "58:AppIcon-29@2x.png:AppIcon-29@2x-ipad.png"
  "87:AppIcon-29@3x.png"
  "40:AppIcon-40.png"
  "80:AppIcon-40@2x.png:AppIcon-40@2x-ipad.png"
  "120:AppIcon-40@3x.png:AppIcon-60@2x.png"
  "180:AppIcon-60@3x.png"
  "76:AppIcon-76.png"
  "152:AppIcon-76@2x.png"
  "167:AppIcon-83.5@2x.png"
  "1024:AppIcon-1024.png"
)

OUTPUT_DIR="ios/PowderTracker/PowderTracker/Assets.xcassets/AppIcon.appiconset"

echo "Generating all required sizes..."
for size_info in "${SIZES[@]}"; do
  IFS=':' read -ra PARTS <<< "$size_info"
  SIZE="${PARTS[0]}"

  # Generate for each output filename
  for i in $(seq 1 $((${#PARTS[@]}-1))); do
    FILENAME="${PARTS[$i]}"
    magick logo_master.png -resize "${SIZE}x${SIZE}" "$OUTPUT_DIR/$FILENAME"
    echo "  ✓ Generated $FILENAME (${SIZE}x${SIZE})"
  done
done

echo ""
echo "✓ All app icon sizes generated successfully!"
echo "✓ Icons are in: $OUTPUT_DIR"
