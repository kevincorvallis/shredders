//
//  AppStoreScreenshots.swift
//  PowderTrackerUITests
//
//  Automated App Store screenshot capture.
//  Run with: xcodebuild test -scheme PowderTracker -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' -only-testing:PowderTrackerUITests/AppStoreScreenshots
//

import XCTest

@MainActor
final class AppStoreScreenshots: XCTestCase {
    var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING", "SCREENSHOTS"]
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() async throws {
        app = nil
    }

	
    @MainActor
    func testCaptureRemainingScreenshots() {
        // Wait for app to fully load
        sleep(5)

        // Debug: print all tab bar buttons
        let tabBar = app.tabBars.firstMatch
        _ = tabBar.waitForExistence(timeout: 10)
 
        print("Tab bar exists: \(tabBar.exists)")
        print("All tab buttons:")
        for button in tabBar.buttons.allElementsBoundByIndex {
            print("  - Button: '\(button.label)' identifier: '\(button.identifier)'")
        }

        // Take debug screenshot to see current state
        snapshot("00_iPad_Debug")

        // Try tapping tabs by index if labels don't match
        let allButtons = tabBar.buttons.allElementsBoundByIndex

        // Tab order: Today (0), Mountains (1), Map (2), Events (3), Profile (4)
        if allButtons.count > 2 {
            allButtons[2].tap() // Map
            sleep(3)
            snapshot("04_MapView")
        }

        if allButtons.count > 3 {
            allButtons[3].tap() // Events
            sleep(2)
            snapshot("05_EventsList")
        }

        if allButtons.count > 4 {
            allButtons[4].tap() // Profile
            sleep(2)
            snapshot("06_Profile")
        }
    }

    @MainActor
    func testCaptureAppStoreScreenshots() {
        // Wait for app to fully load
        sleep(3)

        // 1. Today Dashboard
        let todayTab = app.tabBars.buttons["Today"].firstMatch
        if todayTab.waitForExistence(timeout: 5) {
            todayTab.tap()
            sleep(2)
            snapshot("01_TodayDashboard")
        }

        // 2. Mountains List
        let mountainsTab = app.tabBars.buttons["Mountains"].firstMatch
        if mountainsTab.waitForExistence(timeout: 5) {
            mountainsTab.tap()
            sleep(2)
            snapshot("02_MountainsList")
        }

        // 3. Mountain Detail - tap first mountain
        let scrollView = app.scrollViews.firstMatch
        if scrollView.waitForExistence(timeout: 3) {
            let mountainCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'score' OR label CONTAINS[c] 'Open' OR label CONTAINS[c] 'Closed'")).firstMatch
            if mountainCard.waitForExistence(timeout: 5) && mountainCard.isHittable {
                mountainCard.tap()
                sleep(2)
                snapshot("03_MountainDetail")

                // Go back - try multiple approaches
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists && backButton.isHittable {
                    backButton.tap()
                    sleep(1)
                } else {
                    // Try swiping back
                    app.swipeRight()
                    sleep(1)
                }
            }
        }

        // 4. Map View - ensure we can find the tab bar
        sleep(1)
        let mapTab = app.tabBars.buttons["Map"].firstMatch
        print("Map tab exists: \(mapTab.exists), hittable: \(mapTab.isHittable)")
        if mapTab.waitForExistence(timeout: 5) {
            mapTab.tap()
            sleep(3) // Wait for map tiles to load
            snapshot("04_MapView")
        } else {
            print("ERROR: Map tab not found")
        }

        // 5. Events List
        let eventsTab = app.tabBars.buttons["Events"].firstMatch
        print("Events tab exists: \(eventsTab.exists), hittable: \(eventsTab.isHittable)")
        if eventsTab.waitForExistence(timeout: 5) {
            eventsTab.tap()
            sleep(2)
            snapshot("05_EventsList")
        } else {
            print("ERROR: Events tab not found")
        }

        // 6. Profile
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        print("Profile tab exists: \(profileTab.exists), hittable: \(profileTab.isHittable)")
        if profileTab.waitForExistence(timeout: 5) {
            profileTab.tap()
            sleep(2)
            snapshot("06_Profile")
        } else {
            print("ERROR: Profile tab not found")
        }
    }

    // MARK: - Snapshot Helper

    @MainActor
    private func setupSnapshot(_ app: XCUIApplication) {
        // Snapshot setup for fastlane compatibility
        Snapshot.setupSnapshot(app, waitForAnimations: true)
    }

    @MainActor
    private func snapshot(_ name: String) {
        // Take screenshot and save as attachment
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Determine device type using UIImage pixel dimensions (not CGSize points)
        let image = screenshot.image
        let pixelWidth = image.cgImage?.width ?? 0
        let pixelHeight = image.cgImage?.height ?? 0
        let minPixelDim = min(pixelWidth, pixelHeight)
        // iPad 12.9" is 2048x2732 pixels, iPad 11" is 1668x2388 pixels
        // iPhone 6.7" is 1290x2796 pixels
        // Key difference: iPad minimum pixel dimension > 1350 (to handle 11" iPad)
        let isIPad = minPixelDim > 1350

        // Debug logging
        print("Pixel dimensions: \(pixelWidth)x\(pixelHeight), minPixelDim: \(minPixelDim), isIPad: \(isIPad)")

        // Also save to file
        let data = screenshot.pngRepresentation
        let dir = isIPad
            ? "/Users/kevin/Downloads/Projects/shredders/ios/PowderTracker/AppStore/Screenshots/12.9-inch"
            : "/Users/kevin/Downloads/Projects/shredders/ios/PowderTracker/AppStore/Screenshots/6.7-inch"
        let path = "\(dir)/\(name).png"
        try? data.write(to: URL(fileURLWithPath: path))
        print("Screenshot saved: \(name) to \(isIPad ? "iPad" : "iPhone") folder at \(path)")
    }
}

// Minimal Snapshot helper for standalone use
enum Snapshot {
    static func setupSnapshot(_ app: XCUIApplication, waitForAnimations: Bool) {
        // No-op for standalone - fastlane would provide this
    }
}
