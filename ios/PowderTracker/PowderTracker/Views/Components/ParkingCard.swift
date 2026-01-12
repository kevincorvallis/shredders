import SwiftUI

struct ParkingCard: View {
    let parking: ParkingPredictionResponse
    @State private var showLots = false
    @State private var showTips = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            VStack(spacing: .spacingL) {
                // Difficulty section
                difficultySection

                // Recommended arrival time
                arrivalTimeSection

                // Reservation alert (if required)
                if parking.reservationRequired {
                    reservationAlert
                }

                // Parking lots toggle
                if !parking.recommendedLots.isEmpty {
                    lotsToggle
                }

                // Tips toggle
                if !parking.tips.isEmpty {
                    tipsToggle
                }
            }
            .padding(.spacingL)
        }
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusHero)
                .strokeBorder(difficultyColor.opacity(.opacityBold), lineWidth: 2)
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text("Parking Prediction")
                    .sectionHeader()

                Text("AI-powered analysis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Confidence badge
            ConfidenceIndicator(
                confidence: parking.confidence.displayName,
                style: .badge,
                showIcon: true,
                showText: true
            )
        }
        .padding(.spacingL)
        .background(Color(.tertiarySystemBackground))
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        VStack(spacing: .spacingM) {
            // Large difficulty icon
            Image(systemName: parking.difficulty.icon)
                .font(.system(size: 56))
                .foregroundColor(difficultyColor)
                .frame(height: 80)

            // Difficulty level
            Text(parking.difficulty.displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(difficultyColor)

            // Headline
            Text(parking.headline)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingL)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(difficultyColor.opacity(.opacitySubtle))
        )
    }

    // MARK: - Arrival Time Section

    private var arrivalTimeSection: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: "clock.fill")
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(.opacityMedium))
                )

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text("Recommended Arrival")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(parking.recommendedArrivalTime)
                    .metric()
            }

            Spacer()
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(Color(.tertiarySystemBackground))
        )
    }

    // MARK: - Reservation Alert

    private var reservationAlert: some View {
        VStack(spacing: .spacingS) {
            HStack(spacing: .spacingS) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Reservation Required")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text("Book parking in advance to guarantee a spot")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            if let url = parking.reservationUrl, let reservationURL = URL(string: url) {
                Link(destination: reservationURL) {
                    HStack {
                        Text("Book Parking Now")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, .spacingS)
                    .background(
                        RoundedRectangle(cornerRadius: .cornerRadiusButton)
                            .fill(Color.orange)
                    )
                }
            }
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(Color.orange.opacity(.opacitySubtle))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .strokeBorder(Color.orange.opacity(.opacityBold), lineWidth: 1)
        )
    }

    // MARK: - Parking Lots

    private var lotsToggle: some View {
        ExpandableSection(
            title: "Parking Lots",
            icon: "parkingsign.circle.fill",
            count: parking.recommendedLots.count,
            color: .blue,
            isExpanded: $showLots
        ) {
            ForEach(parking.recommendedLots) { lot in
                ParkingLotRow(lot: lot)
            }
        }
    }

    // MARK: - Tips

    private var tipsToggle: some View {
        ExpandableSection(
            title: "Parking Tips",
            icon: "lightbulb.fill",
            count: parking.tips.count,
            color: .orange,
            isExpanded: $showTips
        ) {
            ForEach(Array(parking.tips.enumerated()), id: \.offset) { index, tip in
                HStack(alignment: .top, spacing: .spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)

                    Text(tip)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Helpers

    private var difficultyColor: Color {
        Color.forParkingDifficulty(parking.difficulty.displayName)
    }

}

// MARK: - Supporting Views

struct ParkingLotRow: View {
    let lot: ParkingLotRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Lot name and type
            HStack {
                Image(systemName: lot.type.icon)
                    .font(.subheadline)
                    .foregroundColor(lotTypeColor)

                Text(lot.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Availability badge
                HStack(spacing: .spacingXS) {
                    Circle()
                        .fill(availabilityColor)
                        .frame(width: .statusIndicatorSize, height: .statusIndicatorSize)

                    Text(lot.availability.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(availabilityColor)
                }
                .padding(.horizontal, .spacingS)
                .padding(.vertical, .spacingXS)
                .background(
                    Capsule()
                        .fill(availabilityColor.opacity(.opacityMedium))
                )
            }

            // Details
            HStack(spacing: .spacingL) {
                HStack(spacing: .spacingXS) {
                    Image(systemName: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(lot.distanceToLift)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: .spacingXS) {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(lot.capacity.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Notes
            if let notes = lot.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, .spacingXS)
            }
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .fill(Color(.tertiarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .cornerRadiusButton)
                .strokeBorder(availabilityColor.opacity(.opacityLight), lineWidth: 1)
        )
    }

    private var lotTypeColor: Color {
        switch lot.type {
        case .main: return .blue
        case .overflow: return .orange
        case .premium: return .purple
        case .shuttle: return .green
        }
    }

    private var availabilityColor: Color {
        switch lot.availability {
        case .likely: return .green
        case .limited: return .orange
        case .full: return .red
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ParkingCard(parking: .mock)
            ParkingCard(parking: .mockEasy)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
