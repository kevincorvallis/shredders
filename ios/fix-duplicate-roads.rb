#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find the duplicate file reference in Components group
components_group = project.main_group['PowderTracker']['Views']['Components']

if components_group
  # Find RoadConditionsSection.swift in Components
  road_file = components_group.files.find { |f| f.path == 'RoadConditionsSection.swift' }

  if road_file
    puts "Found duplicate RoadConditionsSection.swift in Components group"

    # Remove from build phase
    target.source_build_phase.files.each do |build_file|
      if build_file.file_ref == road_file
        target.source_build_phase.files.delete(build_file)
        puts "  ✅ Removed from build phase"
      end
    end

    # Remove file reference
    road_file.remove_from_project
    puts "  ✅ Removed file reference"
  else
    puts "⚠️  File reference not found in Components group"
  end
end

# Save the project
project.save

puts "\n🎉 Fixed duplicate RoadConditionsSection!"
puts "The correct version in Views/Location/ will be used."
