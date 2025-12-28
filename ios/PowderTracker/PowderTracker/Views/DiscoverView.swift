import SwiftUI
import MapKit

struct DiscoverView: View {
    @StateObject private var viewModel = MountainSelectionViewModel()
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var tripPlanningViewModel = TripPlanningViewModel()
    @StateObject private var locationManager = LocationManager.shared
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    )
    @State private var mapSelection: String?
    @State private var showFullMap = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact Map
                Map(position: $cameraPosition, selection: $mapSelection) {
                    UserAnnotation()

                    ForEach(viewModel.mountains) { mountain in
                        Annotation(
                            mountain.shortName,
                            coordinate: mountain.location.coordinate,
                            anchor: .bottom
                        ) {
                            MountainMarker(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                isSelected: mapSelection == mountain.id || selectedMountainId == mountain.id
                            )
                        }
                        .tag(mountain.id)
                    }
                }
                .mapStyle(.standard(elevation: .realistic))
                .mapControls {
                    MapUserLocationButton()
                    MapCompass()
                }
                .frame(height: UIScreen.main.bounds.height * 0.35)
                .overlay(alignment: .topTrailing) {
                    Button {
                        showFullMap = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "map")
                            Text("View All")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                    .padding(12)
                }

                // Selected Mountain Details
                ScrollView {
                    VStack(spacing: 20) {
                        if dashboardViewModel.isLoading && dashboardViewModel.conditions == nil {
                            DashboardSkeleton()
                        } else if let error = dashboardViewModel.error {
                            ErrorView(message: error) {
                                Task { await dashboardViewModel.refresh() }
                            }
                        } else {
                            // Header
                            mountainHeader

                            // Powder Score
                            if let score = dashboardViewModel.powderScore {
                                powderScoreSection(score)
                            }

                            // Conditions
                            if let conditions = dashboardViewModel.conditions {
                                MountainConditionsCard(conditions: conditions)
                            }

                            // Road & Pass Conditions
                            RoadsCard(roads: tripPlanningViewModel.roads)

                            // Trip Advice
                            TripAdviceCard(tripAdvice: tripPlanningViewModel.tripAdvice)

                            // Powder Day Planner
                            PowderDayCard(powderDayPlan: tripPlanningViewModel.powderDayPlan)

                            // Weather.gov Links
                            WeatherGovLinksView(mountainId: selectedMountainId)

                            // 3-Day Forecast Preview
                            if !dashboardViewModel.forecast.isEmpty {
                                forecastPreviewSection
                            }

                            // Quick Actions
                            quickActionsSection
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await dashboardViewModel.refresh()
                await tripPlanningViewModel.refresh(for: selectedMountainId)
            }
            .task(id: selectedMountainId) {
                await dashboardViewModel.loadData(for: selectedMountainId)
                await tripPlanningViewModel.fetchAll(for: selectedMountainId)
                zoomToSelectedMountain()
            }
            .task {
                await viewModel.loadMountains()
                locationManager.requestPermission()
            }
            .onChange(of: mapSelection) { _, newId in
                if let id = newId {
                    selectedMountainId = id
                }
            }
            .sheet(isPresented: $showFullMap) {
                FullMapView(
                    viewModel: viewModel,
                    selectedMountainId: $selectedMountainId,
                    showFullMap: $showFullMap
                )
            }
        }
    }

    private var mountainHeader: some View {
        VStack(spacing: 8) {
            if let conditions = dashboardViewModel.conditions {
                HStack(spacing: 8) {
                    Text(conditions.mountain.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Button {
                        showFullMap = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Change")
                            Image(systemName: "chevron.down.circle.fill")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }

                HStack(spacing: 12) {
                    Label("\(conditions.mountain.elevation.summit.formatted())'", systemImage: "mountain.2")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distance = viewModel.getDistance(to: conditions.mountain) {
                        Label("\(Int(distance)) mi away", systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func powderScoreSection(_ score: MountainPowderScore) -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                PowderScoreGauge(
                    score: Int(score.score.rounded()),
                    maxScore: 10,
                    label: scoreLabel(for: score.score)
                )
                Spacer()
            }

            Text(score.verdict)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(score.factors) { factor in
                    HStack {
                        Circle()
                            .fill(factor.contribution > factor.weight * 5 ? Color.green : Color.red)
                            .frame(width: 8, height: 8)

                        Text(factor.name)
                            .font(.subheadline)

                        Spacer()

                        Text(factor.description)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(factor.contribution > factor.weight * 5 ? .green : .red)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func scoreLabel(for score: Double) -> String {
        if score >= 8 { return "Epic" }
        if score >= 6 { return "Great" }
        if score >= 4 { return "Good" }
        return "Fair"
    }

    private var forecastPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("7-Day Forecast")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    ForecastView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(dashboardViewModel.forecast.prefix(3).enumerated()), id: \.element.id) { index, day in
                    ForecastDayRow(day: day, isToday: index == 0)
                    if index < 2 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                NavigationLink {
                    WebcamsView(mountainId: selectedMountainId)
                } label: {
                    QuickActionButton(icon: "video", title: "Webcams")
                }

                NavigationLink {
                    PatrolView(mountainId: selectedMountainId)
                } label: {
                    QuickActionButton(icon: "shield", title: "Patrol")
                }

                NavigationLink {
                    HistoryChartView()
                } label: {
                    QuickActionButton(icon: "chart.xyaxis.line", title: "History")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func zoomToSelectedMountain() {
        guard let mountain = viewModel.mountains.first(where: { $0.id == selectedMountainId }) else { return }
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: mountain.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
                )
            )
        }
        mapSelection = selectedMountainId
    }
}

// MARK: - Full Map View Sheet
struct FullMapView: View {
    @ObservedObject var viewModel: MountainSelectionViewModel
    @Binding var selectedMountainId: String
    @Binding var showFullMap: Bool

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.5, longitude: -121.5),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
        )
    )
    @State private var mapSelection: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Map(position: $cameraPosition, selection: $mapSelection) {
                    UserAnnotation()

                    ForEach(viewModel.mountains) { mountain in
                        Annotation(
                            mountain.shortName,
                            coordinate: mountain.location.coordinate,
                            anchor: .bottom
                        ) {
                            MountainMarker(
                                mountain: mountain,
                                score: viewModel.getScore(for: mountain),
                                isSelected: mapSelection == mountain.id || selectedMountainId == mountain.id
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
                .frame(height: UIScreen.main.bounds.height * 0.5)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if !viewModel.washingtonMountains.isEmpty {
                            Section {
                                ForEach(viewModel.washingtonMountains) { mountain in
                                    Button {
                                        selectMountain(mountain)
                                    } label: {
                                        MountainRow(
                                            mountain: mountain,
                                            score: viewModel.getScore(for: mountain),
                                            distance: viewModel.getDistance(to: mountain),
                                            isSelected: selectedMountainId == mountain.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                SectionHeader(title: "Washington")
                            }
                        }

                        if !viewModel.oregonMountains.isEmpty {
                            Section {
                                ForEach(viewModel.oregonMountains) { mountain in
                                    Button {
                                        selectMountain(mountain)
                                    } label: {
                                        MountainRow(
                                            mountain: mountain,
                                            score: viewModel.getScore(for: mountain),
                                            distance: viewModel.getDistance(to: mountain),
                                            isSelected: selectedMountainId == mountain.id
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            } header: {
                                SectionHeader(title: "Oregon")
                            }
                        }

                        if !viewModel.idahoMountains.isEmpty {
                            Section {
                                ForEach(viewModel.idahoMountains) { mountain in
                                    Button {
                                        selectMountain(mountain)
                                    } label: {
                                        MountainRow(
                                            mountain: mountain,
                                            score: viewModel.getScore(for: mountain),
                                            distance: viewModel.getDistance(to: mountain),
                                            isSelected: selectedMountainId == mountain.id
                                        )
                                    }
                                    .buttonStyle(.plain)
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
            .navigationTitle("All Mountains")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showFullMap = false
                    }
                }
            }
            .onChange(of: mapSelection) { _, newId in
                if let id = newId, let mountain = viewModel.mountains.first(where: { $0.id == id }) {
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
        }
    }

    private func selectMountain(_ mountain: Mountain) {
        selectedMountainId = mountain.id
        mapSelection = mountain.id
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: mountain.location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                )
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showFullMap = false
        }
    }
}

#Preview {
    DiscoverView()
}
