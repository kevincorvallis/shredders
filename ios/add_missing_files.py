#!/usr/bin/env python3
import random
import re

def generate_hex_id():
    """Generate a random 24-character hex ID like Xcode uses"""
    return ''.join(random.choices('0123456789ABCDEF', k=24))

# Files to add
files_to_add = [
    {
        'name': 'SunData.swift',
        'path': 'Models',
        'full_path': 'PowderTracker/Models/SunData.swift'
    },
    {
        'name': 'FavoriteMountain.swift',
        'path': 'Models',
        'full_path': 'PowderTracker/Models/FavoriteMountain.swift'
    },
    {
        'name': 'FavoritesManager.swift',
        'path': 'Services',
        'full_path': 'PowderTracker/Services/FavoritesManager.swift'
    }
]

# Generate IDs for each file
for file_info in files_to_add:
    file_info['file_ref_id'] = generate_hex_id()
    file_info['build_file_id'] = generate_hex_id()

# Read the project file
project_path = '/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj/project.pbxproj'
with open(project_path, 'r') as f:
    content = f.read()

# 1. Add PBXBuildFile entries
build_file_entries = []
for file_info in files_to_add:
    entry = f"\t\t{file_info['build_file_id']} /* {file_info['name']} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_info['file_ref_id']} /* {file_info['name']} */; }};"
    build_file_entries.append(entry)

build_file_section = '\n'.join(build_file_entries)
content = content.replace(
    '/* End PBXBuildFile section */',
    f"{build_file_section}\n/* End PBXBuildFile section */"
)

# 2. Add PBXFileReference entries
file_ref_entries = []
for file_info in files_to_add:
    entry = f"\t\t{file_info['file_ref_id']} /* {file_info['name']} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_info['name']}; sourceTree = \"<group>\"; }};"
    file_ref_entries.append(entry)

file_ref_section = '\n'.join(file_ref_entries)
content = content.replace(
    '/* End PBXFileReference section */',
    f"{file_ref_section}\n/* End PBXFileReference section */"
)

# 3. Add files to their respective groups
# Add SunData.swift and FavoriteMountain.swift to Models group
models_pattern = r'(F0B99B6E05E8E7AF6A27AF90 /\* Models \*/ = \{[^}]+children = \([^)]+)(F1DB3CEAE1D17C9CCA7D7FF5 /\* TripPlanning\.swift \*/,)'
models_addition = (
    f"{files_to_add[0]['file_ref_id']} /* SunData.swift */,\n\t\t\t\t"
    f"{files_to_add[1]['file_ref_id']} /* FavoriteMountain.swift */,"
)
models_replacement = r'\1' + models_addition + '\n\t\t\t\t\\2'
content = re.sub(models_pattern, models_replacement, content)

# Add FavoritesManager.swift to Services group (need to find or create it)
# First, let's check if Services group exists
if 'Services' not in content or '/* Services */' not in content:
    # Services group doesn't exist, we need to create it
    # Find the PowderTracker group and add Services to it
    powdertracker_pattern = r'(80E6C6A255B1EC04EE1B0F17 /\* PowderTracker \*/ = \{[^}]+children = \([^)]+)(F0B99B6E05E8E7AF6A27AF90 /\* Models \*/,)'
    services_group_id = generate_hex_id()
    services_addition = f"{services_group_id} /* Services */,\n\t\t\t\t"
    content = re.sub(powdertracker_pattern, r'\1' + services_addition + r'\2', content)

    # Create the Services group definition
    services_group = f'''		{services_group_id} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{files_to_add[2]['file_ref_id']} /* FavoritesManager.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
'''
    # Add after Models group definition
    models_def_pattern = r'(F0B99B6E05E8E7AF6A27AF90 /\* Models \*/ = \{[^}]+\};)'
    content = re.sub(models_def_pattern, r'\1\n' + services_group, content)
else:
    # Services group exists, just add the file to it
    services_pattern = r'(/\* Services \*/ = \{[^}]+children = \([^)]+)(\s+\);)'
    services_replacement = r'\1\t\t\t\t' + files_to_add[2]['file_ref_id'] + ' /* FavoritesManager.swift */,\n\2'
    content = re.sub(services_pattern, services_replacement, content)

# 4. Add to PBXSourcesBuildPhase
# Find the sources build phase and add the build file references
sources_phase_pattern = r'(8F5A29C0A8E0C8F9C1D2C6B1 /\* Sources \*/[^}]+files = \([^)]+)(\s+\);)'
sources_entries = []
for file_info in files_to_add:
    sources_entries.append(f'{file_info["build_file_id"]} /* {file_info["name"]} in Sources */')

sources_addition = '\t\t\t\t' + ',\n\t\t\t\t'.join(sources_entries) + ','
content = re.sub(sources_phase_pattern, r'\1' + sources_addition + r'\n\2', content)

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("Successfully added missing files to Xcode project!")
for file_info in files_to_add:
    print(f"  - {file_info['name']}")
