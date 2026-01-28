import SwiftUI
import MapKit

struct LocationMapSection: View {
    let mountain: Mountain
    let mountainDetail: MountainDetail
    let liftData: LiftGeoJSON?
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.blue)
                Text("Location")
                    .font(.headline)

                Spacer()

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
                    .cornerRadius(.cornerRadiusCard)
                }
            }

            // Map View
            Map(position: $cameraPosition) {
                // Lift lines (draw first so they appear under annotations)
                if let lifts = liftData?.features {
                    ForEach(lifts) { lift in
                        MapPolyline(coordinates: lift.mapCoordinates)
                            .stroke(liftColor(for: lift.properties.type), lineWidth: 3)
                    }
                }

                // Lift name labels
                if let lifts = liftData?.features {
                    ForEach(lifts) { lift in
                        if let midpoint = lift.midpointCoordinate {
                            Annotation(
                                lift.properties.name,
                                coordinate: midpoint,
                                anchor: .center
                            ) {
                                Text(lift.properties.name)
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(liftColor(for: lift.properties.type).opacity(0.9))
                                            .shadow(color: Color(.label).opacity(0.3), radius: 2, x: 0, y: 1)
                                    )
                            }
                        }
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
                            .cornerRadius(.cornerRadiusButton)
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
            .cornerRadius(.cornerRadiusCard)
            .onAppear {
                // Center map on mountain with tight zoom to show terrain detail
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: mountainDetail.location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
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
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: Color(.label).opacity(0.05), radius: 8, x: 0, y: 2)
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
