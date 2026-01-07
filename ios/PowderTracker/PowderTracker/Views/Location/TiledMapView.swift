//
//  TiledMapView.swift
//  PowderTracker
//
//  UIKit MKMapView wrapper with support for tiled lift overlays.
//  This allows lazy loading of lift tiles instead of rendering all lifts at once.
//

import SwiftUI
import MapKit

/// SwiftUI wrapper for MKMapView with tile overlay support
struct TiledMapView: UIViewRepresentable {
    let mountain: MountainDetail
    let mountainId: String
    let showLifts: Bool
    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Configure map appearance
        mapView.mapType = .hybridFlyover
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true

        // Enable 3D terrain
        let camera = MKMapCamera(
            lookingAtCenter: mountain.location.coordinate,
            fromDistance: 8000,
            pitch: 45,
            heading: 0
        )
        mapView.camera = camera

        // Add lift tile overlay if enabled
        if showLifts {
            let liftOverlay = LiftTileOverlay(mountainId: mountainId)
            mapView.addOverlay(liftOverlay)
        }

        // Add mountain annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = mountain.location.coordinate
        annotation.title = mountain.name
        annotation.subtitle = "Base: \(mountain.elevation.base) ft • Summit: \(mountain.elevation.summit) ft"
        mapView.addAnnotation(annotation)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update region if changed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TiledMapView

        init(_ parent: TiledMapView) {
            self.parent = parent
        }

        // MARK: - Overlay Rendering

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? LiftTileOverlay {
                return LiftTileOverlayRenderer(tileOverlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: - Annotation Rendering

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }

            let identifier = "MountainAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            // Customize marker appearance
            if let markerView = annotationView as? MKMarkerAnnotationView {
                markerView.markerTintColor = .systemBlue
                markerView.glyphImage = UIImage(systemName: "mountain.2.fill")
            }

            return annotationView
        }

        // MARK: - Region Changes

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

/// SwiftUI preview wrapper
struct TiledMapView_Previews: PreviewProvider {
    static var previews: some View {
        TiledMapView(
            mountain: MountainDetail(
                id: "crystal",
                name: "Crystal Mountain",
                shortName: "Crystal",
                location: MountainLocation(lat: 46.9355, lng: -121.4745),
                elevation: MountainElevation(base: 4400, summit: 7012),
                region: "washington",
                snotel: MountainDetail.SnotelInfo(
                    stationId: "908",
                    stationName: "Wells Creek"
                ),
                noaa: MountainDetail.NOAAInfo(
                    gridOffice: "SEW",
                    gridX: 142,
                    gridY: 90
                ),
                webcams: [],
                roadWebcams: nil,
                color: "#8b5cf6",
                website: "https://www.crystalmountainresort.com",
                logo: "/logos/crystal.svg",
                status: MountainStatus(
                    isOpen: true,
                    percentOpen: 88,
                    liftsOpen: "10/11",
                    runsOpen: "50/57",
                    message: "Excellent skiing",
                    lastUpdated: nil
                ),
                passType: .ikon
            ),
            mountainId: "crystal",
            showLifts: true,
            region: .constant(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 46.9355, longitude: -121.4745),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        )
        .frame(height: 300)
    }
}
