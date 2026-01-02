import SwiftUI
import MapKit

struct LocationMapSection: View {
    let mountain: Mountain
    let mountainDetail: MountainDetail
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
            }

            // Map View
            Map(position: $cameraPosition) {

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
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func formatCoordinate(_ lat: Double, _ lng: Double) -> String {
        let latDirection = lat >= 0 ? "N" : "S"
        let lngDirection = lng >= 0 ? "E" : "W"
        return String(format: "%.4f°%@ %.4f°%@", abs(lat), latDirection, abs(lng), lngDirection)
    }
}
