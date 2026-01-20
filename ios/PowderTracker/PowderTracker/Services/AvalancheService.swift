//
//  AvalancheService.swift
//  PowderTracker
//
//  Service for fetching avalanche forecast data from avalanche.org API.
//

import Foundation
import MapKit
import UIKit

// MARK: - Avalanche API Response Models

struct AvalancheMapLayerResponse: Codable {
    let type: String
    let features: [AvalancheFeature]
}

struct AvalancheFeature: Codable, Identifiable {
    let type: String
    let id: Int
    let properties: AvalancheProperties
    let geometry: AvalancheGeometry
}

struct AvalancheProperties: Codable {
    let name: String
    let center: String
    let centerLink: String
    let timezone: String
    let centerId: String
    let state: String
    let offSeason: Bool
    let travelAdvice: String?
    let danger: String
    let dangerLevel: Int
    let color: String
    let stroke: String
    let fontColor: String
    let link: String
    let startDate: String?
    let endDate: String?
    let fillOpacity: Double
    let fillIncrement: Double
    let warning: AvalancheWarning?

    enum CodingKeys: String, CodingKey {
        case name, center, timezone, state, danger, color, stroke, link, warning
        case centerLink = "center_link"
        case centerId = "center_id"
        case offSeason = "off_season"
        case travelAdvice = "travel_advice"
        case dangerLevel = "danger_level"
        case fontColor = "font_color"
        case startDate = "start_date"
        case endDate = "end_date"
        case fillOpacity, fillIncrement
    }
}

struct AvalancheWarning: Codable {
    let product: String?
}

struct AvalancheGeometry: Codable {
    let type: String
    let coordinates: [[[AvalancheCoordinate]]]
}

// Custom coordinate type to handle the array format [longitude, latitude]
struct AvalancheCoordinate: Codable {
    let longitude: Double
    let latitude: Double

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        longitude = try container.decode(Double.self)
        latitude = try container.decode(Double.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Avalanche Danger Level

enum AvalancheDangerLevel: Int {
    case noRating = -1
    case noAvalancheInfo = 0
    case low = 1
    case moderate = 2
    case considerable = 3
    case high = 4
    case extreme = 5

    var displayName: String {
        switch self {
        case .noRating, .noAvalancheInfo: return "No Rating"
        case .low: return "Low"
        case .moderate: return "Moderate"
        case .considerable: return "Considerable"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }

    var color: UIColor {
        switch self {
        case .noRating, .noAvalancheInfo: return UIColor.systemGray
        case .low: return UIColor.systemGreen
        case .moderate: return UIColor.systemYellow
        case .considerable: return UIColor.systemOrange
        case .high: return UIColor.systemRed
        case .extreme: return UIColor.black
        }
    }
}

// MARK: - Avalanche Service

actor AvalancheService {
    static let shared = AvalancheService()

    private let baseURL = "https://api.avalanche.org"
    private var cachedData: AvalancheMapLayerResponse?
    private var lastFetch: Date?
    private let cacheExpiration: TimeInterval = 1800 // 30 minutes

    /// Fetch all avalanche zones with current forecasts
    func getAvalancheZones() async throws -> AvalancheMapLayerResponse {
        // Return cached if still valid
        if let cachedData = cachedData,
           let lastFetch = lastFetch,
           Date().timeIntervalSince(lastFetch) < cacheExpiration {
            return cachedData
        }

        let url = URL(string: "\(baseURL)/v2/public/products/map-layer")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AvalancheServiceError.requestFailed
        }

        let decoder = JSONDecoder()
        let mapLayer = try decoder.decode(AvalancheMapLayerResponse.self, from: data)

        cachedData = mapLayer
        lastFetch = Date()

        return mapLayer
    }

    /// Get avalanche zones for a specific state (e.g., "WA", "OR", "CO")
    func getAvalancheZones(forState state: String) async throws -> [AvalancheFeature] {
        let allZones = try await getAvalancheZones()
        return allZones.features.filter { $0.properties.state == state }
    }

    /// Get avalanche zones near a coordinate
    func getAvalancheZones(near coordinate: CLLocationCoordinate2D, radiusMiles: Double = 100) async throws -> [AvalancheFeature] {
        let allZones = try await getAvalancheZones()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let radiusMeters = radiusMiles * 1609.34

        return allZones.features.filter { feature in
            // Check if any point of the polygon is within radius
            for polygon in feature.geometry.coordinates {
                for ring in polygon {
                    for coord in ring {
                        let zoneLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                        if location.distance(from: zoneLocation) <= radiusMeters {
                            return true
                        }
                    }
                }
            }
            return false
        }
    }

    /// Clear cached data
    func clearCache() {
        cachedData = nil
        lastFetch = nil
    }
}

// MARK: - Errors

enum AvalancheServiceError: Error, LocalizedError {
    case requestFailed
    case invalidResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "Failed to fetch avalanche data"
        case .invalidResponse: return "Invalid response from server"
        case .decodingFailed: return "Failed to decode avalanche data"
        }
    }
}

// MARK: - MKPolygon Extension for Avalanche

class AvalanchePolygon: MKPolygon {
    var feature: AvalancheFeature?
    var dangerLevel: AvalancheDangerLevel = .noRating
    var fillColor: UIColor = .systemGray
    var strokeColor: UIColor = .blue
}

extension AvalancheFeature {
    /// Convert to MKPolygon overlays for MapKit
    func toPolygons() -> [AvalanchePolygon] {
        var polygons: [AvalanchePolygon] = []

        for multiPolygon in geometry.coordinates {
            for ring in multiPolygon {
                let coordinates = ring.map { $0.coordinate }
                guard coordinates.count > 2 else { continue }

                let polygon = AvalanchePolygon(coordinates: coordinates, count: coordinates.count)
                polygon.feature = self
                polygon.dangerLevel = AvalancheDangerLevel(rawValue: properties.dangerLevel) ?? .noRating
                polygon.fillColor = UIColor(hex: properties.color) ?? .systemGray
                polygon.strokeColor = UIColor(hex: properties.stroke) ?? .blue
                polygon.title = properties.name
                polygon.subtitle = properties.danger

                polygons.append(polygon)
            }
        }

        return polygons
    }
}

// MARK: - UIColor Hex Extension

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
