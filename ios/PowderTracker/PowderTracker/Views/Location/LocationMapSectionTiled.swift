//
//  LocationMapSectionTiled.swift
//  PowderTracker
//
//  Map section that uses tiled lift overlays instead of direct polyline rendering.
//  This version loads lift imagery as tiles, sending only visible portions.
//

import SwiftUI
import MapKit

struct LocationMapSectionTiled: View {
    let mountain: Mountain
    let mountainDetail: MountainDetail
    let liftData: LiftGeoJSON?
    @State private var region: MKCoordinateRegion
    @State private var useTiledOverlay = true

    init(mountain: Mountain, mountainDetail: MountainDetail, liftData: LiftGeoJSON?) {
        self.mountain = mountain
        self.mountainDetail = mountainDetail
        self.liftData = liftData

        // Initialize region centered on mountain
        _region = State(initialValue: MKCoordinateRegion(
            center: mountainDetail.location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.blue)
                Text("Location")
                    .font(.headline)

                Spacer()

                // Rendering mode toggle
                Button {
                    useTiledOverlay.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: useTiledOverlay ? "square.grid.3x3.fill" : "line.3.horizontal")
                            .font(.caption2)
                        Text(useTiledOverlay ? "Tiled" : "Vector")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.8))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                // Lift count badge
                if let liftCount = liftData?.properties.liftCount, liftCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "cablecar.fill")
                            .font(.caption2)
                        Text("\(liftCount) lifts")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(12)
                }
            }

            // Map View - switch between tiled and vector rendering
            if useTiledOverlay {
                // Tiled overlay mode - loads tiles separately
                TiledMapView(
                    mountain: mountainDetail,
                    mountainId: mountain.id,
                    showLifts: true,
                    region: $region
                )
                .frame(height: 280)
                .cornerRadius(12)
            } else {
                // Vector rendering mode - draws all lifts directly
                Map(position: .constant(.region(region))) {
                    // Lift lines (draw first so they appear under annotations)
                    if let lifts = liftData?.features {
                        ForEach(lifts) { lift in
                            MapPolyline(coordinates: lift.mapCoordinates)
                                .stroke(liftColor(for: lift.properties.type), lineWidth: 3)
                        }
                    }

                    // Mountain annotation
                    Annotation(
                        mountainDetail.name,
                        coordinate: mountainDetail.location.coordinate,
                        anchor: .bottom
                    ) {
                        VStack(spacing: 4) {
                            // Custom mountain marker
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .blue.opacity(0.7)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)

                                Image(systemName: "mountain.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }

                            // Mountain name tag
                            Text(mountainDetail.shortName)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .cornerRadius(8)
                        }
                    }

                    // User location
                    UserAnnotation()
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .frame(height: 280)
                .cornerRadius(12)
            }

            // Performance info
            HStack {
                Image(systemName: useTiledOverlay ? "square.grid.3x3.fill" : "line.3.horizontal")
                    .foregroundColor(.secondary)
                    .font(.caption)

                if useTiledOverlay {
                    Text("Tiled mode: Loading visible tiles only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    if let liftCount = liftData?.properties.liftCount {
                        Text("Vector mode: Rendering \(liftCount) lifts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            // Location details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Coordinates: \(formatCoordinate(mountainDetail.location.lat, mountainDetail.location.lng))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Image(systemName: "mountain.2.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Base: \(mountainDetail.elevation.base) ft • Summit: \(mountainDetail.elevation.summit) ft")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formatCoordinate(_ lat: Double, _ lng: Double) -> String {
        let latDirection = lat >= 0 ? "N" : "S"
        let lngDirection = lng >= 0 ? "E" : "W"
        return String(format: "%.4f°%@ %.4f°%@", abs(lat), latDirection, abs(lng), lngDirection)
    }

    private func liftColor(for type: String) -> Color {
        switch type {
        case "gondola", "cable_car":
            return .red
        case "chair_lift":
            return .blue
        case "drag_lift", "t-bar", "j-bar", "platter":
            return .green
        case "rope_tow":
            return .orange
        case "magic_carpet":
            return .purple
        case "mixed_lift":
            return .indigo
        default:
            return .gray
        }
    }
}
