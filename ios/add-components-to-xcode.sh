#!/bin/bash

# Script to add the new component files to Xcode project
# This is the safest method for adding Swift files to an existing Xcode project

PROJECT_DIR="/Users/kevin/Downloads/shredders/ios/PowderTracker"
PROJECT_FILE="$PROJECT_DIR/PowderTracker.xcodeproj/project.pbxproj"

echo "Adding new component files to Xcode project..."

# Generate unique IDs (24-character hex strings)
MOUNTAIN_STATUS_REF_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
NAVIGATE_BUTTON_REF_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
SNOWFALL_TABLE_REF_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')

MOUNTAIN_STATUS_BUILD_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
NAVIGATE_BUTTON_BUILD_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
SNOWFALL_TABLE_BUILD_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')

# Backup the project file first
cp "$PROJECT_FILE" "$PROJECT_FILE.backup"
echo "✅ Created backup: project.pbxproj.backup"

# Step 1: Add PBXFileReference entries
echo "Adding file references..."
sed -i '' "/5D191EFA0C190B3434D1A449 \/\* PowderScoreGauge.swift \*\//a\\
\\t\\t${MOUNTAIN_STATUS_REF_ID} /* MountainStatusView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MountainStatusView.swift; sourceTree = \"<group>\"; };\\
\\t\\t${NAVIGATE_BUTTON_REF_ID} /* NavigateButton.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NavigateButton.swift; sourceTree = \"<group>\"; };\\
\\t\\t${SNOWFALL_TABLE_REF_ID} /* SnowfallTableView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SnowfallTableView.swift; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"

# Step 2: Add to Components children array
echo "Adding to Components group..."
sed -i '' "/5D191EFA0C190B3434D1A449 \/\* PowderScoreGauge.swift \*\//a\\
\\t\\t\\t\\t${MOUNTAIN_STATUS_REF_ID} /* MountainStatusView.swift */,\\
\\t\\t\\t\\t${NAVIGATE_BUTTON_REF_ID} /* NavigateButton.swift */,\\
\\t\\t\\t\\t${SNOWFALL_TABLE_REF_ID} /* SnowfallTableView.swift */,
" "$PROJECT_FILE"

# Step 3: Add PBXBuildFile entries
echo "Adding build file entries..."
sed -i '' "/E0CA30E94F41AB09EEFDE036 \/\* PowderScoreGauge.swift in Sources \*\//a\\
\\t\\t${MOUNTAIN_STATUS_BUILD_ID} /* MountainStatusView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${MOUNTAIN_STATUS_REF_ID} /* MountainStatusView.swift */; };\\
\\t\\t${NAVIGATE_BUTTON_BUILD_ID} /* NavigateButton.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${NAVIGATE_BUTTON_REF_ID} /* NavigateButton.swift */; };\\
\\t\\t${SNOWFALL_TABLE_BUILD_ID} /* SnowfallTableView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${SNOWFALL_TABLE_REF_ID} /* SnowfallTableView.swift */; };
" "$PROJECT_FILE"

# Step 4: Add to PBXSourcesBuildPhase
echo "Adding to build phase..."
sed -i '' "/E0CA30E94F41AB09EEFDE036 \/\* PowderScoreGauge.swift in Sources \*\//a\\
\\t\\t\\t\\t${MOUNTAIN_STATUS_BUILD_ID} /* MountainStatusView.swift in Sources */,\\
\\t\\t\\t\\t${NAVIGATE_BUTTON_BUILD_ID} /* NavigateButton.swift in Sources */,\\
\\t\\t\\t\\t${SNOWFALL_TABLE_BUILD_ID} /* SnowfallTableView.swift in Sources */,
" "$PROJECT_FILE"

echo "✅ Successfully added all component files to Xcode project"
echo ""
echo "New file IDs generated:"
echo "  MountainStatusView: $MOUNTAIN_STATUS_REF_ID"
echo "  NavigateButton: $NAVIGATE_BUTTON_REF_ID"
echo "  SnowfallTableView: $SNOWFALL_TABLE_REF_ID"
echo ""
echo "If anything goes wrong, restore from backup:"
echo "  cp $PROJECT_FILE.backup $PROJECT_FILE"
