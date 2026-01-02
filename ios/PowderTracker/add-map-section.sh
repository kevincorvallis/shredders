#!/bin/bash

PROJECT_DIR="/Users/kevin/Downloads/shredders/ios/PowderTracker"
PBXPROJ="$PROJECT_DIR/PowderTracker.xcodeproj/project.pbxproj"

# File to add
FILE_PATH="PowderTracker/Views/Location/LocationMapSection.swift"
FILE_NAME="LocationMapSection.swift"

# Generate unique IDs
FILE_REF_ID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)
BUILD_FILE_ID=$(uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | cut -c1-24)

echo "Adding $FILE_NAME to Xcode project..."
echo "File Reference ID: $FILE_REF_ID"
echo "Build File ID: $BUILD_FILE_ID"

# Backup the project file
cp "$PBXPROJ" "$PBXPROJ.backup"

# Add PBXBuildFile entry
sed -i '' "/\/\* Begin PBXBuildFile section \*\//a\\
		$BUILD_FILE_ID /* $FILE_NAME in Sources */ = {isa = PBXBuildFile; fileRef = $FILE_REF_ID /* $FILE_NAME */; };
" "$PBXPROJ"

# Add PBXFileReference entry
sed -i '' "/\/\* Begin PBXFileReference section \*\//a\\
		$FILE_REF_ID /* $FILE_NAME */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $FILE_NAME; sourceTree = \"<group>\"; };
" "$PBXPROJ"

# Find the Location group and add the file reference
sed -i '' "/\/\* Location \*\/ = {/,/children = (/{
    /children = (/a\\
				$FILE_REF_ID /* $FILE_NAME */,
}" "$PBXPROJ"

# Add to PBXSourcesBuildPhase
sed -i '' "/\/\* Sources \*\/ = {/,/files = (/{
    /files = (/a\\
				$BUILD_FILE_ID /* $FILE_NAME in Sources */,
}" "$PBXPROJ"

echo "✅ Successfully added $FILE_NAME to Xcode project"
echo "File added to Location group"
