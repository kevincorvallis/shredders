import Foundation
import CoreLocation

struct MountainLocation: Codable {
    let lat: Double
    let lng: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
}

struct MountainElevation: Codable {
    let base: Int
    let summit: Int

    var verticalDrop: Int {
        summit - base
    }
}

struct Mountain: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let location: MountainLocation
    let elevation: MountainElevation
    let region: String
    let color: String
    let website: String
    let hasSnotel: Bool
    let webcamCount: Int

    // Computed property for distance from user
    var distance: Double?

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Mountain, rhs: Mountain) -> Bool {
        lhs.id == rhs.id
    }

    // Helper to calculate distance from a location
    func distanceFrom(_ location: CLLocation) -> Double {
        let mountainLocation = CLLocation(latitude: self.location.lat, longitude: self.location.lng)
        return mountainLocation.distance(from: location) / 1609.34 // Convert meters to miles
    }
}

struct MountainsResponse: Codable {
    let mountains: [Mountain]
}

// MARK: - Mountain Detail (full response from /api/mountains/[id])
struct MountainDetail: Codable {
    let id: String
    let name: String
    let shortName: String
    let location: MountainLocation
    let elevation: MountainElevation
    let region: String
    let snotel: SnotelInfo?
    let noaa: NOAAInfo
    let webcams: [Webcam]
    let color: String
    let website: String

    struct SnotelInfo: Codable {
        let stationId: String
        let stationName: String
    }

    struct NOAAInfo: Codable {
        let gridOffice: String
        let gridX: Int
        let gridY: Int
    }

    struct Webcam: Codable, Identifiable {
        let id: String
        let name: String
        let url: String
        let refreshUrl: String?
    }
}

// MARK: - Mock Data
extension Mountain {
    static let mock = Mountain(
        id: "baker",
        name: "Mt. Baker",
        shortName: "Baker",
        location: MountainLocation(lat: 48.857, lng: -121.669),
        elevation: MountainElevation(base: 3500, summit: 5089),
        region: "washington",
        color: "#3b82f6",
        website: "https://www.mtbaker.us",
        hasSnotel: true,
        webcamCount: 3
    )

    static let mockMountains: [Mountain] = [
        .mock,
        Mountain(
            id: "stevens",
            name: "Stevens Pass",
            shortName: "Stevens",
            location: MountainLocation(lat: 47.745, lng: -121.089),
            elevation: MountainElevation(base: 4061, summit: 5845),
            region: "washington",
            color: "#10b981",
            website: "https://www.stevenspass.com",
            hasSnotel: true,
            webcamCount: 1
        ),
        Mountain(
            id: "crystal",
            name: "Crystal Mountain",
            shortName: "Crystal",
            location: MountainLocation(lat: 46.935, lng: -121.474),
            elevation: MountainElevation(base: 4400, summit: 7012),
            region: "washington",
            color: "#8b5cf6",
            website: "https://www.crystalmountainresort.com",
            hasSnotel: true,
            webcamCount: 1
        ),
    ]
}
