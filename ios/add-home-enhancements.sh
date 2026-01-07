#!/bin/bash

PROJECT_DIR="/Users/kevin/Downloads/shredders/ios/PowderTracker"
XCODEPROJ="$PROJECT_DIR/PowderTracker.xcodeproj"

# New component files to add
NEW_FILES=(
  "PowderTracker/Views/Components/BestPowderTodayCard.swift"
  "PowderTracker/Views/Components/EnhancedMountainCard.swift"
  "PowderTracker/Views/Components/QuickStatsDashboard.swift"
)

# Add files to Xcode project using Ruby
ruby << 'RUBY'
require 'xcodeproj'

project_path = '/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.first

# Find or create the Components group
components_group = project.main_group['PowderTracker']['Views']['Components']

files_to_add = [
  'PowderTracker/Views/Components/BestPowderTodayCard.swift',
  'PowderTracker/Views/Components/EnhancedMountainCard.swift',
  'PowderTracker/Views/Components/QuickStatsDashboard.swift'
]

files_to_add.each do |file_path|
  file_name = File.basename(file_path)
  
  # Check if file already exists in project
  existing = components_group.files.find { |f| f.path == file_name }
  next if existing
  
  # Add file reference
  file_ref = components_group.new_file(file_path)
  
  # Add to target
  target.add_file_references([file_ref])
  
  puts "✅ Added #{file_name}"
end

project.save
puts "\n✅ Xcode project updated successfully"
RUBY

