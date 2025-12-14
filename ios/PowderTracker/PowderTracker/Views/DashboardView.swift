import SwiftUI

struct DashboardView: View {
    @State private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
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
                        // Header
                        headerSection

                        // Powder Score
                        if let score = viewModel.powderScore {
                            powderScoreSection(score)
                        }

                        // Conditions
                        if let conditions = viewModel.conditions {
                            ConditionsCard(conditions: conditions)
                        }

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
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            if let conditions = viewModel.conditions {
                Text(conditions.mountain.name)
                    .font(.title)
                    .fontWeight(.bold)

                Text("\(conditions.mountain.elevation.base.formatted())' - \(conditions.mountain.elevation.summit.formatted())'")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical)
    }

    private func powderScoreSection(_ score: PowderScore) -> some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                PowderScoreGauge(score: score.score, maxScore: score.maxScore, label: score.label)
                Spacer()
            }

            Text(score.recommendation)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Factors
            VStack(spacing: 8) {
                ForEach(score.factors) { factor in
                    HStack {
                        Circle()
                            .fill(factor.isPositive ? Color.green : Color.red)
                            .frame(width: 8, height: 8)

                        Text(factor.name)
                            .font(.subheadline)

                        Spacer()

                        Text(factor.value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(factor.isPositive ? .green : .red)
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
