#!/usr/bin/env ruby
require 'securerandom'

def gen_id
  SecureRandom.hex(12).upcase
end

# Generate IDs for all files
files = [
  { name: 'LocationViewModel.swift', group: 'ViewModels' },
  { name: 'SunData.swift', group: 'Models' },
  { name: 'FavoriteMountain.swift', group: 'Models' },
  { name: 'FavoritesManager.swift', group: 'Services' },
  { name: 'LocationView.swift', group: 'Views/Location' },
  { name: 'SnowDepthSection.swift', group: 'Views/Location' },
  { name: 'WeatherConditionsSection.swift', group: 'Views/Location' },
  { name: 'RoadConditionsSection.swift', group: 'Views/Location' },
  { name: 'WebcamsSection.swift', group: 'Views/Location' }
]

location_group_id = gen_id

files.each do |f|
  f[:file_ref] = gen_id
  f[:build_file] = gen_id
end

project_path = 'PowderTracker/PowderTracker.xcodeproj/project.pbxproj'
content = File.read(project_path)

# 1. Add PBXBuildFile entries (before /* End PBXBuildFile section */)
build_entries = files.map do |f|
  "\t\t#{f[:build_file]} /* #{f[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{f[:file_ref]} /* #{f[:name]} */; };"
end.join("\n")

content.sub!('/* End PBXBuildFile section */', "#{build_entries}\n/* End PBXBuildFile section */")

# 2. Add PBXFileReference entries
ref_entries = files.map do |f|
  "\t\t#{f[:file_ref]} /* #{f[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{f[:name]}; sourceTree = \"<group>\"; };"
end.join("\n")

content.sub!('/* End PBXFileReference section */', "#{ref_entries}\n/* End PBXFileReference section */")

# 3. Add LocationViewModel to ViewModels group (before closing paren)
content.sub!(/(71616C95900467E5F4B4EAED \/\* ViewModels \*\/ = \{.*?children = \(.*?E558ABF80EA303FC196A18C0 \/\* TripPlanningViewModel\.swift \*\/,)/m) do
  "#{$1}\n\t\t\t\t#{files[0][:file_ref]} /* LocationViewModel.swift */,"
end

# 4. Add SunData and FavoriteMountain to Models group  
content.sub!(/(F0B99B6E05E8E7AF6A27AF90 \/\* Models \*\/ = \{.*?children = \(.*?F1DB3CEAE1D17C9CCA7D7FF5 \/\* TripPlanning\.swift \*\/,)/m) do
  "#{$1}\n\t\t\t\t#{files[1][:file_ref]} /* SunData.swift */,\n\t\t\t\t#{files[2][:file_ref]} /* FavoriteMountain.swift */,"
end

# 5. Add FavoritesManager to Services group
content.sub!(/(848CD3FF1F0ED180B6A41DBD \/\* Services \*\/ = \{.*?children = \(.*?2157D2D009AB7E7771B8E03B \/\* LocationManager\.swift \*\/,)/m) do
  "#{$1}\n\t\t\t\t#{files[3][:file_ref]} /* FavoritesManager.swift */,"
end

# 6. Create Location group
location_group = <<~GROUP
\t\t#{location_group_id} /* Location */ = {
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t#{files[4][:file_ref]} /* LocationView.swift */,
\t\t\t\t#{files[5][:file_ref]} /* SnowDepthSection.swift */,
\t\t\t\t#{files[6][:file_ref]} /* WeatherConditionsSection.swift */,
\t\t\t\t#{files[7][:file_ref]} /* RoadConditionsSection.swift */,
\t\t\t\t#{files[8][:file_ref]} /* WebcamsSection.swift */,
\t\t\t);
\t\t\tpath = Location;
\t\t\tsourceTree = "<group>";
\t\t};
GROUP

# Add Location to Views group's children list
content.sub!(/(FB275362EEA83C2D1C4035C1 \/\* Views \*\/ = \{.*?children = \(.*?AAD53D080257007E2F41F249 \/\* WebcamsView\.swift \*\/,)/m) do
  "#{$1}\n\t\t\t\t#{location_group_id} /* Location */,"
end

# Add Location group definition (after Components group closes)
content.sub!(/(AB287A8A884E4E3BD60F605C \/\* Components \*\/ = \{[^}]*\};)/m) do
  "#{$1}\n#{location_group}"
end

# 7. Add to Sources build phase
content.sub!(/(8F5A29C0A8E0C8F9C1D2C6B1 \/\* Sources \*\/.*?files = \(.*?E22BA522BAE84F38BF067A0D \/\* SkeletonView\.swift in Sources \*\/,)/m) do
  build_refs = files.map { |f| "\t\t\t\t#{f[:build_file]} /* #{f[:name]} in Sources */," }.join("\n")
  "#{$1}\n#{build_refs}"
end

File.write(project_path, content)
puts "Successfully added all files!"
files.each { |f| puts "  - #{f[:name]}" }
