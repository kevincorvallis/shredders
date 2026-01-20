//
//  WeatherMapView.swift
//  PowderTracker
//
//  UIKit MKMapView wrapper with weather overlay support.
//  SwiftUI's Map doesn't support tile overlays, so we use UIViewRepresentable.
//

import SwiftUI
import MapKit

/// SwiftUI wrapper for MKMapView with weather overlay support
struct WeatherMapView: UIViewRepresentable {
    @ObservedObject var overlayState: MapOverlayState
    let mountains: [Mountain]
    let selectedMountainId: String?
    let onMountainSelected: (Mountain) -> Void

    @Binding var region: MKCoordinateRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator

        // Configure map appearance
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true

        // Set initial region
        mapView.setRegion(region, animated: false)

        // Attach overlay manager
        context.coordinator.overlayManager.attach(to: mapView)

        // Add mountain annotations
        updateAnnotations(mapView, context: context)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update annotations if mountains changed
        updateAnnotations(mapView, context: context)

        // Handle overlay state changes
        let coordinator = context.coordinator
        let currentOverlay = overlayState.activeOverlay
        let currentTimeOffset = overlayState.selectedTimeOffset

        // Check if overlay changed
        if currentOverlay != coordinator.lastOverlayType ||
           currentTimeOffset != coordinator.lastTimeOffset {

            coordinator.lastOverlayType = currentOverlay
            coordinator.lastTimeOffset = currentTimeOffset

            if let overlayType = currentOverlay {
                // Calculate timestamp for time-based overlays
                var timestamp: Int? = nil
                if overlayType.isTimeBased {
                    timestamp = Int(Date().timeIntervalSince1970 + currentTimeOffset)
                }
                coordinator.overlayManager.showOverlay(overlayType, timestamp: timestamp)
            } else {
                coordinator.overlayManager.removeCurrentOverlay()
            }
        }
    }

    private func updateAnnotations(_ mapView: MKMapView, context: Context) {
        // Remove existing mountain annotations (keep user location)
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existingAnnotations)

        // Add mountain annotations
        for mountain in mountains {
            let annotation = MountainAnnotation(mountain: mountain)
            annotation.coordinate = mountain.location.coordinate
            annotation.title = mountain.name
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: WeatherMapView
        let overlayManager = WeatherOverlayManager()

        // Track state to detect changes
        var lastOverlayType: MapOverlayType?
        var lastTimeOffset: TimeInterval = 0

        init(_ parent: WeatherMapView) {
            self.parent = parent
        }

        // MARK: - Overlay Rendering

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            // Check for weather overlay (tiles)
            if let weatherOverlay = overlay as? WeatherTileOverlay {
                return WeatherTileOverlayRenderer(tileOverlay: weatherOverlay)
            }

            // Check for avalanche polygon overlay
            if let avalanchePolygon = overlay as? AvalanchePolygon {
                let renderer = MKPolygonRenderer(polygon: avalanchePolygon)
                renderer.fillColor = avalanchePolygon.fillColor.withAlphaComponent(0.4)
                renderer.strokeColor = avalanchePolygon.strokeColor
                renderer.lineWidth = 1.5
                return renderer
            }

            // Check for lift overlay
            if let liftOverlay = overlay as? LiftTileOverlay {
                return LiftTileOverlayRenderer(tileOverlay: liftOverlay)
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        // MARK: - Annotation Rendering

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Don't customize user location
            if annotation is MKUserLocation {
                return nil
            }

            // Mountain annotation
            if let mountainAnnotation = annotation as? MountainAnnotation {
                let identifier = "MountainMarker"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if annotationView == nil {
                    annotationView = MKMarkerAnnotationView(annotation: mountainAnnotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true

                    // Add detail button
                    let button = UIButton(type: .detailDisclosure)
                    annotationView?.rightCalloutAccessoryView = button
                } else {
                    annotationView?.annotation = mountainAnnotation
                }

                // Customize marker
                let isSelected = parent.selectedMountainId == mountainAnnotation.mountain.id
                annotationView?.markerTintColor = isSelected ? .systemBlue : .systemPurple
                annotationView?.glyphImage = UIImage(systemName: "mountain.2.fill")
                annotationView?.displayPriority = isSelected ? .required : .defaultHigh

                return annotationView
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            if let mountainAnnotation = view.annotation as? MountainAnnotation {
                parent.onMountainSelected(mountainAnnotation.mountain)
            }
        }

        func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
            if let mountainAnnotation = annotation as? MountainAnnotation {
                parent.onMountainSelected(mountainAnnotation.mountain)
            }
        }

        // MARK: - Region Changes

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
            }
        }
    }
}

// MARK: - Mountain Annotation

class MountainAnnotation: NSObject, MKAnnotation {
    let mountain: Mountain
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?

    init(mountain: Mountain) {
        self.mountain = mountain
        self.coordinate = mountain.location.coordinate
        self.title = mountain.name
        self.subtitle = "\(mountain.elevation.summit.formatted()) ft"
        super.init()
    }
}

// MARK: - Preview

#Preview {
    WeatherMapView(
        overlayState: MapOverlayState(),
        mountains: [],
        selectedMountainId: nil,
        onMountainSelected: { _ in },
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        ))
    )
}
