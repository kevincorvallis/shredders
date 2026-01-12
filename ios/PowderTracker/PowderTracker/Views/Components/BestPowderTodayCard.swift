import SwiftUI

struct BestPowderTodayCard: View {
    let mountain: Mountain
    let conditions: MountainConditions?
    let powderScore: Int?
    let arrivalTime: ArrivalTimeRecommendation?
    let parking: ParkingPredictionResponse?
    let viewModel: HomeViewModel?
    @State private var scoreAnimationAmount: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("BEST POWDER TODAY")
                        .badge()
                        .foregroundColor(.white.opacity(0.9))
                        .tracking(1)

                    Text(mountain.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                // Powder score
                if let score = powderScore {
                    ZStack {
                        // Pulsing ring for epic scores
                        if score >= 8 {
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 2)
                                .frame(width: .iconHero + 10, height: .iconHero + 10)
                                .scaleEffect(scoreAnimationAmount)
                                .opacity(2 - scoreAnimationAmount)
                        }

                        Circle()
                            .fill(Color.white.opacity(.opacityLight))
                            .frame(width: .iconHero, height: .iconHero)

                        VStack(spacing: .spacingXS) {
                            Text("\(score)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("/10")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .onAppear {
                        if score >= 8 {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                scoreAnimationAmount = 1.3
                            }
                        }
                    }
                }
            }
            .padding(.spacingL)
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

            // Why Best? Section
            let reasons = viewModel?.getWhyBestReasons(for: mountain.id) ?? []
            if !reasons.isEmpty {
                VStack(alignment: .leading, spacing: .spacingS) {
                    Text("Why Best?")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    ForEach(Array(reasons.enumerated()), id: \.offset) { index, reason in
                        HStack(alignment: .top, spacing: .spacingS) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)

                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Parking badge (if available)
                    if let parking = parking {
                        HStack(spacing: 6) {
                            Image(systemName: "parkingsign.circle.fill")
                                .font(.caption)
                                .foregroundColor(parkingColor(for: parking.difficulty))

                            Text("\(parking.difficulty.displayName) Parking")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(parkingColor(for: parking.difficulty))
                        }
                        .padding(.horizontal, .spacingS)
                        .padding(.vertical, .spacingXS)
                        .background(parkingColor(for: parking.difficulty).opacity(.opacitySubtle))
                        .cornerRadius(.cornerRadiusButton)
                    }
                }
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingM)
                .background(Color(.systemBackground))
            }

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
            .padding(.spacingL)
            .background(Color(.tertiarySystemBackground))
        }
        .background(Color(.systemBackground))
        .cornerRadius(.cornerRadiusHero)
        .heroShadow()
    }

    // MARK: - Helpers

    private func parkingColor(for difficulty: ParkingDifficulty) -> Color {
        Color.forParkingDifficulty(difficulty.displayName)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: .spacingS) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .metric()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingM)
    }
}
