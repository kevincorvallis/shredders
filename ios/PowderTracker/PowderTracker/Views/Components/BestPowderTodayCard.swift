import SwiftUI

struct BestPowderTodayCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: Int?
    let arrivalTime: ArrivalTimeRecommendation?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BEST POWDER TODAY")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(1)

                    Text(mountain.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                Spacer()

                // Powder score
                if let score = powderScore {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)

                        VStack(spacing: 2) {
                            Text("\(score)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("/10")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: mountain.color) ?? .blue,
                        (Color(hex: mountain.color) ?? .blue).opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Stats grid
            HStack(spacing: 0) {
                StatPill(
                    icon: "snow",
                    value: conditions.map { "\($0.snowfall24h)\"" } ?? "N/A",
                    label: "24h Snow"
                )

                Divider()
                    .frame(height: 40)

                StatPill(
                    icon: "thermometer.medium",
                    value: conditions?.temperature.map { "\(Int($0))°" } ?? "N/A",
                    label: "Temp"
                )

                Divider()
                    .frame(height: 40)

                if let arrivalTime = arrivalTime {
                    StatPill(
                        icon: "clock.fill",
                        value: arrivalTime.recommendedArrivalTime,
                        label: "Arrive By"
                    )
                } else {
                    StatPill(
                        icon: "mountain.2.fill",
                        value: conditions?.snowDepth.map { "\(Int($0))\"" } ?? "N/A",
                        label: "Base"
                    )
                }
            }
            .background(Color(.secondarySystemBackground))

            // CTA button
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)

                Text("View Details")
                    .font(.headline)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundColor(.primary)
            .padding()
            .background(Color(.tertiarySystemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
