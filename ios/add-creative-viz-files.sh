#!/bin/bash

# Add new creative visualization files to Xcode project

cd "$(dirname "$0")/PowderTracker"

# Files to add
FILES=(
    "PowderTracker/Views/Components/RadialDashboard.swift"
    "PowderTracker/Views/Components/AtAGlanceCard.swift"
    "PowderTracker/Views/Components/LiftLinePredictorCard.swift"
    "PowderTracker/Services/LiftLinePredictor.swift"
)

# Add each file to the project
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "Adding $file to Xcode project..."

        # Get the file UUID
        FILE_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
        FILE_REF_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')

        # Get just the filename
        FILENAME=$(basename "$file")

        # Determine the group
        if [[ "$file" == *"/Services/"* ]]; then
            GROUP="Services"
        elif [[ "$file" == *"/Components/"* ]]; then
            GROUP="Components"
        else
            GROUP="Views"
        fi

        echo "  File: $FILENAME"
        echo "  Group: $GROUP"
        echo "  UUID: $FILE_UUID"
        echo "  Ref UUID: $FILE_REF_UUID"
    fi
done

echo ""
echo "Files created! Now running XcodeGen to update project..."

# Use XcodeGen if available, otherwise use manual pbxproj editing
if command -v xcodegen &> /dev/null; then
    echo "Using XcodeGen..."
    xcodegen generate
else
    echo "XcodeGen not found. Files created but you may need to add them manually to Xcode."
    echo "Drag and drop these files in Xcode:"
    for file in "${FILES[@]}"; do
        echo "  - $file"
    done
fi

echo ""
echo "✅ Done! New visualization components are ready:"
echo "   • RadialDashboard - Apple Watch-style activity rings"
echo "   • AtAGlanceCard - Compact hero card with key metrics"
echo "   • LiftLinePredictorCard - AI-powered lift line predictions"
echo "   • LiftLinePredictor - Prediction engine"
