//
//  ArrivalParkingRow.swift
//  PowderTracker
//
//  Expandable row showing arrival and parking information
//

import SwiftUI

struct ArrivalParkingRow: View {
    let mountain: Mountain
    let arrivalTime: ArrivalTimeRecommendation?
    let parking: ParkingPredictionResponse?

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed State - Always visible
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    // Mountain logo
                    MountainLogoView(
                        logoUrl: mountain.logo,
                        color: mountain.color,
                        size: 40
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(mountain.shortName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)

                        // Arrival time preview
                        if let arrival = arrivalTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)

                                Text(arrival.arrivalWindow.optimal)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                // Confidence badge
                                confidenceBadge(arrival.confidence)
                            }
                        }

                        // Parking preview
                        if let pkg = parking {
                            HStack(spacing: 4) {
                                Image(systemName: "parkingsign.circle")
                                    .font(.caption2)
                                    .foregroundStyle(parkingColor(pkg.difficulty))

                                Text(pkg.difficulty.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let firstLot = pkg.recommendedLots.first {
                                    Text("• \(firstLot.name)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }

                        // Crowd level (from arrival time)
                        if let arrival = arrivalTime {
                            HStack(spacing: 4) {
                                Image(systemName: "person.3")
                                    .font(.caption2)
                                    .foregroundStyle(crowdColor(arrival.factors.expectedCrowdLevel))

                                Text(arrival.factors.expectedCrowdLevel.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()

                    // Expand chevron
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding()
            }
            .buttonStyle(.plain)

            // Expanded State - Detailed information
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()

                    // Detailed arrival info
                    if let arrival = arrivalTime {
                        arrivalDetails(arrival)
                    }

                    // Detailed parking info
                    if let pkg = parking {
                        parkingDetails(pkg)
                    }

                    // Actions
                    HStack(spacing: 12) {
                        // Get Directions button
                        Button {
                            openMapsDirections()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                                Text("Directions")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        // View Full Details button
                        NavigationLink {
                            LocationView(mountain: mountain)
                        } label: {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("Details")
                            }
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.tertiarySystemBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .padding(.top, -8)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func confidenceBadge(_ confidence: ArrivalTimeRecommendation.Confidence) -> some View {
        HStack(spacing: 2) {
            Image(systemName: confidence.icon)
                .font(.caption2)
            Text(confidence.displayName)
                .font(.caption2)
        }
        .foregroundStyle(confidenceColor(confidence))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(confidenceColor(confidence).opacity(0.15))
        .clipShape(Capsule())
    }

    private func arrivalDetails(_ arrival: ArrivalTimeRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Arrival Window")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Earliest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(arrival.arrivalWindow.earliest)
                        .font(.caption)
                        .fontWeight(.medium)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Optimal")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(arrival.arrivalWindow.optimal)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(arrival.arrivalWindow.latest)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            if !arrival.reasoning.isEmpty {
                Text("Reasoning")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                ForEach(Array(arrival.reasoning.prefix(2)), id: \.self) { reason in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func parkingDetails(_ pkg: ParkingPredictionResponse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Parking Recommendations")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ForEach(Array(pkg.recommendedLots.prefix(2))) { lot in
                HStack(spacing: 8) {
                    Image(systemName: lot.type.icon)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(width: 20)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lot.name)
                            .font(.caption)
                            .fontWeight(.medium)

                        if let notes = lot.notes {
                            Text(notes)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }

                    Spacer()

                    HStack(spacing: 2) {
                        Image(systemName: lot.availability.icon)
                            .font(.caption2)
                        Text(lot.availability.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(availabilityColor(lot.availability))
                }
                .padding(.vertical, 4)
            }

            if pkg.reservationRequired, let url = pkg.reservationUrl {
                Link(destination: URL(string: url)!) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                        Text("Reserve Parking")
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.blue)
                }
            }
        }
    }

    private func confidenceColor(_ confidence: ArrivalTimeRecommendation.Confidence) -> Color {
        switch confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }

    private func parkingColor(_ difficulty: ParkingDifficulty) -> Color {
        switch difficulty {
        case .easy: return .green
        case .moderate: return .yellow
        case .challenging: return .orange
        case .veryDifficult: return .red
        }
    }

    private func crowdColor(_ crowd: ArrivalTimeRecommendation.ArrivalFactors.CrowdLevel) -> Color {
        switch crowd {
        case .low: return .green
        case .medium: return .yellow
        case .high, .extreme: return .red
        }
    }

    private func availabilityColor(_ availability: LotAvailability) -> Color {
        switch availability {
        case .likely: return .green
        case .limited: return .yellow
        case .full: return .red
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
