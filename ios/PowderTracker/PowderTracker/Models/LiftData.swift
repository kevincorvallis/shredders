import Foundation
import CoreLocation

// MARK: - Lift GeoJSON Models

struct LiftGeoJSON: Codable {
    let type: String
    let properties: LiftCollectionProperties
    let features: [LiftFeature]
}

struct LiftCollectionProperties: Codable {
    let mountainId: String
    let mountainName: String
    let liftCount: Int

    enum CodingKeys: String, CodingKey {
        case mountainId = "mountain_id"
        case mountainName = "mountain_name"
        case liftCount = "lift_count"
    }
}

struct LiftFeature: Codable, Identifiable {
    var id: String { properties.id }
    let type: String
    let geometry: LiftGeometry
    let properties: LiftFeatureProperties
}

struct LiftGeometry: Codable {
    let type: String  // "LineString"
    let coordinates: [[Double]]  // [[lng, lat], [lng, lat], ...]
}

struct LiftFeatureProperties: Codable {
    let id: String
    let type: String
    let name: String
    let occupancy: String?
    let capacity: String?
    let duration: String?
    let heating: String?
    let bubble: String?
}

// MARK: - Extensions

extension LiftFeature {
    /// Convert GeoJSON coordinates to CLLocationCoordinate2D array
    /// Note: GeoJSON uses [longitude, latitude] format
    var mapCoordinates: [CLLocationCoordinate2D] {
        geometry.coordinates.compactMap { coord in
            guard coord.count >= 2 else { return nil }
            return CLLocationCoordinate2D(
                latitude: coord[1],   // latitude is second
                longitude: coord[0]   // longitude is first
            )
        }
    }

    /// Human-readable lift type
    var displayType: String {
        switch properties.type {
        case "chair_lift":
            if let occupancy = properties.occupancy {
                return "\(occupancy)-Person Chair"
            }
            return "Chairlift"
        case "gondola":
            return "Gondola"
        case "cable_car":
            return "Cable Car"
        case "drag_lift":
            return "Drag Lift"
        case "t-bar":
            return "T-Bar"
        case "j-bar":
            return "J-Bar"
        case "platter":
            return "Platter Lift"
        case "rope_tow":
            return "Rope Tow"
        case "magic_carpet":
            return "Magic Carpet"
        case "mixed_lift":
            return "Mixed Lift"
        default:
            return properties.type.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    /// Icon name for lift type
    var iconName: String {
        switch properties.type {
        case "chair_lift":
            return "cablecar.fill"
        case "gondola", "cable_car":
            return "point.3.filled.connected.trianglepath.dotted"
        case "drag_lift", "t-bar", "j-bar", "platter", "rope_tow":
            return "figure.skiing.downhill"
        case "magic_carpet":
            return "arrow.up.square.fill"
        default:
            return "tram.fill"
        }
    }
}
