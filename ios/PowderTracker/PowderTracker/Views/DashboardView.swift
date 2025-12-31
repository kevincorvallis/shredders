import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()
    @StateObject private var tripPlanningViewModel = TripPlanningViewModel()
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @State private var displayMountainId: String = "baker" // Immediate state for UI
    @State private var showingMountainPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading && viewModel.conditions == nil {
                        DashboardSkeleton()
                    } else if let error = viewModel.error {
                        ErrorView(message: error) {
                            Task { await viewModel.refresh() }
                        }
                    } else {
                        // Header with mountain picker
                        headerSection

                        // Powder Score
                        if let score = viewModel.powderScore {
                            powderScoreSection(score)
                        }

                        // Conditions
                        if let conditions = viewModel.conditions {
                            MountainConditionsCard(conditions: conditions)
                        }

                        // Road & Pass Conditions (WA mountains only)
                        RoadsCard(roads: tripPlanningViewModel.roads)

                        // Trip & Traffic Advice
                        TripAdviceCard(tripAdvice: tripPlanningViewModel.tripAdvice)

                        // Powder Day Planner (3-day)
                        PowderDayCard(powderDayPlan: tripPlanningViewModel.powderDayPlan)

                        // Weather.gov Integration (Alerts & Links)
                        WeatherGovLinksView(mountainId: displayMountainId)

                        // 3-Day Forecast Preview
                        if !viewModel.forecast.isEmpty {
                            forecastPreviewSection
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("PowderTracker")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingMountainPicker = true
                    } label: {
                        Image(systemName: "mountain.2.fill")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
                await tripPlanningViewModel.refresh(for: displayMountainId)
            }
            .task(id: displayMountainId) {
                await viewModel.loadData(for: displayMountainId)
                await tripPlanningViewModel.fetchAll(for: displayMountainId)
            }
            .onAppear {
                // Sync display state on appear
                displayMountainId = selectedMountainId
            }
            .onChange(of: selectedMountainId) { oldValue, newValue in
                // Update immediately when AppStorage changes
                displayMountainId = newValue
            }
            .sheet(isPresented: $showingMountainPicker) {
                MountainPickerView(selectedMountainId: $selectedMountainId)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            if let conditions = viewModel.conditions {
                Button {
                    showingMountainPicker = true
                } label: {
                    HStack(spacing: 8) {
                        Text(conditions.mountain.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)

                        Image(systemName: "chevron.down.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)

                if viewModel.conditions?.mountain != nil {
                    // Use the API's elevation data if available
                }
            } else {
                Text("Select Mountain")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
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

            Text(score.verdict ?? "")
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
                ForEach(Array(viewModel.forecast.prefix(3).enumerated()), id: \.element.id) { index, day in
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
}

struct ErrorView: View {
    let message: String
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

#Preview {
    DashboardView()
}
