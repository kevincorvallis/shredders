import SwiftUI
import MapKit

/// Card with button to open navigation in Apple Maps
struct NavigationCard: View {
    let mountain: Mountain
    @State private var showingDirectionsAlert = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "map.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Navigation")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Open in Apple Maps")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Quick Info
            VStack(spacing: 12) {
                NavigationInfoRow(
                    icon: "location.fill",
                    label: "Destination",
                    value: mountain.name
                )

                NavigationInfoRow(
                    icon: "point.topleft.down.to.point.bottomright.curvepath.fill",
                    label: "Coordinates",
                    value: String(format: "%.4f°, %.4f°", mountain.location.lat, mountain.location.lng)
                )
            }
            
            // Navigate Button
            Button(action: openInMaps) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.title3)
                    
                    Text("Start Navigation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color(.label).opacity(0.08), radius: 8, x: 0, y: 4)
        .alert("Opening Maps", isPresented: $showingDirectionsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Opening Apple Maps with directions to \(mountain.name)")
        }
    }
    
    // MARK: - Open in Maps
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(
            latitude: mountain.location.lat,
            longitude: mountain.location.lng
        )
        
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = mountain.name
        
        // Open with driving directions
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }
}

// MARK: - Navigation Info Row Component

struct NavigationInfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        NavigationCard(mountain: Mountain(
            id: "baker",
            name: "Mt. Baker",
            shortName: "Baker",
            location: MountainLocation(lat: 48.8587, lng: -121.6714),
            elevation: MountainElevation(base: 3500, summit: 5089),
            region: "WA",
            color: "#4A90E2",
            website: "https://www.mtbaker.us",
            hasSnotel: true,
            webcamCount: 3,
            logo: "/logos/baker.svg",
            status: nil,
            passType: .independent
        ))
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
