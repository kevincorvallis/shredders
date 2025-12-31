#!/bin/bash

# Add new component files to Xcode project

cd "$(dirname "$0")/PowderTracker"

# Files to add
FILES=(
    "PowderTracker/Views/Components/SnowTimelineView.swift"
    "PowderTracker/Views/Components/WeatherSummarySection.swift"
    "PowderTracker/Views/Components/SnowSummarySection.swift"
    "PowderTracker/Views/Components/RoadConditionsSection.swift"
)

# Add to project using xcodeproj gem
cat > /tmp/add_new_components.rb << 'RUBY_SCRIPT'
require 'xcodeproj'

project_path = ARGV[0]
files_to_add = ARGV[1..-1]

project = Xcodeproj::Project.open(project_path)
target = project.targets.first

files_to_add.each do |file_path|
  full_path = File.join(File.dirname(project_path), file_path)

  unless File.exist?(full_path)
    puts "Warning: #{full_path} does not exist, skipping"
    next
  end

  group_path = File.dirname(file_path).split('/')
  current_group = project.main_group

  group_path.each do |group_name|
    next if group_name == '.'
    found_group = current_group.groups.find { |g| g.display_name == group_name }
    if found_group
      current_group = found_group
    else
      current_group = current_group.new_group(group_name)
    end
  end

  file_name = File.basename(file_path)
  existing_file = current_group.files.find { |f| f.display_name == file_name }

  if existing_file
    puts "File #{file_name} already exists in project, skipping"
  else
    file_ref = current_group.new_file(full_path)
    target.source_build_phase.add_file_reference(file_ref)
    puts "✅ Added #{file_name} to project"
  end
end

project.save
puts "✅ Project saved successfully"
RUBY_SCRIPT

export GEM_HOME="$HOME/.gem"
export PATH="$GEM_HOME/bin:$PATH"

ruby /tmp/add_new_components.rb "PowderTracker.xcodeproj" "${FILES[@]}"
rm /tmp/add_new_components.rb

echo "✅ New components added to project"
