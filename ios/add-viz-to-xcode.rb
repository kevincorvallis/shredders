#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create groups
components_group = project.main_group['PowderTracker']['Views']['Components']
services_group = project.main_group['PowderTracker']['Services']

# Create Services group if it doesn't exist
unless services_group
  services_group = project.main_group['PowderTracker'].new_group('Services')
end

# Files to add
files_to_add = [
  {
    path: 'PowderTracker/Views/Components/RadialDashboard.swift',
    group: components_group
  },
  {
    path: 'PowderTracker/Views/Components/AtAGlanceCard.swift',
    group: components_group
  },
  {
    path: 'PowderTracker/Views/Components/LiftLinePredictorCard.swift',
    group: components_group
  },
  {
    path: 'PowderTracker/Services/LiftLinePredictor.swift',
    group: services_group
  }
]

# Add each file
files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]

  # Check if file already exists in project
  existing = group.files.find { |f| f.path == File.basename(file_path) }

  if existing
    puts "⚠️  #{File.basename(file_path)} already exists in project, skipping..."
    next
  end

  # Add file reference
  file_ref = group.new_file(file_path)

  # Add to build phase
  target.source_build_phase.add_file_reference(file_ref)

  puts "✅ Added #{File.basename(file_path)}"
end

# Save the project
project.save

puts "\n🎉 Successfully added all visualization files to Xcode project!"
puts "\nNew components:"
puts "  • RadialDashboard - Apple Watch-style activity rings"
puts "  • AtAGlanceCard - Compact summary with expandable sections"
puts "  • LiftLinePredictorCard - AI-powered crowd predictions"
puts "  • LiftLinePredictor - Prediction engine service"
