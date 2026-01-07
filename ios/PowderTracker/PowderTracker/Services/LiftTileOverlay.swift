//
//  LiftTileOverlay.swift
//  PowderTracker
//
//  Custom MKTileOverlay for displaying ski lift data as tiled images.
//  Fetches tiles from the API endpoint at /api/tiles/{mountainId}/{z}/{x}/{y}.png
//

import MapKit
import UIKit

/// Tile overlay that displays ski lifts as rendered image tiles
class LiftTileOverlay: MKTileOverlay {
    private let mountainId: String
    private let baseURL: String

    /// Initialize with mountain ID
    /// - Parameter mountainId: The mountain identifier (e.g., "crystal", "baker")
    init(mountainId: String, baseURL: String = AppConfig.apiBaseURL) {
        self.mountainId = mountainId
        self.baseURL = baseURL

        // Initialize with template URL
        // MKTileOverlay will replace {x}, {y}, {z} with actual coordinates
        let urlTemplate = "\(baseURL)/tiles/\(mountainId)/{z}/{x}/{y}.png"
        super.init(urlTemplate: urlTemplate)

        // Configure overlay properties
        self.canReplaceMapContent = false  // Overlay only, don't replace base map
        self.minimumZ = 10                 // Minimum zoom level
        self.maximumZ = 16                 // Maximum zoom level
    }

    /// Load a tile at the specified path
    /// - Parameters:
    ///   - path: The tile path (x, y, z coordinates)
    ///   - result: Completion handler with tile data or error
    override func loadTile(at path: MKTileOverlayPath, result: @escaping @Sendable (Data?, Error?) -> Void) {
        // Construct URL for this specific tile
        let urlString = "\(baseURL)/tiles/\(mountainId)/\(path.z)/\(path.x)/\(path.y).png"

        guard let url = URL(string: urlString) else {
            result(nil, NSError(domain: "LiftTileOverlay", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid tile URL"
            ]))
            return
        }

        // Fetch tile data
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Failed to load tile \(path.z)/\(path.x)/\(path.y): \(error.localizedDescription)")
                result(nil, error)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200,
                  let data = data else {
                print("Invalid response for tile \(path.z)/\(path.x)/\(path.y)")
                result(nil, NSError(domain: "LiftTileOverlay", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid tile response"
                ]))
                return
            }

            // Return tile data
            result(data, nil)
        }

        task.resume()
    }
}

/// Renderer for the lift tile overlay
class LiftTileOverlayRenderer: MKTileOverlayRenderer {
    override init(tileOverlay: MKTileOverlay) {
        super.init(overlay: tileOverlay)

        // Set alpha for partial transparency if desired
        self.alpha = 0.85
    }
}
