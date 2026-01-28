//
//  LeaveNowCard.swift
//  PowderTracker
//
//  Urgent departure card for Now tab
//

import SwiftUI

struct LeaveNowCard: View {
    let mountain: Mountain
    let arrivalTime: ArrivalTimeRecommendation

    private var parkingDifficultyColor: Color {
        switch arrivalTime.factors.parkingDifficulty {
        case .easy: return .green
        case .moderate: return .yellow
        case .challenging: return .orange
        case .veryDifficult: return .red
        }
    }

    var body: some View {
        VStack(spacing: .spacingL) {
            // Header with Leave Now badge
            HStack {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 50
                )

                VStack(alignment: .leading, spacing: .spacingXS) {
                    HStack(spacing: .spacingS) {
                        Text("LEAVE NOW")
                            .badge()
                            .foregroundStyle(.white)
                            .padding(.horizontal, .spacingS)
                            .padding(.vertical, .spacingXS)
                            .background(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .symbolEffect(.pulse)

                        Spacer()
                    }

                    Text(mountain.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }

            Divider()

            // Arrival details
            VStack(spacing: .spacingM) {
                // Arrival window
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text("Optimal Arrival")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(arrivalTime.arrivalWindow.optimal)
                            .metric()
                    }

                    Spacer()

                    // Confidence badge
                    HStack(spacing: .spacingXS) {
                        Image(systemName: arrivalTime.confidence.icon)
                            .font(.caption2)

                        Text(arrivalTime.confidence.displayName)
                            .badge()
                    }
                    .foregroundStyle(confidenceColor)
                    .padding(.horizontal, .spacingS)
                    .padding(.vertical, .spacingXS)
                    .background(confidenceColor.opacity(0.15))
                    .clipShape(Capsule())
                }

                // Parking difficulty
                HStack {
                    Image(systemName: "parkingsign.circle.fill")
                        .foregroundStyle(parkingDifficultyColor)

                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text("Parking")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(arrivalTime.factors.parkingDifficulty.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }

                // Crowd level
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(crowdLevelColor)

                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text("Crowd Level")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(arrivalTime.factors.expectedCrowdLevel.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    Spacer()
                }
            }

            // Get Directions button
            Button {
                openMapsDirections()
            } label: {
                HStack {
                    Image(systemName: "arrow.triangle.turn.up.right.circle.fill")

                    Text("Get Directions")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.spacingM)
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusCard))
            }
            .accessibilityLabel("Get directions to \(mountain.name)")
            .accessibilityHint("Opens Maps app with directions")
        }
        .padding(.spacingL)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusHero)
        .heroShadow()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Leave now for \(mountain.name). Optimal arrival time: \(arrivalTime.arrivalWindow.optimal). Parking: \(arrivalTime.factors.parkingDifficulty.displayName). Crowd level: \(arrivalTime.factors.expectedCrowdLevel.displayName).")
    }

    private var confidenceColor: Color {
        switch arrivalTime.confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }

    private var crowdLevelColor: Color {
        switch arrivalTime.factors.expectedCrowdLevel {
        case .low: return .green
        case .medium: return .yellow
        case .high, .extreme: return .red
        }
    }

    private func openMapsDirections() {
        let lat = mountain.location.lat
        let lng = mountain.location.lng
        if let url = URL(string: "maps://?daddr=\(lat),\(lng)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Preview temporarily disabled")
        .padding()
}
