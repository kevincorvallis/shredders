import SwiftUI
import MapKit

struct MountainMapView: View {
    @State private var viewModel = MountainSelectionViewModel()
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var favoritesManager = FavoritesService.shared

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    )
    @State private var selectedMountain: Mountain?
    @State private var showFavoritesOnly = false
    @State private var hasSetInitialPosition = false

    // Search state
    @State private var isSearchExpanded = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var displayedMountains: [Mountain] {
        if showFavoritesOnly {
            return viewModel.mountains.filter { favoritesManager.isFavorite($0.id) }
        }
        return viewModel.mountains
    }

    private var searchResults: [Mountain] {
        guard !searchText.isEmpty else { return [] }
        let query = searchText
        return viewModel.mountains.filter { mountain in
            mountain.name.localizedCaseInsensitiveContains(query) ||
            mountain.shortName.localizedCaseInsensitiveContains(query) ||
            mountain.region.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topLeading) {
                Map(position: $cameraPosition) {
                    UserAnnotation()

                    ForEach(displayedMountains) { mountain in
                        Annotation(
                            mountain.shortName,
                            coordinate: mountain.location.coordinate,
                            anchor: .bottom
                        ) {
                            MountainMapPin(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                isSelected: selectedMountain?.id == mountain.id
                            )
                            .onTapGesture {
                                withAnimation(.snappy) {
                                    selectedMountain = mountain
                                    cameraPosition = .region(
                                        MKCoordinateRegion(
                                            center: mountain.location.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                                        )
                                    )
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls { MapCompass() }
                .onTapGesture {
                    selectedMountain = nil
                    dismissSearch()
                }

                // Search overlay (top-leading)
                searchOverlay
                    .padding(.spacingM)
                    .padding(.top, 4)

                // Floating controls (top-trailing)
                VStack(spacing: .spacingS) {
                    Button {
                        if let loc = locationManager.location {
                            withAnimation {
                                cameraPosition = .region(
                                    MKCoordinateRegion(
                                        center: loc.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                                    )
                                )
                            }
                        } else {
                            locationManager.requestPermission()
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }

                    Button {
                        showFavoritesOnly.toggle()
                    } label: {
                        Image(systemName: showFavoritesOnly ? "star.fill" : "star")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(showFavoritesOnly ? .yellow : .primary)
                            .frame(width: 40, height: 40)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.spacingM)
                .padding(.top, 4)

                // Bottom card
                if let mountain = selectedMountain {
                    VStack {
                        Spacer()
                        NavigationLink {
                            MountainDetailView(mountain: mountain)
                        } label: {
                            MountainMapCard(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                conditions: viewModel.getConditions(for: mountain),
                                distance: viewModel.getDistance(to: mountain)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, .spacingM)
                        .padding(.bottom, .spacingM)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadMountains()
                locationManager.requestPermission()
                setInitialPosition()
            }
            .onChange(of: locationManager.location) { _, newLocation in
                guard !hasSetInitialPosition, newLocation != nil else { return }
                setInitialPosition()
            }
            .onChange(of: viewModel.mountains) { _, _ in
                if !hasSetInitialPosition {
                    setInitialPosition()
                }
            }
        }
    }

    // MARK: - Smart Initial Position

    private func setInitialPosition() {
        guard !hasSetInitialPosition else { return }

        // Option 1: User location available
        if let loc = locationManager.location {
            hasSetInitialPosition = true
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
                    )
                )
            }
            return
        }

        // Option 2: Zoom to first favorite mountain
        guard !viewModel.mountains.isEmpty else { return }
        let targetId = favoritesManager.favoriteIds.first ?? "baker"
        if let mountain = viewModel.mountains.first(where: { $0.id == targetId }) {
            hasSetInitialPosition = true
            withAnimation {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: mountain.location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 1.5, longitudeDelta: 1.5)
                    )
                )
            }
        }
    }

    // MARK: - Search

    @ViewBuilder
    private var searchOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isSearchExpanded {
                // Expanded search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search mountains...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .submitLabel(.search)
                    Button {
                        dismissSearch()
                    } label: {
                        Text("Cancel")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))

                // Search results
                if !searchResults.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchResults.prefix(6)) { mountain in
                                Button {
                                    selectFromSearch(mountain)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "mountain.2.fill")
                                            .foregroundStyle(.secondary)
                                            .frame(width: 20)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(mountain.name)
                                                .font(.subheadline.weight(.medium))
                                                .foregroundStyle(.primary)
                                            Text(mountain.region)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if let score = viewModel.getScore(for: mountain) {
                                            Text(String(format: "%.0f", score))
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                                .frame(width: 28, height: 28)
                                                .background(scoreColor(score), in: Circle())
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                if mountain.id != searchResults.prefix(6).last?.id {
                                    Divider().padding(.leading, 42)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 240)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .padding(.top, 4)
                }
            } else {
                // Collapsed: magnifying glass button
                Button {
                    withAnimation(.snappy) {
                        isSearchExpanded = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isSearchFocused = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }
        }
    }

    private func selectFromSearch(_ mountain: Mountain) {
        dismissSearch()
        withAnimation(.snappy) {
            selectedMountain = mountain
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: mountain.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            )
        }
    }

    private func dismissSearch() {
        withAnimation(.snappy) {
            isSearchExpanded = false
            searchText = ""
            isSearchFocused = false
        }
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .red
    }
}

// MARK: - Map Pin

private struct MountainMapPin: View {
    let mountain: Mountain
    let score: Double?
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            MountainMarker(mountain: mountain, score: score, isSelected: isSelected)
        }
        .scaleEffect(isSelected ? 1.15 : 1.0)
        .animation(.snappy, value: isSelected)
    }
}

// MARK: - Bottom Card

private struct MountainMapCard: View {
    let mountain: Mountain
    let score: Double?
    let conditions: MountainConditions?
    let distance: Double?

    var body: some View {
        HStack(spacing: .spacingM) {
            // Score circle
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 48, height: 48)
                Text(score != nil ? String(format: "%.0f", score!) : "?")
                    .font(.title3.bold())
                    .foregroundColor(.white)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mountain.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    // Open/Closed badge
                    if let status = mountain.status {
                        Text(status.isOpen ? "Open" : "Closed")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(status.isOpen ? Color.green : Color.red, in: Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Row 1: Snowfall stats
                HStack(spacing: 8) {
                    if let c = conditions {
                        if c.snowfall24h > 0 {
                            Label("\(c.snowfall24h)\" 24h", systemImage: "snowflake")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        if c.snowfall48h > 0 {
                            Label("\(c.snowfall48h)\" 48h", systemImage: "snowflake")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        if c.snowfall7d > 0 {
                            Label("\(c.snowfall7d)\" 7d", systemImage: "snowflake.circle")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Row 2: Temp, wind, depth, lifts, distance
                HStack(spacing: 8) {
                    if let temp = conditions?.temperature {
                        Label("\(temp)\u{00B0}F", systemImage: "thermometer.medium")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let wind = conditions?.wind {
                        Label("\(wind.speed) mph \(wind.direction)", systemImage: "wind")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let depth = conditions?.snowDepth, depth > 0 {
                        Label("\(depth)\" base", systemImage: "ruler")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let ls = conditions?.liftStatus {
                        Label("\(ls.liftsOpen)/\(ls.liftsTotal) lifts", systemImage: "cablecar.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let distance {
                        Label("\(Int(distance)) mi", systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.spacingM)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: .cornerRadiusCard))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var scoreColor: Color {
        guard let score else { return .gray }
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .red
    }
}

#Preview {
    MountainMapView()
}
