import SwiftUI

struct LocationView: View {
    let mountain: Mountain
    @StateObject private var viewModel: LocationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDetailedSections = false
    @State private var navigateToTab: TabbedLocationView.Tab? = nil

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

                    // At a Glance summary card
                    AtAGlanceCard(
                        viewModel: viewModel,
                        onNavigateToLifts: { navigateToDetailView(.mountain) }
                    )
                    .padding(.horizontal)

                    // Lift Line Predictor (AI-powered)
                    if viewModel.locationData != nil {
                        LiftLinePredictorCard(viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    // Webcams Section (always visible when available)
                    if viewModel.hasWebcams {
                        WebcamsSection(viewModel: viewModel)
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
                            SnowDepthSection(
                                viewModel: viewModel,
                                onNavigateToHistory: { navigateToDetailView(.conditions) }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))

                            // Weather Conditions Section
                            WeatherConditionsSection(
                                viewModel: viewModel,
                                onNavigateToForecast: { navigateToDetailView(.conditions) }
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))

                            // Map Section with Lift Lines
                            if let mountainDetail = viewModel.locationData?.mountain {
                                LocationMapSection(
                                    mountain: mountain,
                                    mountainDetail: mountainDetail,
                                    liftData: viewModel.liftData
                                )
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Road Conditions Section (only if has data)
                            if viewModel.hasRoadData {
                                RoadConditionsSection(
                                    viewModel: viewModel,
                                    onNavigateToTravel: { navigateToDetailView(.travel) }
                                )
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
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchData()
        }
        .refreshable {
            await viewModel.fetchData()
        }
        .navigationDestination(item: $navigateToTab) { tab in
            TabbedLocationView(mountain: mountain, initialTab: tab)
        }
    }

    // MARK: - Navigation Helper

    private func navigateToDetailView(_ tab: TabbedLocationView.Tab) {
        navigateToTab = tab
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
            ),
            passType: .ikon
        ))
    }
}
