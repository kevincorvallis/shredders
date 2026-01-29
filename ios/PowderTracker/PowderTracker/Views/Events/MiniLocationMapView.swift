//
//  MiniLocationMapView.swift
//  PowderTracker
//
//  A small, non-interactive map preview for selected locations
//

import SwiftUI
import MapKit

struct MiniLocationMapView: View {
    let coordinate: CLLocationCoordinate2D
    let title: String

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            Marker(title, coordinate: coordinate)
                .tint(.red)
        }
        .mapStyle(.standard(elevation: .flat))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
        .onAppear {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
        .onChange(of: coordinate.latitude) { _, _ in
            updateCamera()
        }
        .onChange(of: coordinate.longitude) { _, _ in
            updateCamera()
        }
    }

    private func updateCamera() {
        withAnimation(.smooth) {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }
}

#Preview {
    VStack {
        MiniLocationMapView(
            coordinate: CLLocationCoordinate2D(latitude: 47.6062, longitude: -122.3321),
            title: "Seattle"
        )
        .frame(height: 150)
        .padding()
    }
}
