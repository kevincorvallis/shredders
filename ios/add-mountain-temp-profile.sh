#!/bin/bash

cd /Users/kevin/Downloads/shredders/ios

# Add the new file to Xcode project
ruby -r xcodeproj <<'RUBY'
project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the Components group
components_group = project.main_group.find_subpath('PowderTracker/Views/Components', true)

# Add the new file
file_ref = components_group.new_file('MountainTemperatureProfile.swift')

# Add to target
target = project.targets.first
target.add_file_references([file_ref])

project.save

puts "✅ Added MountainTemperatureProfile.swift to Xcode project"
RUBY
