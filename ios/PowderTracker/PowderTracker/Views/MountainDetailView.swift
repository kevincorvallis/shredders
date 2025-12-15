import SwiftUI

struct MountainDetailView: View {
    let mountainId: String
    let mountainName: String

    @State private var viewModel = DashboardViewModel()
    @StateObject private var tripPlanningViewModel = TripPlanningViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.conditions == nil {
                    ProgressView("Loading conditions...")
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if let error = viewModel.error {
                    ErrorView(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else {
                    // Powder Score
                    if let score = viewModel.powderScore {
                        powderScoreSection(score)
                    }

                    // Conditions
                    if let conditions = viewModel.conditions {
                        MountainConditionsCard(conditions: conditions)
                    }

                    // Road & Pass Conditions
                    RoadsCard(roads: tripPlanningViewModel.roads)

                    // Trip & Traffic Advice
                    TripAdviceCard(tripAdvice: tripPlanningViewModel.tripAdvice)

                    // Powder Day Planner
                    PowderDayCard(powderDayPlan: tripPlanningViewModel.powderDayPlan)

                    // 3-Day Forecast Preview
                    if !viewModel.forecast.isEmpty {
                        forecastSection
                    }

                    // Quick Actions
                    quickActionsSection
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(mountainName)
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refresh()
            await tripPlanningViewModel.refresh(for: mountainId)
        }
        .task {
            await viewModel.loadData(for: mountainId)
            await tripPlanningViewModel.fetchAll(for: mountainId)
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

            // Factors
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

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("7-Day Forecast")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.forecast.enumerated()), id: \.element.id) { index, day in
                    ForecastDayRow(day: day, isToday: index == 0)
                    if index < viewModel.forecast.count - 1 {
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
                    WebcamsView()
                } label: {
                    QuickActionButton(icon: "video", title: "Webcams")
                }

                NavigationLink {
                    PatrolView()
                } label: {
                    QuickActionButton(icon: "shield", title: "Patrol")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        MountainDetailView(mountainId: "baker", mountainName: "Mt. Baker")
    }
}
