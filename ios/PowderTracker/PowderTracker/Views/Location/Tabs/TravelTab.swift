import SwiftUI

struct TravelTab: View {
    var viewModel: LocationViewModel
    let mountain: Mountain
    @State private var arrivalTime: ArrivalTimeRecommendation?
    @State private var isLoadingArrivalTime = false
    @State private var parkingPrediction: ParkingPredictionResponse?
    @State private var isLoadingParking = false

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

            // Parking Prediction
            if let parking = parkingPrediction {
                ParkingCard(parking: parking)
            } else if isLoadingParking {
                ParkingLoadingView()
            } else {
                ParkingErrorView(onRetry: loadParkingPrediction)
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
            await loadParkingPrediction()
        }
    }

    private func loadArrivalTime() async {
        isLoadingArrivalTime = true

        do {
            arrivalTime = try await APIClient.shared.fetchArrivalTime(for: mountain.id)
        } catch {
            #if DEBUG
            print("Failed to load arrival time: \(error)")
            #endif
        }

        isLoadingArrivalTime = false
    }

    private func loadParkingPrediction() async {
        isLoadingParking = true

        do {
            parkingPrediction = try await APIClient.shared.fetchParkingPrediction(for: mountain.id)
        } catch {
            #if DEBUG
            print("Failed to load parking prediction: \(error)")
            #endif
        }

        isLoadingParking = false
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

struct ParkingLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Analyzing parking conditions...")
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

struct ParkingErrorView: View {
    let onRetry: () async -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load parking prediction")
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
