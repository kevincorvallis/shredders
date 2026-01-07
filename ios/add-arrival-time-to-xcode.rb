#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'PowderTracker' }

unless target
  puts "❌ Error: Could not find PowderTracker target"
  exit 1
end

# Find groups
models_group = project.main_group['PowderTracker']['Models']
components_group = project.main_group['PowderTracker']['Views']['Components']

unless models_group && components_group
  puts "❌ Error: Could not find Models or Components group"
  exit 1
end

puts "✅ Found groups"

# Add ArrivalTime.swift to Models
arrival_time_model = 'PowderTracker/Models/ArrivalTime.swift'
if File.exist?(arrival_time_model)
  existing = models_group.files.find { |f| f.path == 'ArrivalTime.swift' }

  unless existing
    file_ref = models_group.new_reference('ArrivalTime.swift')
    file_ref.source_tree = '<group>'
    target.add_file_references([file_ref])
    puts "✅ Added ArrivalTime.swift to Models"
  else
    puts "⚠️  ArrivalTime.swift already in project"
  end
else
  puts "❌ ArrivalTime.swift not found"
end

# Add ArrivalTimeCard.swift to Components
arrival_card = 'PowderTracker/Views/Components/ArrivalTimeCard.swift'
if File.exist?(arrival_card)
  existing = components_group.files.find { |f| f.path == 'ArrivalTimeCard.swift' }

  unless existing
    file_ref = components_group.new_reference('ArrivalTimeCard.swift')
    file_ref.source_tree = '<group>'
    target.add_file_references([file_ref])
    puts "✅ Added ArrivalTimeCard.swift to Components"
  else
    puts "⚠️  ArrivalTimeCard.swift already in project"
  end
else
  puts "❌ ArrivalTimeCard.swift not found"
end

# Add QuickArrivalTimeBanner.swift to Components
quick_banner = 'PowderTracker/Views/Components/QuickArrivalTimeBanner.swift'
if File.exist?(quick_banner)
  existing = components_group.files.find { |f| f.path == 'QuickArrivalTimeBanner.swift' }

  unless existing
    file_ref = components_group.new_reference('QuickArrivalTimeBanner.swift')
    file_ref.source_tree = '<group>'
    target.add_file_references([file_ref])
    puts "✅ Added QuickArrivalTimeBanner.swift to Components"
  else
    puts "⚠️  QuickArrivalTimeBanner.swift already in project"
  end
else
  puts "❌ QuickArrivalTimeBanner.swift not found"
end

# Save the project
project.save

puts ""
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts "✅ Successfully added arrival time files!"
puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
puts ""
puts "Next steps:"
puts "  1. Open Xcode"
puts "  2. Clean build folder: Cmd+Shift+K"
puts "  3. Build project: Cmd+B"
puts ""
