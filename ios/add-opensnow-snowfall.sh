#!/bin/bash

PROJECT_FILE="PowderTracker/PowderTracker.xcodeproj/project.pbxproj"
NEW_FILE="PowderTracker/Views/Components/OpenSnowStyleSnowfallView.swift"

# Generate UUIDs for the file reference and build file
FILE_REF_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
BUILD_FILE_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:upper:]' '[:upper:]')

echo "Adding OpenSnowStyleSnowfallView.swift to Xcode project..."
echo "File Reference UUID: $FILE_REF_UUID"
echo "Build File UUID: $BUILD_FILE_UUID"

# Backup project file
cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"

# Add file reference in PBXFileReference section
perl -i -pe "BEGIN{undef $/;} s|(/\* Components \*/.*?children = \(.*?)(.*?)(\);.*?name = Components;)|
\$1\t\t\t\t${FILE_REF_UUID} /\* OpenSnowStyleSnowfallView.swift \*/,\n\$2\$3|sm" "$PROJECT_FILE"

# Add the actual file reference entry
perl -i -pe "s|(/\* End PBXFileReference section \*/)|
\t\t${FILE_REF_UUID} /\* OpenSnowStyleSnowfallView.swift \*/ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = OpenSnowStyleSnowfallView.swift; sourceTree = \"<group>\"; };\n\$1|" "$PROJECT_FILE"

# Add build file in PBXBuildFile section  
perl -i -pe "s|(/\* End PBXBuildFile section \*/)|
\t\t${BUILD_FILE_UUID} /\* OpenSnowStyleSnowfallView.swift in Sources \*/ = {isa = PBXBuildFile; fileRef = ${FILE_REF_UUID} /\* OpenSnowStyleSnowfallView.swift \*/; };\n\$1|" "$PROJECT_FILE"

# Add to PBXSourcesBuildPhase
perl -i -pe "BEGIN{undef $/;} s|(PBXSourcesBuildPhase.*?files = \(.*?)(.*?)(\);.*?PBXSourcesBuildPhase)|
\$1\t\t\t\t${BUILD_FILE_UUID} /\* OpenSnowStyleSnowfallView.swift in Sources \*/,\n\$2\$3|sm" "$PROJECT_FILE"

echo "✅ Successfully added OpenSnowStyleSnowfallView.swift to Xcode project"
