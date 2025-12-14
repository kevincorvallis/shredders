import Foundation
import CoreLocation
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: Error?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000 // Update only when moved 1km
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        locationManager.requestLocation()
    }

    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // Calculate distances for a list of mountains
    func sortMountainsByDistance(_ mountains: [Mountain]) -> [Mountain] {
        guard let userLocation = location else {
            return mountains
        }

        return mountains.sorted { m1, m2 in
            let d1 = m1.distanceFrom(userLocation)
            let d2 = m2.distanceFrom(userLocation)
            return d1 < d2
        }
    }

    // Get distance to a specific mountain
    func distanceTo(_ mountain: Mountain) -> Double? {
        guard let userLocation = location else { return nil }
        return mountain.distanceFrom(userLocation)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            location = locations.last
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
            print("Location error: \(error.localizedDescription)")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.requestLocation()
            case .denied, .restricted:
                print("Location access denied")
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
}
