#!/bin/bash

# Script to add NewHomeView and NewMountainsView to Xcode project

PROJECT_DIR="/Users/kevin/Downloads/shredders/ios/PowderTracker"
PROJECT_FILE="$PROJECT_DIR/PowderTracker.xcodeproj/project.pbxproj"

echo "Adding new view files to Xcode project..."

# Generate unique IDs (24-character hex strings)
NEW_HOME_REF_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
NEW_MOUNTAINS_REF_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')

NEW_HOME_BUILD_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
NEW_MOUNTAINS_BUILD_ID=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')

# Backup the project file first
cp "$PROJECT_FILE" "$PROJECT_FILE.backup-$(date +%s)"
echo "✅ Created backup: project.pbxproj.backup-$(date +%s)"

# Find an existing Views file reference to anchor our additions
ANCHOR=$(grep "\/\* HomeView.swift \*\/ = {isa = PBXFileReference" "$PROJECT_FILE" | awk '{print $1}')

if [ -z "$ANCHOR" ]; then
    echo "⚠️  Could not find HomeView.swift reference, trying ContentView.swift..."
    ANCHOR=$(grep "\/\* ContentView.swift \*\/ = {isa = PBXFileReference" "$PROJECT_FILE" | awk '{print $1}')
fi

if [ -z "$ANCHOR" ]; then
    echo "❌ Could not find anchor file. Please add files manually in Xcode."
    exit 1
fi

echo "Using anchor: $ANCHOR"

# Step 1: Add PBXFileReference entries for the new files
echo "Adding file references..."
sed -i '' "/${ANCHOR}/a\\
\\t\\t${NEW_HOME_REF_ID} /* NewHomeView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NewHomeView.swift; sourceTree = \"<group>\"; };\\
\\t\\t${NEW_MOUNTAINS_REF_ID} /* NewMountainsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NewMountainsView.swift; sourceTree = \"<group>\"; };
" "$PROJECT_FILE"

# Step 2: Add to Views children array (find the Views group and add to it)
echo "Adding to Views group..."
# This adds them to the same group as HomeView
VIEWS_GROUP_LINE=$(grep -n "\/\* HomeView.swift \*\/," "$PROJECT_FILE" | head -1 | cut -d: -f1)
if [ ! -z "$VIEWS_GROUP_LINE" ]; then
    sed -i '' "${VIEWS_GROUP_LINE}a\\
\\t\\t\\t\\t${NEW_HOME_REF_ID} /* NewHomeView.swift */,\\
\\t\\t\\t\\t${NEW_MOUNTAINS_REF_ID} /* NewMountainsView.swift */,
" "$PROJECT_FILE"
fi

# Step 3: Add PBXBuildFile entries
echo "Adding build file entries..."
BUILD_ANCHOR=$(grep -m 1 "HomeView.swift in Sources" "$PROJECT_FILE" | grep "PBXBuildFile" | awk '{print $1}')
if [ ! -z "$BUILD_ANCHOR" ]; then
    sed -i '' "/${BUILD_ANCHOR}/a\\
\\t\\t${NEW_HOME_BUILD_ID} /* NewHomeView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${NEW_HOME_REF_ID} /* NewHomeView.swift */; };\\
\\t\\t${NEW_MOUNTAINS_BUILD_ID} /* NewMountainsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = ${NEW_MOUNTAINS_REF_ID} /* NewMountainsView.swift */; };
" "$PROJECT_FILE"
fi

# Step 4: Add to PBXSourcesBuildPhase
echo "Adding to build phase..."
SOURCE_ANCHOR=$(grep -m 1 "HomeView.swift in Sources" "$PROJECT_FILE" | grep "in Sources" | awk '{print $1}')
if [ ! -z "$SOURCE_ANCHOR" ]; then
    SOURCE_LINE=$(grep -n "${SOURCE_ANCHOR}" "$PROJECT_FILE" | grep "Sources \*/" | head -1 | cut -d: -f1)
    if [ ! -z "$SOURCE_LINE" ]; then
        sed -i '' "${SOURCE_LINE}a\\
\\t\\t\\t\\t${NEW_HOME_BUILD_ID} /* NewHomeView.swift in Sources */,\\
\\t\\t\\t\\t${NEW_MOUNTAINS_BUILD_ID} /* NewMountainsView.swift in Sources */,
" "$PROJECT_FILE"
    fi
fi

echo "✅ Successfully added new view files to Xcode project"
echo ""
echo "New file IDs generated:"
echo "  NewHomeView: $NEW_HOME_REF_ID"
echo "  NewMountainsView: $NEW_MOUNTAINS_REF_ID"
echo ""
echo "To verify, try building the project:"
echo "  cd $PROJECT_DIR && xcodebuild -scheme PowderTracker -sdk iphonesimulator build"
