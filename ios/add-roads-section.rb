#!/usr/bin/env ruby

require 'xcodeproj'

puts "🔧 Adding RoadConditionsSection to Xcode project...\n"

project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find Location group
location_group = project.main_group['PowderTracker']['Views']['Location']

unless location_group
  puts "❌ Location group not found"
  exit 1
end

# Check if RoadConditionsSection.swift exists in the group
existing = location_group.files.find { |f| f.display_name == 'RoadConditionsSection.swift' }

if existing
  puts "✅ RoadConditionsSection.swift already exists in Location group"

  # Make sure it's in the build phase
  already_in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing }
  unless already_in_build
    target.source_build_phase.add_file_reference(existing)
    puts "   ✅ Added to build phase"
  else
    puts "   ✅ Already in build phase"
  end
else
  puts "📁 Adding RoadConditionsSection.swift..."

  # Add file reference with relative path
  file_ref = location_group.new_file('RoadConditionsSection.swift')
  file_ref.path = 'RoadConditionsSection.swift'
  file_ref.source_tree = '<group>'

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added RoadConditionsSection.swift to Location group"
end

# Save the project
puts "\n💾 Saving project..."
project.save

puts "\n🎉 Done! RoadConditionsSection should now be available."
