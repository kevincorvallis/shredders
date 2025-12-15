import SwiftUI

struct TripAdviceCard: View {
    let tripAdvice: TripAdviceResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "car.side.fill")
                    .foregroundStyle(.blue)
                Text("Trip & Traffic")
                    .font(.headline)
                Spacer()
            }

            if let advice = tripAdvice {
                // Headline
                Text(advice.headline)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                // Risk badges
                HStack(spacing: 12) {
                    RiskBadge(label: "Crowds", level: advice.crowd)
                    RiskBadge(label: "Traffic", level: advice.trafficRisk)
                    RiskBadge(label: "Roads", level: advice.roadRisk)
                }

                // Suggested departures
                if !advice.suggestedDepartures.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Suggested Departure")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ForEach(advice.suggestedDepartures.prefix(2)) { departure in
                            HStack {
                                Text(departure.from)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Spacer()
                                Text(departure.suggestion)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(10)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Notes
                if !advice.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(advice.notes.prefix(3), id: \.self) { note in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RiskBadge: View {
    let label: String
    let level: RiskLevel

    var body: some View {
        VStack(spacing: 2) {
            Text(level.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(levelColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(levelColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var levelColor: Color {
        switch level {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

#Preview {
    VStack {
        TripAdviceCard(tripAdvice: .mock)
        TripAdviceCard(tripAdvice: nil)
    }
    .padding()
}
