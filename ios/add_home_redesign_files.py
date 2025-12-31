#!/usr/bin/env python3
import os
import re
import uuid

# Files to add with their group paths
files_to_add = [
    {
        'path': 'PowderTracker/ViewModels/HomeViewModel.swift',
        'group': 'ViewModels'
    },
    {
        'path': 'PowderTracker/Views/Components/MountainLogoView.swift',
        'group': 'Components'
    },
    {
        'path': 'PowderTracker/Views/Components/MountainCardRow.swift',
        'group': 'Components'
    },
    {
        'path': 'PowderTracker/Views/Components/FavoritesEmptyState.swift',
        'group': 'Components'
    },
    {
        'path': 'PowderTracker/Views/FavoritesManagementView.swift',
        'group': 'Views'
    },
]

project_path = 'PowderTracker/PowderTracker.xcodeproj/project.pbxproj'

def generate_uuid():
    """Generate a UUID compatible with Xcode (24 characters uppercase hex)"""
    return uuid.uuid4().hex[:24].upper()

def add_files_to_xcode_project():
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # Track all entries to add
    file_refs = []
    build_files = []

    for file_info in files_to_add:
        file_path = file_info['path']
        filename = os.path.basename(file_path)

        # Check if file already exists in project
        if filename in content:
            print(f"✓ {filename} already in project")
            continue

        # Generate UUIDs
        file_ref_uuid = generate_uuid()
        build_file_uuid = generate_uuid()

        # Create PBXFileReference
        file_ref = f'\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = "<group>"; }};\n'
        file_refs.append((file_ref_uuid, file_ref, filename, file_info['group']))

        # Create PBXBuildFile
        build_file = f'\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};\n'
        build_files.append((build_file_uuid, build_file, filename))

    if not file_refs:
        print("\nAll files already in project!")
        return

    # Find insertion points
    pbx_file_ref_section = re.search(r'(/\* Begin PBXFileReference section \*/\n)', content)
    pbx_build_file_section = re.search(r'(/\* Begin PBXBuildFile section \*/\n)', content)
    pbx_sources_build_phase = re.search(r'(/\* Sources \*/ = {\n\s+isa = PBXSourcesBuildPhase;\n\s+buildActionMask = \d+;\n\s+files = \(\n)', content)

    if not (pbx_file_ref_section and pbx_build_file_section and pbx_sources_build_phase):
        print("Error: Could not find required sections in project file")
        return

    # Insert PBXFileReference entries
    insert_pos = pbx_file_ref_section.end()
    for _, file_ref, filename, _ in file_refs:
        content = content[:insert_pos] + file_ref + content[insert_pos:]
        insert_pos += len(file_ref)
        print(f"+ Added PBXFileReference for {filename}")

    # Insert PBXBuildFile entries
    insert_pos = content.find('/* Begin PBXBuildFile section */\n') + len('/* Begin PBXBuildFile section */\n')
    for _, build_file, filename in build_files:
        content = content[:insert_pos] + build_file + content[insert_pos:]
        insert_pos += len(build_file)
        print(f"+ Added PBXBuildFile for {filename}")

    # Add to PBXSourcesBuildPhase
    sources_match = re.search(r'(/\* Sources \*/ = {\n\s+isa = PBXSourcesBuildPhase;\n\s+buildActionMask = \d+;\n\s+files = \(\n)', content)
    if sources_match:
        insert_pos = sources_match.end()
        for build_file_uuid, _, filename in build_files:
            build_ref = f'\t\t\t\t{build_file_uuid} /* {filename} in Sources */,\n'
            content = content[:insert_pos] + build_ref + content[insert_pos:]
            insert_pos += len(build_ref)
            print(f"+ Added {filename} to Sources build phase")

    # Add files to their respective groups
    for file_ref_uuid, _, filename, group_name in file_refs:
        # Find the group
        group_pattern = rf'(/\* {group_name} \*/ = {{\n\s+isa = PBXGroup;\n\s+children = \(\n)'
        group_match = re.search(group_pattern, content)

        if group_match:
            insert_pos = group_match.end()
            group_entry = f'\t\t\t\t{file_ref_uuid} /* {filename} */,\n'
            content = content[:insert_pos] + group_entry + content[insert_pos:]
            print(f"+ Added {filename} to {group_name} group")
        else:
            print(f"⚠ Warning: Could not find {group_name} group")

    # Write back to file
    with open(project_path, 'w') as f:
        f.write(content)

    print(f"\n✅ Successfully added {len(file_refs)} files to Xcode project")

if __name__ == '__main__':
    add_files_to_xcode_project()
