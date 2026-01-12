#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'PowderTracker/PowderTracker.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first
duplicate_files = [
  'TabbedLocationView.swift',
  'MountainsView.swift',
  'TravelTab.swift'
]

puts "🔍 Searching for duplicate build file entries..."

duplicate_files.each do |filename|
  found_files = []

  target.source_build_phase.files.each do |build_file|
    if build_file.file_ref && build_file.file_ref.path&.include?(filename)
      found_files << build_file
    end
  end

  if found_files.count > 1
    puts "\n📋 Found #{found_files.count} entries for #{filename}"
    found_files[1..-1].each do |duplicate|
      puts "  ❌ Removing duplicate: #{duplicate.file_ref.path}"
      target.source_build_phase.files.delete(duplicate)
    end
    puts "  ✅ Kept: #{found_files.first.file_ref.path}"
  elsif found_files.count == 1
    puts "✓ #{filename} - OK (only one entry)"
  else
    puts "⚠️  #{filename} - Not found in build phase"
  end
end

project.save

puts "\n🎉 Cleaned up duplicate build file entries!"
