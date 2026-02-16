import SwiftUI
import MapKit

struct MountainMapView: View {
    var viewModel: MountainSelectionViewModel
    @ObservedObject private var locationManager = LocationManager.shared

    init(viewModel: MountainSelectionViewModel = MountainSelectionViewModel()) {
        self.viewModel = viewModel
    }
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
    @State private var isSearchActive = false
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
            ZStack {
                // Full-bleed map
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
                                    isSearchActive = false
                                    isSearchFocused = false
                                    searchText = ""
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

                // Tap-to-dismiss overlay when search is active
                if isSearchActive {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dismissSearch()
                        }
                }

                // Floating controls (top-trailing)
                VStack(spacing: 10) {
                    FloatingMapButton(
                        icon: "location.fill",
                        isActive: false
                    ) {
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
                    }

                    FloatingMapButton(
                        icon: showFavoritesOnly ? "star.fill" : "star",
                        isActive: showFavoritesOnly,
                        activeColor: .yellow
                    ) {
                        withAnimation(.snappy) {
                            showFavoritesOnly.toggle()
                        }
                        HapticFeedback.selection.trigger()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.trailing, 16)
                .padding(.top, 12)

                // Bottom panel: search bar + selected card
                VStack(spacing: 0) {
                    Spacer()
                    bottomPanel
                }
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                if viewModel.mountains.isEmpty {
                    await viewModel.loadMountains()
                }
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

    // MARK: - Bottom Panel

    @ViewBuilder
    private var bottomPanel: some View {
        VStack(spacing: 0) {
            // Search results (slide up above search bar)
            if isSearchActive && !searchResults.isEmpty {
                searchResultsList
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Selected mountain card
            if let mountain = selectedMountain, !isSearchActive {
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
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Search bar (always visible at bottom, above Apple Maps logo)
            searchBar
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)

            if isSearchActive {
                TextField("Search mountains...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        if let first = searchResults.first {
                            selectFromSearch(first)
                        }
                    }
            } else {
                Text("Search mountains...")
                    .font(.body)
                    .foregroundStyle(.tertiary)

                Spacer()
            }

            if isSearchActive {
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }

                Button {
                    dismissSearch()
                } label: {
                    Text("Cancel")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: Capsule())
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .contentShape(Capsule())
        .onTapGesture {
            if !isSearchActive {
                withAnimation(.snappy) {
                    isSearchActive = true
                    selectedMountain = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(searchResults.prefix(5).enumerated()), id: \.element.id) { index, mountain in
                Button {
                    selectFromSearch(mountain)
                } label: {
                    HStack(spacing: 12) {
                        MountainLogoView(
                            logoUrl: mountain.logo,
                            color: mountain.color,
                            size: 36
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(mountain.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(mountain.region.capitalized)
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }

                if index < min(searchResults.count, 5) - 1 {
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Smart Initial Position

    private func setInitialPosition() {
        guard !hasSetInitialPosition else { return }

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

    // MARK: - Actions

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
            isSearchActive = false
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

// MARK: - Floating Map Button

private struct FloatingMapButton: View {
    let icon: String
    var isActive: Bool = false
    var activeColor: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? activeColor : .primary)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
                .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        }
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
        HStack(spacing: 14) {
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
                        .foregroundStyle(.tertiary)
                }

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
                    }
                    if let ls = conditions?.liftStatus {
                        Label("\(ls.liftsOpen)/\(ls.liftsTotal)", systemImage: "cablecar.fill")
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
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
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
