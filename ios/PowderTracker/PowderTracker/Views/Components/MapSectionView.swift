import SwiftUI
import MapKit

// MARK: - Map Expansion State

enum MapExpansionState {
    case collapsed
    case expanded

    var height: CGFloat {
        switch self {
        case .collapsed: return 120
        case .expanded: return UIScreen.main.bounds.height * 0.6
        }
    }
}

// MARK: - Map Section View

/// Collapsible map section for displaying mountains with interactive markers
/// Supports collapsed preview and expanded full-size states
struct MapSectionView: View {
    let mountains: [Mountain]
    let scores: [String: Double]
    @Binding var isExpanded: Bool
    let onMountainSelected: (Mountain) -> Void

    @State private var cameraPosition: MapCameraPosition
    @State private var selectedMountainId: String?

    init(
        mountains: [Mountain],
        scores: [String: Double],
        isExpanded: Binding<Bool>,
        onMountainSelected: @escaping (Mountain) -> Void
    ) {
        self.mountains = mountains
        self.scores = scores
        self._isExpanded = isExpanded
        self.onMountainSelected = onMountainSelected

        // Initialize camera position to show all mountains
        let region = Self.calculateRegion(for: mountains)
        self._cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map
            Map(position: $cameraPosition, selection: $selectedMountainId) {
                UserAnnotation()

                ForEach(mountains) { mountain in
                    Annotation(
                        mountain.shortName,
                        coordinate: mountain.location.coordinate,
                        anchor: .bottom
                    ) {
                        MountainMarker(
                            mountain: mountain,
                            score: scores[mountain.id],
                            isSelected: selectedMountainId == mountain.id
                        )
                        .onTapGesture {
                            selectedMountainId = mountain.id
                            onMountainSelected(mountain)
                        }
                    }
                    .tag(mountain.id)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                if isExpanded {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
            }
            .disabled(!isExpanded) // Disable interactions when collapsed

            // Selected mountain detail card
            if let selectedId = selectedMountainId,
               let mountain = mountains.first(where: { $0.id == selectedId }),
               isExpanded {
                NavigationLink {
                    LocationView(mountain: mountain)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(mountain.shortName)
                                .font(.headline)
                                .fontWeight(.semibold)

                            if let score = scores[mountain.id] {
                                HStack(spacing: 4) {
                                    Text("Powder Score:")
                                        .font(.caption)
                                    Text(String(format: "%.1f", score))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                }
                            }
                        }

                        Spacer()

                        Text("View Details")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(.cornerRadiusButton)
                }
                .padding(.horizontal, .spacingL)
                .padding(.bottom, .spacingXXL * 2.5) // Above collapse button
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Overlay buttons
            if !isExpanded {
                // Collapsed: Show expand button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Expand Map")
                        Image(systemName: "chevron.up")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingM)
                    .background(Color.blue)
                    .cornerRadius(.cornerRadiusButton)
                    .shadow(color: .black.opacity(0.2), radius: 8)
                }
            } else {
                // Expanded: Show collapse button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded = false
                        selectedMountainId = nil // Clear selection on collapse
                    }
                } label: {
                    HStack {
                        Image(systemName: "chevron.down")
                        Text("Collapse Map")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingS)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(.cornerRadiusButton)
                }
                .padding(.bottom, .spacingM)
            }
        }
        .frame(height: isExpanded ? MapExpansionState.expanded.height : MapExpansionState.collapsed.height)
        .cornerRadius(.cornerRadiusCard)
        .shadow(color: .black.opacity(0.1), radius: 8)
        .onChange(of: selectedMountainId) { _, newId in
            // Animate camera to selected mountain
            if let id = newId,
               let mountain = mountains.first(where: { $0.id == id }) {
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: mountain.location.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                        )
                    )
                }
            }
        }
        .onChange(of: mountains.count) { _, _ in
            // Recalculate region when filtered mountains change
            if mountains.isEmpty {
                // Reset to Pacific Northwest default when all mountains filtered out
                withAnimation {
                    cameraPosition = .region(
                        MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
                            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
                        )
                    )
                    selectedMountainId = nil
                }
            } else {
                let region = Self.calculateRegion(for: mountains)
                withAnimation {
                    cameraPosition = .region(region)
                }
            }
        }
    }

    // MARK: - Helper Methods

    /// Calculate the map region that encompasses all mountains
    private static func calculateRegion(for mountains: [Mountain]) -> MKCoordinateRegion {
        guard !mountains.isEmpty else {
            // Default to Pacific Northwest
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
            )
        }

        if mountains.count == 1 {
            // Single mountain - zoom in
            return MKCoordinateRegion(
                center: mountains[0].location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
            )
        }

        // Multiple mountains - calculate bounding box
        let coordinates = mountains.map { $0.location.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLng = coordinates.map { $0.longitude }.min() ?? 0
        let maxLng = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2
        )

        // Add 20% padding to the span
        let latDelta = (maxLat - minLat) * 1.2
        let lngDelta = (maxLng - minLng) * 1.2

        // Ensure minimum span for better visibility
        let finalLatDelta = max(latDelta, 0.5)
        let finalLngDelta = max(lngDelta, 0.5)

        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: finalLatDelta, longitudeDelta: finalLngDelta)
        )
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var isExpanded = false

    NavigationStack {
        ScrollView {
            VStack {
                Text("Mountains Tab")
                    .font(.title)
                    .padding()

                // Mock MapSectionView would go here
                // (Preview requires actual Mountain data)

                Text("Mountains list below...")
                    .foregroundColor(.secondary)
            }
        }
    }
}
