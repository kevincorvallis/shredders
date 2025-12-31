#!/usr/bin/env python3
import re

project_path = 'PowderTracker/PowderTracker.xcodeproj/project.pbxproj'

# Read the project file
with open(project_path, 'r') as f:
    content = f.read()

# Find the line with Favorites ManagementView in the wrong group (Widget Views group)
# We need to remove it from there and add it to the correct Views group

# Find the Views group that contains HomeView.swift (UUID: FB275362EEA83C2D1C4035C1)
# Find the line: "38FF60F28D4E42A989CE5215 /* HomeView.swift */,"
# And add FavoritesManagementView.swift after AlertsView.swift

# First, find and store the UUID for FavoritesManagementView
favorites_uuid_match = re.search(r'([0-9A-F]{24}) /\* FavoritesManagementView\.swift \*/', content)
if not favorites_uuid_match:
    print("Error: Could not find FavoritesManagementView UUID")
    exit(1)

favorites_uuid = favorites_uuid_match.group(1)
print(f"Found FavoritesManagementView UUID: {favorites_uuid}")

# Remove from wrong Widget Views group (around line 221)
# The pattern is: UUID /* FavoritesManagementView.swift */,\n in a children array
wrong_ref_pattern = rf'\t\t\t\t{favorites_uuid} /\* FavoritesManagementView\.swift \*/,\n'
content = re.sub(wrong_ref_pattern, '', content)
print("Removed FavoritesManagementView from Widget Views group")

# Add to correct Views group (FB275362EEA83C2D1C4035C1)
# Find the line with MoreView.swift and add FavoritesManagementView after it
more_view_pattern = r'(B8A56F458BB54E42B1B8B896 /\* MoreView\.swift \*/,\n)'
more_view_match = re.search(more_view_pattern, content)

if more_view_match:
    insert_pos = more_view_match.end()
    new_ref = f'\t\t\t\t{favorites_uuid} /* FavoritesManagementView.swift */,\n'
    content = content[:insert_pos] + new_ref + content[insert_pos:]
    print("Added FavoritesManagementView to correct Views group")
else:
    print("Error: Could not find MoreView.swift to insert after")
    exit(1)

# Write back to file
with open(project_path, 'w') as f:
    f.write(content)

print("✅ Successfully fixed FavoritesManagementView.swift path reference")
