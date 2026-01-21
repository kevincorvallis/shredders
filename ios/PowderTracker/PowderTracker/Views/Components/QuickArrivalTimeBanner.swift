import SwiftUI

struct QuickArrivalTimeBanner: View {
    let mountain: Mountain
    @State private var arrivalTime: ArrivalTimeRecommendation?
    @State private var isLoading = false
    @Binding var selectedTab: TabbedLocationView.Tab

    var body: some View {
        Group {
            if let arrivalTime = arrivalTime {
                arrivalTimeBanner(arrivalTime)
            } else if isLoading {
                loadingBanner
            }
        }
        .task {
            await loadArrivalTime()
        }
    }

    // MARK: - Arrival Time Banner

    private func arrivalTimeBanner(_ recommendation: ArrivalTimeRecommendation) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = .travel
            }
        }) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text("Best Arrival Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    Text(recommendation.recommendedArrivalTime)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: recommendation.confidence.icon)
                            .font(.caption2)

                        Text("\(recommendation.confidence.displayName) Confidence")
                            .font(.caption2)
                    }
                    .foregroundColor(confidenceColor(recommendation.confidence))
                }

                Spacer()

                // Chevron
                VStack(spacing: 4) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text("Details")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Loading Banner

    private var loadingBanner: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Loading arrival time...")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }

    // MARK: - Helpers

    private func loadArrivalTime() async {
        isLoading = true

        do {
            arrivalTime = try await APIClient.shared.fetchArrivalTime(for: mountain.id)
        } catch {
            #if DEBUG
            print("Failed to load quick arrival time: \(error)")
            #endif
        }

        isLoading = false
    }

    private func confidenceColor(_ confidence: ArrivalTimeRecommendation.Confidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}
