import SwiftUI

struct LocationView: View {
    let mountain: Mountain
    @StateObject private var viewModel: LocationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var viewMode: ViewMode = .glance
    @State private var showingDetailedSections = false

    enum ViewMode {
        case glance  // At a Glance card
        case radial  // Radial dashboard
    }

    init(mountain: Mountain) {
        self.mountain = mountain
        _viewModel = StateObject(wrappedValue: LocationViewModel(mountain: mountain))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.isLoading {
                    ProgressView("Loading conditions...")
                        .padding(.top, 100)
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task {
                            await viewModel.fetchData()
                        }
                    }
                    .padding()
                } else if viewModel.locationData != nil {

                    // View mode toggle
                    viewModeToggle
                        .padding(.horizontal)

                    // Main visualization (toggleable)
                    Group {
                        switch viewMode {
                        case .glance:
                            AtAGlanceCard(viewModel: viewModel)
                        case .radial:
                            RadialDashboard(viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)

                    // Lift Line Predictor (AI-powered)
                    // TEMP: Always show for testing until AWS credentials are added to Vercel
                    if viewModel.locationData != nil {
                        LiftLinePredictorCard(viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    // Detailed sections toggle
                    Button {
                        withAnimation(.spring()) {
                            showingDetailedSections.toggle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: showingDetailedSections ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            Text(showingDetailedSections ? "Hide Detailed Sections" : "Show More Details")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Detailed sections (collapsible)
                    if showingDetailedSections {
                        VStack(spacing: 16) {
                            // Snow Depth Section
                            SnowDepthSection(viewModel: viewModel)
                                .transition(.move(edge: .top).combined(with: .opacity))

                            // Weather Conditions Section
                            WeatherConditionsSection(viewModel: viewModel)
                                .transition(.move(edge: .top).combined(with: .opacity))

                            // Map Section
                            if let mountainDetail = viewModel.locationData?.mountain {
                                LocationMapSection(mountain: mountain, mountainDetail: mountainDetail)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Road Conditions Section (only if has data)
                            if viewModel.hasRoadData {
                                RoadConditionsSection(viewModel: viewModel)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Webcams Section (only if has webcams)
                            if viewModel.hasWebcams {
                                WebcamsSection(viewModel: viewModel)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .padding(.top, 100)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(mountain.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.fetchData()
        }
        .refreshable {
            await viewModel.fetchData()
        }
    }

    // MARK: - View Mode Toggle

    private var viewModeToggle: some View {
        HStack(spacing: 12) {
            ForEach([ViewMode.glance, ViewMode.radial], id: \.self) { mode in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewMode = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode == .glance ? "square.grid.2x2.fill" : "circle.grid.cross.fill")
                            .font(.caption)
                        Text(mode == .glance ? "At a Glance" : "Radial View")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(viewMode == mode ? .white : .blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(viewMode == mode ? Color.blue : Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LocationView(mountain: Mountain(
            id: "crystal",
            name: "Crystal Mountain",
            shortName: "Crystal",
            location: MountainLocation(lat: 46.9356, lng: -121.4747),
            elevation: MountainElevation(base: 4400, summit: 7012),
            region: "WA",
            color: "#4A90E2",
            website: "https://www.crystalmountainresort.com",
            hasSnotel: true,
            webcamCount: 3,
            logo: "/logos/crystal.svg",
            status: MountainStatus(
                isOpen: true,
                percentOpen: 88,
                liftsOpen: "10/11",
                runsOpen: "50/57",
                message: "Excellent skiing",
                lastUpdated: nil
            )
        ))
    }
}
