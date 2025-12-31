import SwiftUI

struct LocationView: View {
    let mountain: Mountain
    @StateObject private var viewModel: LocationViewModel
    @Environment(\.dismiss) private var dismiss

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
                    // Lift Status Section
                    LiftStatusSection(viewModel: viewModel)
                        .padding(.horizontal)

                    // Snow Depth Section
                    SnowDepthSection(viewModel: viewModel)
                        .padding(.horizontal)

                    // Weather Conditions Section
                    WeatherConditionsSection(viewModel: viewModel)
                        .padding(.horizontal)

                    // Road Conditions Section (only if has data)
                    if viewModel.hasRoadData {
                        RoadConditionsSection(viewModel: viewModel)
                            .padding(.horizontal)
                    }

                    // Webcams Section (only if has webcams)
                    if viewModel.hasWebcams {
                        WebcamsSection(viewModel: viewModel)
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
