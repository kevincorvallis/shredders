#!/usr/bin/env ruby
require 'securerandom'

def gen_id
  SecureRandom.hex(12).upcase
end

# Generate build file IDs for widget extension
sundata_widget_build = gen_id
favoritemountain_widget_build = gen_id

project_path = 'PowderTracker/PowderTracker.xcodeproj/project.pbxproj'
content = File.read(project_path)

# Get the existing file reference IDs for SunData and FavoriteMountain
sundata_ref = content[/([A-F0-9]+) \/\* SunData\.swift \*\/ = \{isa = PBXFileReference/, 1]
favoritemountain_ref = content[/([A-F0-9]+) \/\* FavoriteMountain\.swift \*\/ = \{isa = PBXFileReference/, 1]

puts "SunData ref: #{sundata_ref}"
puts "FavoriteMountain ref: #{favoritemountain_ref}"

# 1. Add build file entries for widget extension
build_entries = <<~BUILD
\t\t#{sundata_widget_build} /* SunData.swift in Sources */ = {isa = PBXBuildFile; fileRef = #{sundata_ref} /* SunData.swift */; };
\t\t#{favoritemountain_widget_build} /* FavoriteMountain.swift in Sources */ = {isa = PBXBuildFile; fileRef = #{favoritemountain_ref} /* FavoriteMountain.swift */; };
BUILD

content.sub!('/* End PBXBuildFile section */', "#{build_entries}/* End PBXBuildFile section */")

# 2. Add to widget extension sources build phase (before TripPlanning.swift)
content.sub!(/(1B935F4BCD0BFE2CD5F747DE \/\* Sources \*\/.*?files = \(.*?CF58C94B833F15B2364444DF \/\* TripPlanning\.swift in Sources \*\/,)/m) do
  "#{$1}\n\t\t\t\t#{sundata_widget_build} /* SunData.swift in Sources */,\n\t\t\t\t#{favoritemountain_widget_build} /* FavoriteMountain.swift in Sources */,"
end

File.write(project_path, content)
puts "Successfully added SunData and FavoriteMountain to Widget Extension!"
