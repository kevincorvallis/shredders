#!/bin/bash

# Get the project file
PROJECT_FILE="PowderTracker.xcodeproj/project.pbxproj"

# Generate UUIDs for the file
UUID_FILE=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
UUID_BUILD=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')

echo "Adding TemperatureElevationMapView.swift to Xcode project..."

# Add file reference to PBXFileReference section
ruby -i -pe "
  if \$_ =~ /\/\* Begin PBXFileReference section \*\//
    print \"\t\t$UUID_FILE /* TemperatureElevationMapView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = TemperatureElevationMapView.swift; sourceTree = \\\"<group>\\\"; };\n\"
  end
" "$PROJECT_FILE"

# Add to Components group - INSIDE the children array
ruby -i -pe "
  if \$_ =~ /AB287A8A884E4E3BD60F605C \/\* Components \*\/ = \{/ .. \$_ =~ /\t\t\};/
    if \$_ =~ /children = \(/
      print
      print \"\t\t\t\t$UUID_FILE /* TemperatureElevationMapView.swift */,\n\"
      next
    end
  end
" "$PROJECT_FILE"

# Add build file to PBXBuildFile section
ruby -i -pe "
  if \$_ =~ /\/\* Begin PBXBuildFile section \*\//
    print \"\t\t$UUID_BUILD /* TemperatureElevationMapView.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_FILE /* TemperatureElevationMapView.swift */; };\n\"
  end
" "$PROJECT_FILE"

# Add to PBXSourcesBuildPhase - find the main target's Sources phase
ruby -i -pe "
  if \$inside_sources
    if \$_ =~ /files = \(/
      print
      print \"\t\t\t\t$UUID_BUILD /* TemperatureElevationMapView.swift in Sources */,\n\"
      \$inside_sources = false
      next
    end
  end
  if \$_ =~ /\/\* Sources \*\/ = \{/
    \$inside_sources = true
  end
" "$PROJECT_FILE"

echo "✅ TemperatureElevationMapView.swift added to Xcode project"
