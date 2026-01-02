#!/bin/bash

# Get the project file
PROJECT_FILE="PowderTracker.xcodeproj/project.pbxproj"

# Generate UUIDs for new files
UUID_SNOW_COMP=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
UUID_COLOR_HEX=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
UUID_BUILD_SNOW=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')
UUID_BUILD_COLOR=$(uuidgen | tr '[:upper:]' '[:lower:]' | tr -d '-' | cut -c1-24 | tr '[:lower:]' '[:upper:]')

# Add file references
ruby -i -pe "
  if \$_ =~ /\/\* Begin PBXFileReference section \*\//
    print \"\t\t$UUID_SNOW_COMP /* SnowComparison.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SnowComparison.swift; sourceTree = \\\"<group>\\\"; };\\n\"
    print \"\t\t$UUID_COLOR_HEX /* Color+Hex.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \\\"Color+Hex.swift\\\"; sourceTree = \\\"<group>\\\"; };\\n\"
  end
" "$PROJECT_FILE"

# Add to Models group
ruby -i -pe "
  if \$_ =~ /Models.*=.*{/ .. \$_ =~ /};/ and \$_ =~ /children = \(/
    print \"\t\t\t\t$UUID_SNOW_COMP /* SnowComparison.swift */,\\n\"
  end
" "$PROJECT_FILE"

# Add to Extensions group or create it
ruby -i -pe "
  if \$_ =~ /Extensions.*children = \(/
    print \"\t\t\t\t$UUID_COLOR_HEX /* Color+Hex.swift */,\\n\"
  end
" "$PROJECT_FILE"

# Add build files
ruby -i -pe "
  if \$_ =~ /\/\* Begin PBXBuildFile section \*\//
    print \"\t\t$UUID_BUILD_SNOW /* SnowComparison.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_SNOW_COMP /* SnowComparison.swift */; };\\n\"
    print \"\t\t$UUID_BUILD_COLOR /* Color+Hex.swift in Sources */ = {isa = PBXBuildFile; fileRef = $UUID_COLOR_HEX /* Color+Hex.swift */; };\\n\"
  end
" "$PROJECT_FILE"

# Add to sources build phase
ruby -i -pe "
  if \$_ =~ /Sources.*buildActionMask/ .. \$_ =~ /runOnlyForDeploymentPostprocessing = 0;/ and \$_ =~ /files = \(/
    print \"\t\t\t\t$UUID_BUILD_SNOW /* SnowComparison.swift in Sources */,\\n\"
    print \"\t\t\t\t$UUID_BUILD_COLOR /* Color+Hex.swift in Sources */,\\n\"
  end
" "$PROJECT_FILE"

echo "Files added to Xcode project"
