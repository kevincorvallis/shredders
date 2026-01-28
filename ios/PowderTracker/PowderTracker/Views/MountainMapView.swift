import SwiftUI
import MapKit

struct MountainMapView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @StateObject private var overlayState = MapOverlayState()
    @AppStorage("selectedMountainId") private var persistedMountainId = "baker"
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
        span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
    )
    @State private var selectedMountainId: String?
    @State private var showingOverlaySheet = false
    @State private var navigateToMountain: Mountain?

    // Filter state (matching MountainsView)
    @State private var searchText = ""
    @State private var sortBy: SortOption = .distance
    @State private var filterPass: PassFilter = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Map with weather overlay support
                ZStack(alignment: .bottomLeading) {
                    WeatherMapView(
                        overlayState: overlayState,
                        mountains: viewModel.mountains,
                        selectedMountainId: selectedMountainId,
                        onMountainSelected: { mountain in
                            selectMountain(mountain)
                        },
                        region: $mapRegion
                    )
                    // Note: Don't use .id() here - it destroys and recreates the map view.
                    // UIViewRepresentable already calls updateUIView when @ObservedObject changes.

                    // Legend overlay (when overlay is active)
                    if let overlay = overlayState.activeOverlay {
                        MapLegendView(overlay: overlay)
                            .padding(.spacingM)
                    }

                    // Overlay availability indicator
                    if let overlay = overlayState.activeOverlay,
                       !WeatherTileOverlay.isAvailable(overlay) {
                        VStack {
                            Spacer()
                            HStack {
                                Image(systemName: overlay.isComingSoon || overlay == .avalanche ? "clock.fill" : "exclamationmark.triangle.fill")
                                    .foregroundColor(overlay.isComingSoon || overlay == .avalanche ? .blue : .orange)
                                Text(overlayUnavailableMessage(for: overlay))
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(.cornerRadiusButton)
                            .padding()
                        }
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

                // Search and filter section
                VStack(spacing: .spacingS) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search mountains...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.spacingS)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(.cornerRadiusButton)

                    // Filter chips row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: .spacingS) {
                            // Sort menu
                            Menu {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Button {
                                        sortBy = option
                                    } label: {
                                        Label(option.rawValue, systemImage: sortBy == option ? "checkmark" : "")
                                    }
                                }
                            } label: {
                                FilterChip(icon: "arrow.up.arrow.down", label: sortBy.rawValue, isActive: true)
                            }

                            // Pass filters
                            ForEach([PassFilter.all, .epic, .ikon, .favorites, .freshPowder], id: \.self) { passFilter in
                                Button {
                                    filterPass = passFilter
                                } label: {
                                    FilterChip(
                                        icon: passFilter.icon,
                                        label: passFilter.rawValue,
                                        isActive: filterPass == passFilter
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, .spacingM)
                .padding(.vertical, .spacingS)
                .background(Color(.systemBackground))

                Divider()

                // Mountain list (filtered)
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if filteredMountains.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: emptyStateIcon)
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text(emptyStateMessage)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(filteredMountains) { mountain in
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

    private func overlayUnavailableMessage(for overlay: MapOverlayType) -> String {
        switch overlay {
        case .avalanche:
            return "Avalanche Advisory - Coming Soon"
        case .landOwnership, .offlineMaps:
            return "\(overlay.fullName) - Coming Soon"
        case .temperature, .wind:
            return "\(overlay.fullName) requires API key"
        default:
            return "\(overlay.fullName) unavailable"
        }
    }

    private func selectMountain(_ mountain: Mountain) {
        selectedMountainId = mountain.id
        persistedMountainId = mountain.id
        withAnimation {
            mapRegion = MKCoordinateRegion(
                center: mountain.location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }
    }

    // MARK: - Filtering

    private var filteredMountains: [Mountain] {
        var mountains = viewModel.mountains

        // Apply pass filter
        if filterPass != .all {
            if let passType = filterPass.passTypeKey {
                mountains = mountains.filter { ($0.passType ?? .independent) == passType }
            } else if filterPass == .favorites {
                mountains = mountains.filter { favoritesManager.isFavorite($0.id) }
            } else if filterPass == .freshPowder {
                mountains = mountains.filter { mountain in
                    guard let conditions = viewModel.getConditions(for: mountain) else { return false }
                    return conditions.snowfall24h >= 6
                }
            }
        }

        // Apply search
        if !searchText.isEmpty {
            mountains = mountains.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.shortName.localizedCaseInsensitiveContains(searchText) ||
                $0.region.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sort
        mountains = mountains.sorted { m1, m2 in
            switch sortBy {
            case .name:
                return m1.name < m2.name
            case .distance:
                let d1 = viewModel.getDistance(to: m1) ?? Double.infinity
                let d2 = viewModel.getDistance(to: m2) ?? Double.infinity
                return d1 < d2
            case .powderScore:
                let s1 = viewModel.getScore(for: m1) ?? 0
                let s2 = viewModel.getScore(for: m2) ?? 0
                return s1 > s2
            case .favorites:
                let f1 = favoritesManager.isFavorite(m1.id)
                let f2 = favoritesManager.isFavorite(m2.id)
                if f1 != f2 { return f1 }
                return m1.name < m2.name
            }
        }

        return mountains
    }

    private var emptyStateIcon: String {
        switch filterPass {
        case .favorites: return "star"
        case .freshPowder: return "snowflake"
        case .epic: return "ticket"
        case .ikon: return "star.square"
        default: return "mountain.2"
        }
    }

    private var emptyStateMessage: String {
        switch filterPass {
        case .favorites: return "No favorites yet"
        case .freshPowder: return "No fresh powder today"
        case .epic: return "No Epic Pass mountains found"
        case .ikon: return "No Ikon Pass mountains found"
        default:
            if !searchText.isEmpty {
                return "No mountains match '\(searchText)'"
            }
            return "No mountains found"
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
struct MapSectionHeader: View {
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
