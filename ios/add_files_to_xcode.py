#!/usr/bin/env python3
"""
Script to add Swift files to Xcode project programmatically
"""

import re
import uuid
import shutil
from pathlib import Path

PROJECT_PATH = Path("/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj/project.pbxproj")

# Files to add
FILES_TO_ADD = [
    "MountainStatusView.swift",
    "NavigateButton.swift",
    "SnowfallTableView.swift"
]

def generate_xcode_id():
    """Generate a unique 24-character Xcode ID"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_project():
    # Backup original file
    backup_path = PROJECT_PATH.with_suffix('.pbxproj.backup')
    shutil.copy2(PROJECT_PATH, backup_path)
    print(f"✅ Created backup: {backup_path}")

    # Read project file
    with open(PROJECT_PATH, 'r') as f:
        content = f.read()

    # Generate IDs for each file
    file_data = {}
    for filename in FILES_TO_ADD:
        file_data[filename] = {
            'fileref_id': generate_xcode_id(),
            'buildfile_id': generate_xcode_id()
        }

    # Find the PBXFileReference section and add entries
    print("Adding PBXFileReference entries...")
    # Find PowderScoreGauge reference line
    powder_gauge_pattern = r'(\t\t[A-F0-9]{24} /\* PowderScoreGauge\.swift \*/ = {isa = PBXFileReference;[^\n]+\n)'

    fileref_additions = []
    for filename, ids in file_data.items():
        fileref_line = f'\t\t{ids["fileref_id"]} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};\n'
        fileref_additions.append(fileref_line)

    content = re.sub(
        powder_gauge_pattern,
        r'\1' + ''.join(fileref_additions),
        content,
        count=1
    )

    # Find the PBXBuildFile section and add entries
    print("Adding PBXBuildFile entries...")
    buildfile_pattern = r'(\t\t[A-F0-9]{24} /\* PowderScoreGauge\.swift in Sources \*/ = {isa = PBXBuildFile;[^\n]+\n)'

    buildfile_additions = []
    for filename, ids in file_data.items():
        buildfile_line = f'\t\t{ids["buildfile_id"]} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {ids["fileref_id"]} /* {filename} */; }};\n'
        buildfile_additions.append(buildfile_line)

    content = re.sub(
        buildfile_pattern,
        r'\1' + ''.join(buildfile_additions),
        content,
        count=1
    )

    # Find Components group children and add files
    print("Adding to Components group...")
    # This pattern finds the children array in the Components group
    children_pattern = r'(children = \([^)]*5D191EFA0C190B3434D1A449 /\* PowderScoreGauge\.swift \*/,)'

    children_additions = []
    for filename, ids in file_data.items():
        children_line = f'\n\t\t\t\t{ids["fileref_id"]} /* {filename} */,'
        children_additions.append(children_line)

    content = re.sub(
        children_pattern,
        r'\1' + ''.join(children_additions),
        content,
        count=1
    )

    # Find PBXSourcesBuildPhase and add build files
    print("Adding to build phase...")
    sources_pattern = r'(/\* PowderScoreGauge\.swift in Sources \*/,)'

    sources_additions = []
    for filename, ids in file_data.items():
        sources_line = f'\n\t\t\t\t{ids["buildfile_id"]} /* {filename} in Sources */,'
        sources_additions.append(sources_line)

    # Find all occurrences in PBXSourcesBuildPhase sections
    content = re.sub(
        sources_pattern,
        r'\1' + ''.join(sources_additions),
        content,
        count=2  # Usually appears twice (main target + test target)
    )

    # Write modified content
    with open(PROJECT_PATH, 'w') as f:
        f.write(content)

    print("✅ Successfully added all files to Xcode project")
    print("\nGenerated IDs:")
    for filename, ids in file_data.items():
        print(f"  {filename}:")
        print(f"    FileRef: {ids['fileref_id']}")
        print(f"    BuildFile: {ids['buildfile_id']}")
    print(f"\n💾 Backup saved to: {backup_path}")
    print("\nTo restore if needed:")
    print(f"  cp {backup_path} {PROJECT_PATH}")

if __name__ == "__main__":
    try:
        add_files_to_project()
    except Exception as e:
        print(f"❌ Error: {e}")
        print("\nPlease add files manually using Xcode UI:")
        print("See ADD_COMPONENTS_INSTRUCTIONS.md for instructions")
        exit(1)
