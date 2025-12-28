#!/bin/bash

# Script to add skeleton files to Xcode project
# This is needed because creating files in the filesystem doesn't automatically add them to Xcode

echo "Adding skeleton files to Xcode project..."

cd /Users/kevin/Downloads/shredders/ios/PowderTracker

# The skeleton files
SKELETON_FILES=(
    "PowderTracker/Views/Components/Skeletons/SkeletonView.swift"
    "PowderTracker/Views/Components/Skeletons/DashboardSkeleton.swift"
    "PowderTracker/Views/Components/Skeletons/ForecastSkeleton.swift"
    "PowderTracker/Views/Components/Skeletons/ListSkeleton.swift"
)

# Check if files exist
echo ""
echo "Checking files..."
for file in "${SKELETON_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ Found: $file"
    else
        echo "❌ Missing: $file"
        exit 1
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "FILES EXIST BUT NOT IN XCODE PROJECT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To add these files to your Xcode project:"
echo ""
echo "OPTION 1 - Using Xcode (Recommended):"
echo "  1. Open PowderTracker.xcodeproj in Xcode"
echo "  2. Right-click 'Views/Components' folder in Project Navigator"
echo "  3. Select 'Add Files to PowderTracker...'"
echo "  4. Navigate to: Views/Components/Skeletons"
echo "  5. Select ALL 4 .swift files"
echo "  6. Make sure 'Copy items if needed' is UNCHECKED"
echo "  7. Make sure 'PowderTracker' target is CHECKED"
echo "  8. Click 'Add'"
echo ""
echo "OPTION 2 - Automatic (if you have ruby installed):"
echo "  Run: cd ios && bundle exec pod install"
echo "  Or use xcodeproj gem to modify project"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Try to add using ruby/xcodeproj if available
if command -v ruby &> /dev/null; then
    echo "Attempting to add files automatically using Ruby..."

    cat > /tmp/add_files.rb << 'RUBY_SCRIPT'
#!/usr/bin/env ruby
require 'xcodeproj'

project_path = '/Users/kevin/Downloads/shredders/ios/PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Find or create the Skeletons group
views_group = project.main_group['PowderTracker']['Views']['Components']
skeletons_group = views_group.new_group('Skeletons', 'PowderTracker/Views/Components/Skeletons')

# Files to add
files = [
  'PowderTracker/Views/Components/Skeletons/SkeletonView.swift',
  'PowderTracker/Views/Components/Skeletons/DashboardSkeleton.swift',
  'PowderTracker/Views/Components/Skeletons/ForecastSkeleton.swift',
  'PowderTracker/Views/Components/Skeletons/ListSkeleton.swift'
]

files.each do |file|
  file_ref = skeletons_group.new_reference(file)
  target.add_file_references([file_ref])
  puts "✅ Added: #{file}"
end

project.save
puts ""
puts "✅ Files added to Xcode project successfully!"
RUBY_SCRIPT

    ruby /tmp/add_files.rb 2>/dev/null

    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ SUCCESS! Files added automatically."
        echo "   Now open Xcode and build the project."
        exit 0
    else
        echo "❌ Automatic add failed. Please use OPTION 1 above."
        exit 1
    fi
else
    echo "Ruby not available. Please use OPTION 1 above."
    exit 1
fi
