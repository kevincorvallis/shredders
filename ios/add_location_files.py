#!/usr/bin/env python3
import random
import re

def generate_hex_id():
    """Generate a random 24-character hex ID like Xcode uses"""
    return ''.join(random.choices('0123456789ABCDEF', k=24))

# Files to add
files_to_add = [
    {
        'name': 'LocationViewModel.swift',
        'path': 'ViewModels',
        'full_path': 'PowderTracker/ViewModels/LocationViewModel.swift'
    },
    {
        'name': 'LocationView.swift',
        'path': 'Views/Location',
        'full_path': 'PowderTracker/Views/Location/LocationView.swift'
    },
    {
        'name': 'SnowDepthSection.swift',
        'path': 'Views/Location',
        'full_path': 'PowderTracker/Views/Location/SnowDepthSection.swift'
    },
    {
        'name': 'WeatherConditionsSection.swift',
        'path': 'Views/Location',
        'full_path': 'PowderTracker/Views/Location/WeatherConditionsSection.swift'
    },
    {
        'name': 'RoadConditionsSection.swift',
        'path': 'Views/Location',
        'full_path': 'PowderTracker/Views/Location/RoadConditionsSection.swift'
    },
    {
        'name': 'WebcamsSection.swift',
        'path': 'Views/Location',
        'full_path': 'PowderTracker/Views/Location/WebcamsSection.swift'
    }
]

# Generate IDs for each file
for file_info in files_to_add:
    file_info['file_ref_id'] = generate_hex_id()
    file_info['build_file_id'] = generate_hex_id()

# ID for the Location group
location_group_id = generate_hex_id()

# Read the project file
project_path = '/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj/project.pbxproj'
with open(project_path, 'r') as f:
    content = f.read()

# 1. Add PBXBuildFile entries (after the existing ones, before "/* End PBXBuildFile section */")
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
# Find a good place to add file references (after existing swift files)
content = content.replace(
    '/* End PBXFileReference section */',
    f"{file_ref_section}\n/* End PBXFileReference section */"
)

# 3. Add LocationViewModel to ViewModels group
viewmodels_pattern = r'(71616C95900467E5F4B4EAED /\* ViewModels \*/ = \{[^}]+children = \([^)]+)(E558ABF80EA303FC196A18C0 /\* TripPlanningViewModel\.swift \*/,)'
viewmodels_replacement = r'\1\2\n\t\t\t\t' + files_to_add[0]['file_ref_id'] + ' /* LocationViewModel.swift */,'
content = re.sub(viewmodels_pattern, viewmodels_replacement, content)

# 4. Create Location group and add location view files
location_group = f'''		{location_group_id} /* Location */ = {{
			isa = PBXGroup;
			children = (
				{files_to_add[1]['file_ref_id']} /* LocationView.swift */,
				{files_to_add[2]['file_ref_id']} /* SnowDepthSection.swift */,
				{files_to_add[3]['file_ref_id']} /* WeatherConditionsSection.swift */,
				{files_to_add[4]['file_ref_id']} /* RoadConditionsSection.swift */,
				{files_to_add[5]['file_ref_id']} /* WebcamsSection.swift */,
			);
			path = Location;
			sourceTree = "<group>";
		}};
'''

# Add Location group to Views group
views_pattern = r'(FB275362EEA83C2D1C4035C1 /\* Views \*/ = \{[^}]+children = \([^)]+)(AB287A8A884E4E3BD60F605C /\* Components \*/,)'
views_replacement = r'\1' + location_group_id + ' /* Location */,\n\t\t\t\t\\2'
content = re.sub(views_pattern, views_replacement, content)

# Add Location group definition before the Views group closes
views_end_pattern = r'(AB287A8A884E4E3BD60F605C /\* Components \*/ = \{[^}]+\};)'
content = re.sub(views_end_pattern, r'\1\n' + location_group, content)

# 5. Add to PBXSourcesBuildPhase
# Find the main app's sources build phase
sources_phase_pattern = r'(8F5A29C0A8E0C8F9C1D2C6B1 /\* Sources \*/[^}]+files = \([^)]+)(E22BA522BAE84F38BF067A0D /\* SkeletonView\.swift in Sources \*/,)'
sources_entries = []
for file_info in files_to_add:
    sources_entries.append(f'{file_info["build_file_id"]} /* {file_info["name"]} in Sources */')

sources_replacement = r'\1\2\n\t\t\t\t' + ',\n\t\t\t\t'.join(sources_entries) + ','
content = re.sub(sources_phase_pattern, sources_replacement, content)

# Write back
with open(project_path, 'w') as f:
    f.write(content)

print("Successfully added all location files to Xcode project!")
for file_info in files_to_add:
    print(f"  - {file_info['name']}")
