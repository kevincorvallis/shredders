tell application "Xcode"
	activate

	-- Wait for Xcode to open
	delay 2

	tell application "System Events"
		tell process "Xcode"
			-- Show instructions dialog
			display dialog "Please add these files to the project:

1. Right-click 'Components' folder
2. Choose 'Add Files to PowderTracker...'
3. Select these files:
   • MountainStatusView.swift
   • NavigateButton.swift
   • SnowfallTableView.swift
4. Uncheck 'Copy items if needed'
5. Check 'PowderTracker' target
6. Click 'Add'

Then press OK here to continue." buttons {"OK"} default button "OK"
		end tell
	end tell
end tell
