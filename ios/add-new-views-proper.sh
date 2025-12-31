#!/bin/bash

# Add NewHomeView and NewMountainsView to Xcode project using xcodeproj gem

cd "$(dirname "$0")/PowderTracker"

# Files to add
FILES=(
    "PowderTracker/Views/NewHomeView.swift"
    "PowderTracker/Views/NewMountainsView.swift"
)

# Add to project using xcodeproj gem
cat > /tmp/add_new_views.rb << 'RUBY_SCRIPT'
require 'xcodeproj'

project_path = ARGV[0]
files_to_add = ARGV[1..-1]

project = Xcodeproj::Project.open(project_path)
target = project.targets.first

files_to_add.each do |file_path|
  # Get relative path from project
  full_path = File.join(File.dirname(project_path), file_path)

  # Skip if file doesn't exist
  unless File.exist?(full_path)
    puts "Warning: #{full_path} does not exist, skipping"
    next
  end

  # Add file reference
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

  # Check if file already exists in group
  file_name = File.basename(file_path)
  existing_file = current_group.files.find { |f| f.display_name == file_name }

  if existing_file
    puts "File #{file_name} already exists in project"
  else
    # Add file reference
    file_ref = current_group.new_file(full_path)

    # Add to build phase
    target.source_build_phase.add_file_reference(file_ref)

    puts "Added #{file_name} to project"
  end
end

project.save
puts "Project saved successfully"
RUBY_SCRIPT

# Check if xcodeproj gem is installed
if ! gem list xcodeproj -i > /dev/null 2>&1; then
    echo "Installing xcodeproj gem..."
    gem install xcodeproj
fi

# Run the Ruby script
ruby /tmp/add_new_views.rb "PowderTracker.xcodeproj" "${FILES[@]}"

# Clean up
rm /tmp/add_new_views.rb

echo "✅ Files added to Xcode project"
echo ""
echo "Files added:"
for file in "${FILES[@]}"; do
    echo "  - $file"
done
echo ""
echo "Please rebuild the project to verify"
