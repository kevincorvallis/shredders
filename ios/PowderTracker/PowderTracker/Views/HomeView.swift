import SwiftUI

struct HomeView: View {
    @State private var dashboardViewModel = DashboardViewModel()
    @State private var tripPlanningViewModel = TripPlanningViewModel()
    @AppStorage("selectedMountainId") private var selectedMountainId = "baker"
    @State private var showingMountainPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if dashboardViewModel.isLoading && dashboardViewModel.conditions == nil {
                        DashboardSkeleton()
                    } else if let error = dashboardViewModel.error {
                        ErrorView(message: error) {
                            Task { await dashboardViewModel.refresh() }
                        }
                    } else {
                        // Mountain Selector
                        mountainSelector

                        // Snowfall Tracker (OpenSnow Style)
                        OpenSnowStyleSnowfallView(daysBack: 3, daysForward: 7)

                        // HERO: 7-Day Forecast (Horizontal Cards)
                        if !dashboardViewModel.forecast.isEmpty {
                            forecastSection
                        }

                        // Powder Score
                        if let score = dashboardViewModel.powderScore {
                            powderScoreSection(score)
                        }

                        // Current Conditions
                        if let conditions = dashboardViewModel.conditions {
                            MountainConditionsCard(conditions: conditions)
                        }

                        // Road & Pass Conditions
                        RoadsCard(roads: tripPlanningViewModel.roads)

                        // Trip Advice
                        TripAdviceCard(tripAdvice: tripPlanningViewModel.tripAdvice)

                        // Powder Day Planner
                        PowderDayCard(powderDayPlan: tripPlanningViewModel.powderDayPlan)

                        // Quick Actions
                        quickActionsSection
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await dashboardViewModel.refresh()
                await tripPlanningViewModel.refresh(for: selectedMountainId)
            }
            .task(id: selectedMountainId) {
                await dashboardViewModel.loadData(for: selectedMountainId)
                await tripPlanningViewModel.fetchAll(for: selectedMountainId)
            }
            .sheet(isPresented: $showingMountainPicker) {
                MountainPickerView(selectedMountainId: $selectedMountainId)
            }
        }
    }

    private var mountainSelector: some View {
        Button {
            showingMountainPicker = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT MOUNTAIN")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    if let conditions = dashboardViewModel.conditions {
                        HStack(spacing: 8) {
                            Text(conditions.mountain.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            Image(systemName: "chevron.down.circle.fill")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text("Select Mountain")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("7-DAY FORECAST")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Next week's snow outlook")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                NavigationLink {
                    ForecastView()
                } label: {
                    Text("View All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)

            // Horizontal Scrolling Forecast Cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(dashboardViewModel.forecast.prefix(7).enumerated()), id: \.element.id) { index, day in
                        ForecastHorizontalCard(day: day, isToday: index == 0)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func powderScoreSection(_ score: MountainPowderScore) -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("POWDER SCORE")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("Today's riding conditions")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }

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
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func scoreLabel(for score: Double) -> String {
        if score >= 8 { return "Epic" }
        if score >= 6 { return "Great" }
        if score >= 4 { return "Good" }
        return "Fair"
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK ACTIONS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal)

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
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Forecast Horizontal Card
struct ForecastHorizontalCard: View {
    let day: ForecastDay
    let isToday: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(isToday ? "Today" : dayName)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(isToday ? .blue : .primary)

            // Weather Icon
            Image(systemName: weatherIcon)
                .font(.system(size: 32))
                .foregroundColor(weatherColor)
                .frame(height: 40)

            // Snow Amount (if any)
            if day.snowfall > 0 {
                VStack(spacing: 2) {
                    Text("\(day.snowfall)\"")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("snow")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("0\"")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Temperature
            VStack(spacing: 2) {
                Text("\(day.high)°")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(day.low)°")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Wind
            HStack(spacing: 4) {
                Image(systemName: "wind")
                    .font(.caption2)
                Text("\(day.wind.speed) mph")
                    .font(.caption2)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 100)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var dayName: String {
        return day.dayOfWeek
    }

    private var weatherIcon: String {
        let conditions = day.conditions.lowercased()
        if conditions.contains("snow") {
            return "snowflake"
        } else if conditions.contains("rain") {
            return "cloud.rain"
        } else if conditions.contains("cloud") || conditions.contains("overcast") {
            return "cloud"
        } else if conditions.contains("clear") || conditions.contains("sunny") {
            return "sun.max"
        } else {
            return "cloud.sun"
        }
    }

    private var weatherColor: Color {
        if day.snowfall > 0 { return .blue }
        let conditions = day.conditions.lowercased()
        if conditions.contains("snow") { return .blue }
        if conditions.contains("clear") || conditions.contains("sunny") { return .orange }
        return .gray
    }
}

#Preview {
    HomeView()
}
