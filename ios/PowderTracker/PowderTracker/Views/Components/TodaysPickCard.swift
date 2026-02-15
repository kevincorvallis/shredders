import SwiftUI

/// Best mountain recommendation card with "why this pick" breakdown
/// Prominently displays the top pick for today based on powder score
struct TodaysPickCard: View {
    let mountain: Mountain
    let powderScore: MountainPowderScore
    let data: MountainBatchedResponse
    let reasons: [String]
    var onTap: (() -> Void)? = nil

    private var scoreColor: Color {
        Color.forPowderScore(powderScore.score)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: .spacingM) {
                // Header with mountain info and score
                headerSection

                // Why this pick breakdown
                if !reasons.isEmpty {
                    reasonsSection
                }

                // Quick stats row
                quickStatsRow

                // Call to action
                ctaSection
            }
            .padding(.spacingL)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusHero)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: .cornerRadiusHero)
                    .stroke(scoreColor.opacity(0.5), lineWidth: 2)
            )
            .heroShadow()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's pick: \(mountain.name), powder score \(String(format: "%.1f", powderScore.score))")
        .accessibilityHint("Double tap to view details")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(spacing: .spacingM) {
            // Mountain logo
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 48
            )

            VStack(alignment: .leading, spacing: 4) {
                // Today's Pick label
                Text("TODAY'S PICK")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor)
                    .tracking(0.5)

                // Mountain name
                Text(mountain.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()

            // Powder score badge
            VStack(spacing: 2) {
                Text(String(format: "%.1f", powderScore.score))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("SCORE")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingS)
            .background(
                RoundedRectangle(cornerRadius: .cornerRadiusButton)
                    .fill(scoreColor)
            )
        }
    }

    // MARK: - Reasons Section

    private var reasonsSection: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Text("Why this pick?")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            ForEach(reasons.indices, id: \.self) { index in
                HStack(spacing: .spacingS) {
                    Image(systemName: reasonIcon(for: reasons[index]))
                        .font(.system(size: 12))
                        .foregroundColor(scoreColor)
                        .frame(width: 16)

                    Text(reasons[index])
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.spacingM)
        .background(
            RoundedRectangle(cornerRadius: .cornerRadiusCard)
                .fill(scoreColor.opacity(0.08))
        )
    }

    // MARK: - Quick Stats Row

    private var quickStatsRow: some View {
        HStack(spacing: 0) {
            // 24h Snow
            statItem(
                value: "\(data.conditions.snowfall24h)\"",
                label: "24h Snow",
                icon: "cloud.snow.fill"
            )

            Divider()
                .frame(height: 32)

            // Temperature
            if let temp = data.conditions.temperature {
                statItem(
                    value: "\(temp)°F",
                    label: "Temp",
                    icon: "thermometer.medium"
                )

                Divider()
                    .frame(height: 32)
            }

            // Lifts
            if let liftStatus = data.conditions.liftStatus {
                statItem(
                    value: "\(liftStatus.liftsOpen)/\(liftStatus.liftsTotal)",
                    label: "Lifts",
                    icon: "cablecar.fill"
                )
            }
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        HStack {
            Text("View Details")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(scoreColor)
        }
        .padding(.top, .spacingXS)
    }

    // MARK: - Helpers

    private func reasonIcon(for reason: String) -> String {
        let reasonLower = reason.lowercased()
        if reasonLower.contains("snow") || reasonLower.contains("fresh") {
            return "snowflake"
        } else if reasonLower.contains("crowd") || reasonLower.contains("light") {
            return "person.2.fill"
        } else if reasonLower.contains("more than") {
            return "arrow.up.right"
        } else if reasonLower.contains("parking") {
            return "car.fill"
        } else if reasonLower.contains("monday") || reasonLower.contains("tuesday") || reasonLower.contains("wednesday") || reasonLower.contains("thursday") || reasonLower.contains("friday") {
            return "calendar"
        }
        return "checkmark.circle.fill"
    }
}

// MARK: - Equatable

extension TodaysPickCard: Equatable {
    static func == (lhs: TodaysPickCard, rhs: TodaysPickCard) -> Bool {
        lhs.mountain.id == rhs.mountain.id
            && lhs.powderScore.score == rhs.powderScore.score
            && lhs.data.conditions.snowfall24h == rhs.data.conditions.snowfall24h
            && lhs.reasons == rhs.reasons
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            TodaysPickCard(
                mountain: Mountain.mock,
                powderScore: MountainPowderScore.mock,
                data: MountainBatchedResponse.mock,
                reasons: [
                    "8\" fresh snow in 24h",
                    "Light crowds expected (Monday)",
                    "+4\" more than Crystal"
                ]
            )
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
