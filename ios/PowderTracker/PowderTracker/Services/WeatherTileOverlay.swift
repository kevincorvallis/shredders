//
//  WeatherTileOverlay.swift
//  PowderTracker
//
//  Custom MKTileOverlay for displaying weather data overlays.
//  Supports radar, clouds, temperature, precipitation, and more.
//

import MapKit
import UIKit

// MARK: - Weather Tile Overlay

/// Tile overlay for weather data from various providers
class WeatherTileOverlay: MKTileOverlay {
    let overlayType: MapOverlayType
    private let timestamp: Int?

    /// OpenWeatherMap API key (optional - some overlays work without it)
    private static var openWeatherMapKey: String? {
        AppConfig.openWeatherMapAPIKey
    }

    /// Initialize weather overlay
    /// - Parameters:
    ///   - overlayType: The type of weather overlay
    ///   - timestamp: Unix timestamp for time-based overlays (radar, etc.)
    /// - Returns: nil if the overlay type doesn't have a valid URL template
    init?(overlayType: MapOverlayType, timestamp: Int? = nil) {
        self.overlayType = overlayType
        self.timestamp = timestamp

        // Get URL template based on overlay type - return nil if unavailable
        guard let urlTemplate = Self.urlTemplate(for: overlayType, timestamp: timestamp) else {
            return nil
        }
        super.init(urlTemplate: urlTemplate)

        // Configure overlay properties
        self.canReplaceMapContent = false
        self.minimumZ = 3
        self.maximumZ = 12

        // Set tile size (most providers use 256x256)
        self.tileSize = CGSize(width: 256, height: 256)
    }

    /// Get URL template for overlay type - returns nil for unavailable overlays
    /// Note: Prefers RainViewer for overlays that support it (more reliable, no API key needed)
    private static func urlTemplate(for overlayType: MapOverlayType, timestamp: Int?) -> String? {
        switch overlayType {
        case .radar:
            // RainViewer API (free, no key needed)
            // Uses most recent radar frame if no timestamp provided
            let ts = timestamp ?? Int(Date().timeIntervalSince1970)
            return "https://tilecache.rainviewer.com/v2/radar/\(ts)/256/{z}/{x}/{y}/2/1_1.png"

        case .clouds:
            // Prefer RainViewer satellite/infrared (more reliable, no API key)
            return "https://tilecache.rainviewer.com/v2/satellite/nowcast_raw/256/{z}/{x}/{y}/0/0_0.png"

        case .temperature:
            // OpenWeatherMap temperature layer (no free alternative)
            if let key = openWeatherMapKey {
                return "https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=\(key)"
            }
            return nil

        case .wind:
            // OpenWeatherMap wind layer (no free alternative)
            if let key = openWeatherMapKey {
                return "https://tile.openweathermap.org/map/wind_new/{z}/{x}/{y}.png?appid=\(key)"
            }
            return nil

        case .snowfall, .snowDepth:
            // Use RainViewer radar for precipitation (more reliable than OpenWeatherMap)
            let ts = timestamp ?? Int(Date().timeIntervalSince1970)
            return "https://tilecache.rainviewer.com/v2/radar/\(ts)/256/{z}/{x}/{y}/2/1_1.png"

        case .smoke:
            // NOAA HRRR Smoke (via Iowa State Mesonet)
            // This shows surface smoke concentration
            return "https://mesonet.agron.iastate.edu/cache/tile.py/1.0.0/hrrr::MASSDEN/{z}/{x}/{y}.png"

        case .avalanche:
            // Avalanche data would need to come from NWAC/regional centers
            return nil

        case .landOwnership, .offlineMaps:
            // These are "coming soon" features
            return nil
        }
    }

    /// Check if this overlay type is available (has valid URL)
    static func isAvailable(_ overlayType: MapOverlayType) -> Bool {
        switch overlayType {
        case .radar, .clouds, .snowfall, .snowDepth, .smoke:
            // These all use RainViewer or Iowa State (free, no API key needed)
            return true
        case .temperature, .wind:
            // These require OpenWeatherMap API key (no free alternative)
            return openWeatherMapKey != nil
        case .avalanche, .landOwnership, .offlineMaps:
            return false
        }
    }
}

// MARK: - Weather Tile Overlay Renderer

/// Renderer for weather tile overlays with configurable opacity
class WeatherTileOverlayRenderer: MKTileOverlayRenderer {
    init(tileOverlay: WeatherTileOverlay) {
        super.init(overlay: tileOverlay)

        // Set alpha based on overlay type
        switch tileOverlay.overlayType {
        case .radar:
            self.alpha = 0.7
        case .clouds:
            self.alpha = 0.6
        case .temperature:
            self.alpha = 0.65
        case .wind:
            self.alpha = 0.6
        case .snowfall, .snowDepth:
            self.alpha = 0.7
        case .smoke:
            self.alpha = 0.5
        default:
            self.alpha = 0.6
        }
    }
}

// MARK: - RainViewer Service

/// Service for fetching RainViewer radar timestamps
actor RainViewerService {
    static let shared = RainViewerService()

    private var cachedTimestamps: [Int] = []
    private var lastFetch: Date?
    private let cacheExpiration: TimeInterval = 300 // 5 minutes

    /// Fetch available radar timestamps from RainViewer
    func getRadarTimestamps() async throws -> [Int] {
        // Return cached if still valid
        if let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpiration,
           !cachedTimestamps.isEmpty {
            return cachedTimestamps
        }

        // Fetch fresh timestamps
        let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

        // Extract timestamps from radar frames
        let timestamps = response.radar.past.map { $0.time } + response.radar.nowcast.map { $0.time }

        cachedTimestamps = timestamps
        lastFetch = Date()

        return timestamps
    }

    /// Get the most recent radar timestamp
    func getMostRecentTimestamp() async throws -> Int {
        let timestamps = try await getRadarTimestamps()
        return timestamps.last ?? Int(Date().timeIntervalSince1970)
    }

    /// Get timestamps for animation (past + forecast)
    func getAnimationTimestamps() async throws -> (past: [Int], forecast: [Int]) {
        let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json")!
        let (data, _) = try await URLSession.shared.data(from: url)

        let response = try JSONDecoder().decode(RainViewerResponse.self, from: data)

        return (
            past: response.radar.past.map { $0.time },
            forecast: response.radar.nowcast.map { $0.time }
        )
    }
}

// MARK: - RainViewer Response Models

struct RainViewerResponse: Codable {
    let version: String
    let generated: Int
    let host: String
    let radar: RadarData
    let satellite: SatelliteData?

    struct RadarData: Codable {
        let past: [Frame]
        let nowcast: [Frame]
    }

    struct SatelliteData: Codable {
        let infrared: [Frame]?
    }

    struct Frame: Codable {
        let time: Int
        let path: String
    }
}

// MARK: - Overlay Manager

/// Manager for weather overlays on a map view
@MainActor
class WeatherOverlayManager: ObservableObject {
    private weak var mapView: MKMapView?
    private var currentOverlay: WeatherTileOverlay?
    private var animationTimer: Timer?
    private var animationTimestamps: [Int] = []
    private var currentAnimationIndex = 0

    @Published var isAnimating = false
    @Published var currentTimestamp: Int?

    func attach(to mapView: MKMapView) {
        self.mapView = mapView
    }

    /// Show an overlay on the map
    func showOverlay(_ overlayType: MapOverlayType, timestamp: Int? = nil) {
        guard let mapView = mapView else { return }

        // Remove existing weather overlay
        removeCurrentOverlay()

        // For radar overlays, we need a valid timestamp from RainViewer
        if overlayType == .radar || (overlayType == .snowfall && timestamp == nil) || (overlayType == .snowDepth && timestamp == nil) {
            Task {
                do {
                    let validTimestamp = try await RainViewerService.shared.getMostRecentTimestamp()
                    await MainActor.run {
                        self.addOverlayToMap(overlayType, timestamp: validTimestamp)
                    }
                } catch {
                    #if DEBUG
                    print("Failed to fetch RainViewer timestamp: \(error)")
                    #endif
                    // Try with nil timestamp as fallback
                    await MainActor.run {
                        self.addOverlayToMap(overlayType, timestamp: nil)
                    }
                }
            }
        } else {
            addOverlayToMap(overlayType, timestamp: timestamp)
        }
    }

    private func addOverlayToMap(_ overlayType: MapOverlayType, timestamp: Int?) {
        guard let mapView = mapView else { return }

        // Create and add new overlay - returns nil if unavailable
        guard let overlay = WeatherTileOverlay(overlayType: overlayType, timestamp: timestamp) else {
            #if DEBUG
            print("Overlay \(overlayType.displayName) is not available")
            #endif
            return
        }
        currentOverlay = overlay
        currentTimestamp = timestamp

        #if DEBUG
        print("Adding overlay: \(overlayType.displayName) with timestamp: \(timestamp ?? 0)")
        #endif

        // Add overlay above base map but below annotations
        mapView.addOverlay(overlay, level: .aboveRoads)
    }

    /// Remove the current weather overlay
    func removeCurrentOverlay() {
        stopAnimation()

        if let overlay = currentOverlay {
            mapView?.removeOverlay(overlay)
            currentOverlay = nil
            currentTimestamp = nil
        }
    }

    /// Start radar animation
    func startRadarAnimation() async {
        guard let mapView = mapView else { return }

        do {
            let timestamps = try await RainViewerService.shared.getAnimationTimestamps()
            animationTimestamps = timestamps.past + timestamps.forecast
            currentAnimationIndex = 0
            isAnimating = true

            // Start animation timer
            animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.advanceAnimation()
                }
            }
        } catch {
            #if DEBUG
            print("Failed to fetch radar timestamps: \(error)")
            #endif
        }
    }

    /// Stop radar animation
    func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        isAnimating = false
        animationTimestamps = []
        currentAnimationIndex = 0
    }

    private func advanceAnimation() {
        guard !animationTimestamps.isEmpty else { return }

        currentAnimationIndex = (currentAnimationIndex + 1) % animationTimestamps.count
        let timestamp = animationTimestamps[currentAnimationIndex]

        showOverlay(.radar, timestamp: timestamp)
    }

    /// Get renderer for weather overlays
    func renderer(for overlay: MKOverlay) -> MKOverlayRenderer? {
        if let weatherOverlay = overlay as? WeatherTileOverlay {
            return WeatherTileOverlayRenderer(tileOverlay: weatherOverlay)
        }
        return nil
    }
}
