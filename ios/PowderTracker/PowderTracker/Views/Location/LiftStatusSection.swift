import SwiftUI

struct LiftStatusSection: View {
    @ObservedObject var viewModel: LocationViewModel

    var body: some View {
        if let liftStatus = viewModel.locationData?.conditions.liftStatus {
            VStack(alignment: .leading, spacing: 12) {
                // Section Header
                HStack {
                    Label("Lift Status", systemImage: "cablecar.fill")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Spacer()

                    // Live indicator
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
                }

                // Lift Status Card
                LiftStatusCard(liftStatus: liftStatus)
            }
        }
    }
}

#Preview {
    ScrollView {
        LiftStatusSection(
            viewModel: {
                let vm = LocationViewModel(mountain: Mountain(
                    id: "baker",
                    name: "Mt. Baker",
                    shortName: "Baker",
                    location: MountainLocation(lat: 48.8587, lng: -121.6714),
                    elevation: MountainElevation(base: 3500, summit: 5089),
                    region: "WA",
                    color: "#4A90E2",
                    website: "https://www.mtbaker.us",
                    hasSnotel: true,
                    webcamCount: 3,
                    logo: "/logos/baker.svg",
                    status: nil
                ))

                // Mock lift status data
                vm.locationData = MountainBatchedResponse(
                    mountain: MountainDetail(
                        id: "baker",
                        name: "Mt. Baker",
                        shortName: "Baker",
                        location: MountainLocation(lat: 48.8587, lng: -121.6714),
                        elevation: MountainElevation(base: 3500, summit: 5089),
                        region: "WA",
                        snotel: MountainDetail.SnotelInfo(stationId: "909", stationName: "Wells Creek"),
                        noaa: MountainDetail.NOAAInfo(gridOffice: "SEW", gridX: 120, gridY: 110),
                        webcams: [],
                        roadWebcams: nil,
                        color: "#4A90E2",
                        website: "https://www.mtbaker.us",
                        logo: "/logos/baker.svg",
                        status: nil
                    ),
                    conditions: MountainConditions(
                        mountain: MountainInfo(id: "baker", name: "Mt. Baker", shortName: "Baker"),
                        snowDepth: 142,
                        snowWaterEquivalent: 58.4,
                        snowfall24h: 8,
                        snowfall48h: 14,
                        snowfall7d: 32,
                        temperature: 28,
                        temperatureByElevation: MountainConditions.TemperatureByElevation(
                            base: 32,
                            mid: 28,
                            summit: 25,
                            referenceElevation: 4500,
                            referenceTemp: 28,
                            lapseRate: 3.5
                        ),
                        conditions: "Snow",
                        wind: MountainConditions.WindInfo(speed: 15, direction: "SW"),
                        lastUpdated: ISO8601DateFormatter().string(from: Date()),
                        liftStatus: LiftStatus(
                            isOpen: true,
                            liftsOpen: 9,
                            liftsTotal: 10,
                            runsOpen: 45,
                            runsTotal: 52,
                            message: "All major lifts operating",
                            lastUpdated: ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600))
                        ),
                        dataSources: MountainConditions.DataSources(
                            snotel: MountainConditions.DataSources.SnotelSource(available: true, stationName: "Wells Creek"),
                            noaa: MountainConditions.DataSources.NOAASource(available: true, gridOffice: "SEW"),
                            liftStatus: MountainConditions.DataSources.LiftStatusSource(available: true)
                        )
                    ),
                    powderScore: MountainPowderScore.mock,
                    forecast: [],
                    sunData: nil,
                    roads: nil,
                    tripAdvice: nil,
                    powderDay: nil,
                    alerts: [],
                    weatherGovLinks: nil,
                    status: nil,
                    cachedAt: ISO8601DateFormatter().string(from: Date())
                )

                return vm
            }()
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
