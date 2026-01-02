#!/bin/bash
# Add tile overlay files to Xcode project

cd "$(dirname "$0")/PowderTracker"

# Add files to Xcode project using sed
PROJECT_FILE="PowderTracker.xcodeproj/project.pbxproj"

echo "Adding tile overlay files to Xcode project..."

# Files to add
FILES=(
    "PowderTracker/Services/LiftTileOverlay.swift"
    "PowderTracker/Views/Location/TiledMapView.swift"
    "PowderTracker/Views/Location/LocationMapSectionTiled.swift"
)

# Generate unique IDs for each file
UUID_LIFT_TILE_OVERLAY="F1$(uuidgen | tr -d '-' | cut -c1-22)"
UUID_TILED_MAP_VIEW="F2$(uuidgen | tr -d '-' | cut -c1-22)"
UUID_LOCATION_MAP_TILED="F3$(uuidgen | tr -d '-' | cut -c1-22)"

# Add file references
sed -i '' "/\/\* End PBXFileReference section \*\//i\\
		$UUID_LIFT_TILE_OVERLAY /* LiftTileOverlay.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LiftTileOverlay.swift; sourceTree = \"<group>\"; };\\
		$UUID_TILED_MAP_VIEW /* TiledMapView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TiledMapView.swift; sourceTree = \"<group>\"; };\\
		$UUID_LOCATION_MAP_TILED /* LocationMapSectionTiled.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = LocationMapSectionTiled.swift; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"

# Add to Services group (for LiftTileOverlay.swift)
sed -i '' "/\/\* Services \*\/ = {/,/children = (/a\\
				$UUID_LIFT_TILE_OVERLAY /* LiftTileOverlay.swift */,
" "$PROJECT_FILE"

# Add to Location group (for TiledMapView.swift and LocationMapSectionTiled.swift)
sed -i '' "/\/\* Location \*\/ = {/,/children = (/a\\
				$UUID_TILED_MAP_VIEW /* TiledMapView.swift */,\\
				$UUID_LOCATION_MAP_TILED /* LocationMapSectionTiled.swift */,
" "$PROJECT_FILE"

# Add to compile sources
sed -i '' "/\/\* Begin PBXSourcesBuildPhase section \*\//,/\/\* End PBXSourcesBuildPhase section \*\//s/files = (/files = (\\
				${UUID_LIFT_TILE_OVERLAY}A \/\* LiftTileOverlay.swift in Sources \*\/,\\
				${UUID_TILED_MAP_VIEW}A \/\* TiledMapView.swift in Sources \*\/,\\
				${UUID_LOCATION_MAP_TILED}A \/\* LocationMapSectionTiled.swift in Sources \*\/,/1" "$PROJECT_FILE"

# Add build file references
sed -i '' "/\/\* End PBXBuildFile section \*\//i\\
		${UUID_LIFT_TILE_OVERLAY}A /* LiftTileOverlay.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_LIFT_TILE_OVERLAY /* LiftTileOverlay.swift */; };\\
		${UUID_TILED_MAP_VIEW}A /* TiledMapView.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_TILED_MAP_VIEW /* TiledMapView.swift */; };\\
		${UUID_LOCATION_MAP_TILED}A /* LocationMapSectionTiled.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_LOCATION_MAP_TILED /* LocationMapSectionTiled.swift */; };
" "$PROJECT_FILE"

echo "✅ Added 3 tile overlay files to Xcode project"
echo ""
echo "Files added:"
echo "  - PowderTracker/Services/LiftTileOverlay.swift"
echo "  - PowderTracker/Views/Location/TiledMapView.swift"
echo "  - PowderTracker/Views/Location/LocationMapSectionTiled.swift"
echo ""
echo "You can now use LocationMapSectionTiled instead of LocationMapSection"
echo "to enable tiled lift rendering with lazy loading!"
