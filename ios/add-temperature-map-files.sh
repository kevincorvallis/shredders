#!/bin/bash
# Add temperature elevation map files to Xcode project

cd "$(dirname "$0")/PowderTracker"

PROJECT_FILE="PowderTracker.xcodeproj/project.pbxproj"

echo "Adding temperature elevation map files to Xcode project..."

# Generate unique IDs
UUID_TEMP_MAP="T1$(uuidgen | tr -d '-' | cut -c1-22)"

# Add file reference
sed -i '' "/\/\* End PBXFileReference section \*\//i\\
		$UUID_TEMP_MAP /* TemperatureElevationMapView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TemperatureElevationMapView.swift; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"

# Add to Components group
sed -i '' "/\/\* Components \*\/ = {/,/children = (/a\\
				$UUID_TEMP_MAP /* TemperatureElevationMapView.swift */,
" "$PROJECT_FILE"

# Add to compile sources
sed -i '' "/\/\* Begin PBXSourcesBuildPhase section \*\//,/\/\* End PBXSourcesBuildPhase section \*\//s/files = (/files = (\\
				${UUID_TEMP_MAP}A \/\* TemperatureElevationMapView.swift in Sources \*\/,/1" "$PROJECT_FILE"

# Add build file reference
sed -i '' "/\/\* End PBXBuildFile section \*\//i\\
		${UUID_TEMP_MAP}A /* TemperatureElevationMapView.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_TEMP_MAP /* TemperatureElevationMapView.swift */; };
" "$PROJECT_FILE"

echo "✅ Added TemperatureElevationMapView.swift to Xcode project"
echo ""
echo "File added:"
echo "  - PowderTracker/Views/Components/TemperatureElevationMapView.swift"
echo ""
echo "Temperature elevation map is now ready to use!"
echo "Tap on temperature by elevation sections to see the interactive color-coded mountain temperature map."
