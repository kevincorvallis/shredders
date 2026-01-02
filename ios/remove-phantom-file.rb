#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Find the phantom LiftData.swift file reference
phantom_path = 'PowderTracker/Models/PowderTracker/Models/LiftData.swift'

# Remove from build phase
target.source_build_phase.files.each do |build_file|
  if build_file.file_ref && build_file.file_ref.path&.include?('LiftData.swift')
    puts "Found phantom file in build phase: #{build_file.file_ref.path}"
    target.source_build_phase.files.delete(build_file)
    puts "  ✅ Removed from build phase"
  end
end

# Find and remove file references
project.files.each do |file_ref|
  if file_ref.path&.include?('LiftData.swift')
    puts "Found phantom file reference: #{file_ref.path}"
    file_ref.remove_from_project
    puts "  ✅ Removed file reference"
  end
end

project.save

puts "\n🎉 Cleaned up phantom LiftData.swift reference!"
