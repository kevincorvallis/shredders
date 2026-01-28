import SwiftUI
import Charts

struct HistoryChartView: View {
    @State private var viewModel = HistoryViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading && viewModel.history.isEmpty {
                    HistoryChartSkeleton()
                } else if let error = viewModel.error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    // Period Picker
                    periodPicker

                    // Summary Stats
                    if let summary = viewModel.summary {
                        summarySection(summary)
                    }

                    // Chart
                    if !viewModel.history.isEmpty {
                        SnowDepthChart(history: viewModel.history)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.history.isEmpty {
                await viewModel.loadHistory()
            }
        }
    }

    private var periodPicker: some View {
        Picker("Period", selection: Binding(
            get: { viewModel.selectedDays },
            set: { days in
                Task { await viewModel.changePeriod(to: days) }
            }
        )) {
            Text("7 Days").tag(7)
            Text("30 Days").tag(30)
            Text("60 Days").tag(60)
            Text("90 Days").tag(90)
        }
        .pickerStyle(.segmented)
    }

    private func summarySection(_ summary: HistorySummary) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Current", value: "\(summary.currentDepth)\"", subtitle: "depth")
            StatCard(title: "Peak", value: "\(summary.maxDepth)\"", subtitle: "max depth")
            StatCard(title: "Total", value: "\(summary.totalSnowfall)\"", subtitle: "snowfall")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)

            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

#Preview {
    NavigationStack {
        HistoryChartView()
    }
}
