#!/usr/bin/env ruby

# Script to fix the duplicated paths and correctly add Tabs files

require 'xcodeproj'

project_path = 'PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'PowderTracker' }

# First, remove all the incorrectly added files
location_group = project.main_group['PowderTracker']['Views']['Location']

puts "🔧 Removing incorrectly added files..."

# Remove TabbedLocationView if it exists
tabbed_view_ref = location_group.files.find { |f| f.path&.include?('TabbedLocationView') }
if tabbed_view_ref
  tabbed_view_ref.remove_from_project
  puts "  ✓ Removed incorrect TabbedLocationView reference"
end

# Remove Tabs group if it exists
tabs_group = location_group['Tabs']
if tabs_group
  tabs_group.clear
  tabs_group.remove_from_project
  puts "  ✓ Removed incorrect Tabs group"
end

puts ""
puts "✅ Adding files with correct paths..."

# Add TabbedLocationView.swift with relative path
file_ref = location_group.new_reference('TabbedLocationView.swift')
file_ref.source_tree = '<group>'
target.add_file_references([file_ref])
puts "  ✓ Added TabbedLocationView.swift"

# Create Tabs group with correct path
tabs_group = location_group.new_group('Tabs')
tabs_group.source_tree = '<group>'
tabs_group.path = 'Tabs'

# Add all tab files with just filenames (not full paths)
tab_files = [
  'OverviewTab.swift',
  'ForecastTab.swift',
  'HistoryTab.swift',
  'TravelTab.swift',
  'SafetyTab.swift',
  'WebcamsTab.swift',
  'SocialTab.swift',
  'LiftsTab.swift'
]

tab_files.each do |filename|
  file_ref = tabs_group.new_reference(filename)
  file_ref.source_tree = '<group>'
  target.add_file_references([file_ref])
  puts "  ✓ Added #{filename}"
end

# Save the project
project.save

puts ""
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "✅ Successfully fixed and added all files!"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""
