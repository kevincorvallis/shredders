import SwiftUI

/// Displays predicted lift line wait times based on current conditions
struct LiftLinePredictorCard: View {
    var viewModel: LocationViewModel
    @State private var showingDetails = false

    private var prediction: (overall: LiftLinePredictor.BusynessLevel, predictions: [LiftLinePredictor.LiftPrediction]) {
        // Use actual lift status if available, otherwise use mock data for testing
        let liftStatus = viewModel.locationData?.conditions.liftStatus
        let percentOpen = liftStatus?.percentOpen ?? 85
        let liftsOpen = liftStatus?.liftsOpen ?? 8
        let liftsTotal = liftStatus?.liftsTotal ?? 10

        return LiftLinePredictor.predictMountainBusyness(
            powderScore: Int(viewModel.powderScore ?? 5.0),
            temperature: viewModel.temperature ?? 32,
            windSpeed: viewModel.windSpeed ?? 10,
            percentOpen: percentOpen,
            liftsOpen: liftsOpen,
            liftsTotal: liftsTotal
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingL) {
            // Header
            HStack(alignment: .center, spacing: .spacingS) {
                Label("Lift Line Forecast", systemImage: "clock.fill")
                    .sectionHeader()
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: .spacingS)

                // AI badge
                HStack(spacing: .spacingXS) {
                    Image(systemName: "brain.head.profile")
                        .font(.caption2)
                    Text("AI Predicted")
                        .badge()
                }
                .foregroundColor(.purple)
                .padding(.horizontal, .spacingS)
                .padding(.vertical, .spacingXS)
                .background(
                    Capsule()
                        .fill(Color.purple.opacity(.opacitySubtle))
                )
                .layoutPriority(1) // Ensure badge doesn't get compressed
            }

            // Overall busyness indicator
            overallBusynessView

            // Current time context
            contextView

            // Lift predictions
            if showingDetails {
                Divider()
                liftPredictionsView
            }

            // Toggle details button
            Button {
                withAnimation(.spring()) {
                    showingDetails.toggle()
                }
            } label: {
                HStack {
                    Text(showingDetails ? "Hide Details" : "Show Lift-by-Lift Predictions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: showingDetails ? "chevron.up" : "chevron.down")
                }
                .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .standardCard()
    }

    // MARK: - Overall Busyness View

    private var overallBusynessView: some View {
        HStack(spacing: .spacingL) {
            // Icon
            Image(systemName: prediction.overall.icon)
                .font(.system(size: 40))
                .foregroundColor(colorForBusyness(prediction.overall))

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(prediction.overall.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorForBusyness(prediction.overall))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text("Overall Mountain")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("~\(LiftLinePredictor.estimatedWaitTime(busyness: prediction.overall)) typical wait")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer()

            // Busyness meter
            busynessMeter
        }
        .padding(.spacingM)
        .background(colorForBusyness(prediction.overall).opacity(.opacitySubtle))
        .cornerRadius(.cornerRadiusCard)
    }

    private var busynessMeter: some View {
        VStack(spacing: 2) {
            ForEach(0..<6, id: \.self) { index in
                Rectangle()
                    .fill(busynessBarColor(index: index))
                    .frame(width: 30, height: 8)
                    .cornerRadius(.cornerRadiusTiny / 2)
            }
        }
    }

    private func busynessBarColor(index: Int) -> Color {
        let level = busynessLevelToInt(prediction.overall)
        if index < level {
            return colorForBusyness(prediction.overall)
        } else {
            return Color.gray.opacity(0.2)
        }
    }

    private func busynessLevelToInt(_ level: LiftLinePredictor.BusynessLevel) -> Int {
        switch level {
        case .empty: return 1
        case .light: return 2
        case .moderate: return 3
        case .busy: return 4
        case .veryBusy: return 5
        case .packed: return 6
        }
    }

    // MARK: - Context View

    private var contextView: some View {
        let calendar = Calendar.current
        let now = Date()
        let isWeekend = calendar.component(.weekday, from: now) == 1 || calendar.component(.weekday, from: now) == 7

        return HStack(spacing: .spacingS) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.caption)

            Text(LiftLinePredictor.crowdReason(
                powderScore: Int(viewModel.powderScore ?? 5.0),
                currentTime: now,
                isWeekend: isWeekend
            ))
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }

    // MARK: - Lift Predictions View

    private var liftPredictionsView: some View {
        VStack(spacing: .spacingM) {
            Text("Lift-by-Lift Breakdown")
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(prediction.predictions, id: \.liftName) { pred in
                liftPredictionRow(pred)
            }

            // Disclaimer
            Text("Predictions based on current conditions, time, and typical patterns. Actual wait times may vary.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .padding(.top, .spacingS)
        }
    }

    private func liftPredictionRow(_ prediction: LiftLinePredictor.LiftPrediction) -> some View {
        VStack(spacing: .spacingS) {
            HStack {
                // Lift name
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(prediction.liftName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(prediction.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Wait time and status
                VStack(alignment: .trailing, spacing: .spacingXS) {
                    Text(LiftLinePredictor.estimatedWaitTime(busyness: prediction.busyness))
                        .metric()
                        .foregroundColor(colorForBusyness(prediction.busyness))

                    HStack(spacing: .spacingXS) {
                        Circle()
                            .fill(colorForBusyness(prediction.busyness))
                            .frame(width: .statusDotSize, height: .statusDotSize)
                        Text(prediction.busyness.rawValue)
                            .badge()
                            .foregroundColor(colorForBusyness(prediction.busyness))
                    }
                }
            }

            // Confidence indicator
            HStack(spacing: .spacingXS) {
                Text("Confidence:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 4)

                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: geometry.size.width * prediction.confidence, height: 4)
                    }
                    .cornerRadius(.cornerRadiusTiny / 2)
                }
                .frame(height: 4)

                Text("\(Int(prediction.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .frame(width: 35, alignment: .trailing)
            }
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }

    // MARK: - Helper Methods

    private func colorForBusyness(_ level: LiftLinePredictor.BusynessLevel) -> Color {
        switch level {
        case .empty, .light: return .green
        case .moderate: return .yellow
        case .busy: return .orange
        case .veryBusy, .packed: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        LiftLinePredictorCard(viewModel: {
            let vm = LocationViewModel(mountain: .mock)
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
                    webcamPageUrl: nil,
                    roadWebcams: nil,
                    color: "#4A90E2",
                    website: "https://www.mtbaker.us",
                    logo: "/logos/baker.svg",
                    status: nil,
                    passType: .independent
                ),
                conditions: MountainConditions.mock,
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
        }())
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
