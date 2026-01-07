import SwiftUI

struct TravelTab: View {
    @ObservedObject var viewModel: LocationViewModel
    let mountain: Mountain
    @State private var arrivalTime: ArrivalTimeRecommendation?
    @State private var isLoadingArrivalTime = false

    var body: some View {
        VStack(spacing: 16) {
            // AI-Powered Arrival Time Recommendation
            if let arrivalTime = arrivalTime {
                ArrivalTimeCard(arrivalTime: arrivalTime)
            } else if isLoadingArrivalTime {
                ArrivalTimeLoadingView()
            } else {
                ArrivalTimeErrorView(onRetry: loadArrivalTime)
            }

            // Navigation Card - Open in Apple Maps
            NavigationCard(mountain: mountain)

            // Road Conditions
            if viewModel.hasRoadData {
                RoadConditionsSection(viewModel: viewModel)
            }
        }
        .task {
            await loadArrivalTime()
        }
    }

    private func loadArrivalTime() async {
        isLoadingArrivalTime = true

        do {
            arrivalTime = try await APIClient.shared.fetchArrivalTime(for: mountain.id)
        } catch {
            print("Failed to load arrival time: \(error)")
        }

        isLoadingArrivalTime = false
    }
}

// MARK: - Loading & Error States

struct ArrivalTimeLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing conditions...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ArrivalTimeErrorView: View {
    let onRetry: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load arrival time")
                .font(.headline)

            Text("Check your connection and try again")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: {
                Task {
                    await onRetry()
                }
            }) {
                Label("Retry", systemImage: "arrow.clockwise")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.blue)
                    )
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
