#!/usr/bin/env ruby

# Script to automatically add Tabs files to Xcode project using xcodeproj gem

begin
  require 'xcodeproj'
rescue LoadError
  puts "❌ Error: xcodeproj gem not installed"
  puts ""
  puts "Install it with:"
  puts "  gem install xcodeproj"
  puts ""
  puts "Or run the manual steps in: add-tabs-to-xcode.sh"
  exit 1
end

project_path = 'PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'PowderTracker' }

unless target
  puts "❌ Error: Could not find PowderTracker target"
  exit 1
end

# Find or create the Views/Location group
location_group = project.main_group['PowderTracker']['Views']['Location']

unless location_group
  puts "❌ Error: Could not find Views/Location group"
  exit 1
end

puts "✅ Found Views/Location group"

# Add TabbedLocationView.swift to Location group
tabbed_view_file = 'PowderTracker/Views/Location/TabbedLocationView.swift'
if File.exist?(tabbed_view_file)
  file_ref = location_group.new_file(tabbed_view_file)
  target.add_file_references([file_ref])
  puts "✅ Added TabbedLocationView.swift"
else
  puts "⚠️  TabbedLocationView.swift not found"
end

# Create or find Tabs group
tabs_group = location_group['Tabs'] || location_group.new_group('Tabs', 'PowderTracker/Views/Location/Tabs')
puts "✅ Created/found Tabs group"

# Add all tab files
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

added_count = 0
tab_files.each do |filename|
  filepath = "PowderTracker/Views/Location/Tabs/#{filename}"

  if File.exist?(filepath)
    # Check if file already exists in project
    existing = tabs_group.files.find { |f| f.path == filename }

    unless existing
      file_ref = tabs_group.new_file(filepath)
      target.add_file_references([file_ref])
      puts "✅ Added #{filename}"
      added_count += 1
    else
      puts "⚠️  #{filename} already in project"
    end
  else
    puts "❌ #{filename} not found at #{filepath}"
  end
end

# Save the project
project.save

puts ""
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "✅ Successfully added #{added_count} files to Xcode project"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""
puts "Next steps:"
puts "  1. Open Xcode"
puts "  2. Clean build folder: Cmd+Shift+K"
puts "  3. Build project: Cmd+B"
puts ""
