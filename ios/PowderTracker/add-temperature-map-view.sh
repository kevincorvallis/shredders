#!/bin/bash

# Get the project file
PROJECT_FILE="PowderTracker.xcodeproj/project.pbxproj"

# Generate UUIDs for the file
UUID_FILE=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
UUID_BUILD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')

echo "Adding TemperatureElevationMapView.swift to Xcode project..."

# Add file reference
ruby -i -pe "
  if \$_ =~ /\/\* Begin PBXFileReference section \*\//
    print \"\t\t$UUID_FILE /* TemperatureElevationMapView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TemperatureElevationMapView.swift; sourceTree = \\\"<group>\\\"; };\n\"
  end
" "$PROJECT_FILE"

# Add to Components group (find the Views/Components group)
ruby -i -pe "
  if \$_ =~ /\/\* Components \*\/ = \{/ .. \$_ =~ /\};/ and \$_ =~ /children = \(/
    print \"\t\t\t\t$UUID_FILE /* TemperatureElevationMapView.swift */,\n\"
  end
" "$PROJECT_FILE"

# Add build file
ruby -i -pe "
  if \$_ =~ /\/\* Begin PBXBuildFile section \*\//
    print \"\t\t$UUID_BUILD /* TemperatureElevationMapView.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_FILE /* TemperatureElevationMapView.swift */; };\n\"
  end
" "$PROJECT_FILE"

# Add to sources build phase
ruby -i -pe "
  if \$_ =~ /Sources.*buildActionMask/ .. \$_ =~ /runOnlyForDeploymentPostprocessing = 0;/ and \$_ =~ /files = \(/
    print \"\t\t\t\t$UUID_BUILD /* TemperatureElevationMapView.swift in Sources */,\n\"
  end
" "$PROJECT_FILE"

echo "✅ TemperatureElevationMapView.swift added to Xcode project"
