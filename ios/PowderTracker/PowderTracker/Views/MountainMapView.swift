import SwiftUI
import MapKit

struct MountainMapView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    )
    @State private var selectedMountainId: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map
                Map(position: $cameraPosition, selection: $selectedMountainId) {
                    // User location
                    UserAnnotation()

                    // Mountain markers
                    ForEach(viewModel.mountains) { mountain in
                        Annotation(
                            mountain.shortName,
                            coordinate: mountain.location.coordinate,
                            anchor: .bottom
                        ) {
                            MountainMarker(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                isSelected: selectedMountainId == mountain.id
                            )
                        }
                        .tag(mountain.id)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                    MapScaleView()
                }
                .frame(height: UIScreen.main.bounds.height * 0.45)

                // Mountain list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !viewModel.washingtonMountains.isEmpty {
                            Section {
                                ForEach(viewModel.washingtonMountains) { mountain in
                                    MountainRow(
                                        mountain: mountain,
                                        score: viewModel.getScore(for: mountain),
                                        distance: viewModel.getDistance(to: mountain),
                                        isSelected: selectedMountainId == mountain.id
                                    )
                                    .onTapGesture {
                                        selectMountain(mountain)
                                    }
                                }
                            } header: {
                                SectionHeader(title: "Washington")
                            }
                        }

                        if !viewModel.oregonMountains.isEmpty {
                            Section {
                                ForEach(viewModel.oregonMountains) { mountain in
                                    MountainRow(
                                        mountain: mountain,
                                        score: viewModel.getScore(for: mountain),
                                        distance: viewModel.getDistance(to: mountain),
                                        isSelected: selectedMountainId == mountain.id
                                    )
                                    .onTapGesture {
                                        selectMountain(mountain)
                                    }
                                }
                            } header: {
                                SectionHeader(title: "Oregon")
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Mountains")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadMountains()
                locationManager.requestPermission()
            }
            .onChange(of: selectedMountainId) { _, newId in
                if let id = newId, let mountain = viewModel.mountains.first(where: { $0.id == id }) {
                    viewModel.selectMountain(mountain)
                }
            }
        }
    }

    private func selectMountain(_ mountain: Mountain) {
        selectedMountainId = mountain.id
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

// MARK: - Mountain Marker
struct MountainMarker: View {
    let mountain: Mountain
    let score: Double?
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: isSelected ? .white.opacity(0.5) : .clear, radius: 8)

                Text(score != nil ? String(format: "%.0f", score!) : "?")
                    .font(.system(size: isSelected ? 16 : 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Triangle pointer
            Triangle()
                .fill(scoreColor)
                .frame(width: 12, height: 8)
        }
    }

    var scoreColor: Color {
        guard let score = score else {
            return Color(hex: mountain.color) ?? .gray
        }
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .red
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Mountain Row
struct MountainRow: View {
    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Score circle
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 44, height: 44)

                Text(score != nil ? String(format: "%.0f", score!) : "?")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text("\(mountain.elevation.summit.formatted())ft")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distance = distance {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(Int(distance)) mi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !mountain.hasSnotel {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Limited")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        )
    }

    var scoreColor: Color {
        guard let score = score else { return .gray }
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .red
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.top, 8)
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}

#Preview {
    MountainMapView()
}
