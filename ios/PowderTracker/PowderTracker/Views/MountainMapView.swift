import SwiftUI
import MapKit

struct MountainMapView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var overlayState = MapOverlayState()
    @AppStorage("selectedMountainId") private var persistedMountainId = "baker"
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    )
    @State private var selectedMountainId: String?
    @State private var showingOverlaySheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map with overlay support
                ZStack(alignment: .bottomLeading) {
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

                    // Legend overlay (when overlay is active)
                    if let overlay = overlayState.activeOverlay {
                        MapLegendView(overlay: overlay)
                            .padding(.spacingM)
                    }
                }
                .frame(height: UIScreen.main.bounds.height * 0.40)

                // Overlay picker bar
                OverlayPickerBar(
                    overlayState: overlayState,
                    onMoreTap: { showingOverlaySheet = true }
                )

                // Time scrubber (for time-based overlays)
                if let overlay = overlayState.activeOverlay, overlay.isTimeBased {
                    MapTimeScrubber(overlayState: overlayState)
                        .padding(.horizontal, .spacingM)
                        .padding(.vertical, .spacingS)
                }

                // Mountain list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !viewModel.washingtonMountains.isEmpty {
                            Section {
                                ForEach(viewModel.washingtonMountains) { mountain in
                                    NavigationLink {
                                        MountainDetailView(mountain: mountain)
                                    } label: {
                                        MountainRow(
                                            mountain: mountain,
                                            score: viewModel.getScore(for: mountain),
                                            distance: viewModel.getDistance(to: mountain),
                                            isSelected: selectedMountainId == mountain.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        selectMountain(mountain)
                                    })
                                }
                            } header: {
                                SectionHeader(title: "Washington")
                            }
                        }

                        if !viewModel.oregonMountains.isEmpty {
                            Section {
                                ForEach(viewModel.oregonMountains) { mountain in
                                    NavigationLink {
                                        MountainDetailView(mountain: mountain)
                                    } label: {
                                        MountainRow(
                                            mountain: mountain,
                                            score: viewModel.getScore(for: mountain),
                                            distance: viewModel.getDistance(to: mountain),
                                            isSelected: selectedMountainId == mountain.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        selectMountain(mountain)
                                    })
                                }
                            } header: {
                                SectionHeader(title: "Oregon")
                            }
                        }

                        if !viewModel.idahoMountains.isEmpty {
                            Section {
                                ForEach(viewModel.idahoMountains) { mountain in
                                    NavigationLink {
                                        MountainDetailView(mountain: mountain)
                                    } label: {
                                        MountainRow(
                                            mountain: mountain,
                                            score: viewModel.getScore(for: mountain),
                                            distance: viewModel.getDistance(to: mountain),
                                            isSelected: selectedMountainId == mountain.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .simultaneousGesture(TapGesture().onEnded {
                                        selectMountain(mountain)
                                    })
                                }
                            } header: {
                                SectionHeader(title: "Idaho")
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
            .sheet(isPresented: $showingOverlaySheet) {
                OverlayPickerSheet(overlayState: overlayState)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private func selectMountain(_ mountain: Mountain) {
        selectedMountainId = mountain.id
        persistedMountainId = mountain.id
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

// MARK: - Mountain Row
// Note: MountainMarker and Triangle components are now shared
// See Views/Components/MountainMarker.swift
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
#Preview {
    MountainMapView()
}
