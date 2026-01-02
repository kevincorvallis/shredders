#!/usr/bin/env ruby

require 'xcodeproj'

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

# Check if RoadConditionsSection.swift already exists
existing = location_group.files.find { |f| f.path == 'RoadConditionsSection.swift' }

if existing
  puts "✅ RoadConditionsSection.swift already in project"
else
  # Add file reference
  file_ref = location_group.new_file('PowderTracker/Views/Location/RoadConditionsSection.swift')

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added RoadConditionsSection.swift to Location group"
end

# Save the project
project.save

puts "\n🎉 Done!"
