#!/usr/bin/env ruby

require 'xcodeproj'

puts "🔧 Adding creative visualization files to Xcode project...\n\n"

project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create groups
main_group = project.main_group['PowderTracker']
views_group = main_group['Views']
components_group = views_group['Components']

# Create Services group if it doesn't exist
services_group = main_group['Services']
unless services_group
  puts "📁 Creating Services group..."
  services_group = main_group.new_group('Services', 'PowderTracker/Services')
end

# Files to add
files_to_add = [
  {
    path: 'PowderTracker/Views/Components/RadialDashboard.swift',
    group: components_group,
    name: 'RadialDashboard.swift'
  },
  {
    path: 'PowderTracker/Views/Components/AtAGlanceCard.swift',
    group: components_group,
    name: 'AtAGlanceCard.swift'
  },
  {
    path: 'PowderTracker/Views/Components/LiftLinePredictorCard.swift',
    group: components_group,
    name: 'LiftLinePredictorCard.swift'
  },
  {
    path: 'PowderTracker/Services/LiftLinePredictor.swift',
    group: services_group,
    name: 'LiftLinePredictor.swift'
  }
]

# Add each file
files_to_add.each do |file_info|
  file_path = file_info[:path]
  group = file_info[:group]
  file_name = file_info[:name]

  # Check if file already exists in project
  existing = group.files.find { |f| f.path == file_name }

  if existing
    puts "⚠️  #{file_name} already exists in project"

    # Make sure it's in the build phase
    already_in_build = target.source_build_phase.files.any? { |bf| bf.file_ref == existing }
    unless already_in_build
      target.source_build_phase.add_file_reference(existing)
      puts "   ✅ Added to build phase"
    end
  else
    # Add file reference
    file_ref = group.new_file(file_path)

    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "✅ Added #{file_name}"
  end
end

# Save the project
puts "\n💾 Saving project..."
project.save

puts "\n🎉 Success! All visualization files added to Xcode project!"
puts "\nFiles added:"
puts "  • RadialDashboard.swift - Apple Watch-style rings"
puts "  • AtAGlanceCard.swift - Compact summary card"
puts "  • LiftLinePredictorCard.swift - AI predictions UI"
puts "  • LiftLinePredictor.swift - Prediction engine"
puts "\nNext steps:"
puts "  1. Open LocationView.swift in Xcode"
puts "  2. Uncomment the TODO sections (lines ~35-55)"
puts "  3. Build and run! (Cmd+R)"
