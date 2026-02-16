import SwiftUI

// MARK: - Component Views

struct QuickFilterChipView: View {
    let filter: QuickFilter
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : filter.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? filter.color : filter.color.opacity(0.15))
            .cornerRadius(.cornerRadiusPill)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

struct DiscoverySection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingM) {
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding(.horizontal)

            content()
        }
    }
}

struct ConditionCardView: View {
    let mountain: Mountain
    let score: Double?
    let conditions: MountainConditions?
    let isFavorite: Bool
    let compareMode: Bool
    let isSelectedForComparison: Bool
    let onFavoriteToggle: () -> Void
    let onCompareToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Header
            ZStack(alignment: .topTrailing) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 60
                )
                .frame(maxWidth: .infinity)
                .frame(height: 80)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: mountain.color)?.opacity(0.3) ?? .blue.opacity(0.3),
                            Color(hex: mountain.color)?.opacity(0.1) ?? .blue.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                if compareMode {
                    Button(action: onCompareToggle) {
                        Image(systemName: isSelectedForComparison ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelectedForComparison ? .blue : .white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                } else {
                    Button(action: onFavoriteToggle) {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundColor(isFavorite ? .yellow : .white)
                            .shadow(radius: 2)
                    }
                    .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(mountain.shortName)
                    .font(.headline)
                    .lineLimit(1)

                if let score = score {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(scoreColor(score))
                            .frame(width: 8, height: 8)
                        Text(String(format: "%.1f", score))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(scoreColor(score))
                    }
                }

                if let conditions = conditions {
                    HStack(spacing: 4) {
                        Image(systemName: "cloud.snow.fill")
                            .font(.caption2)
                        Text("\(conditions.snowfall24h)\" 24h")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, .spacingM)
            .padding(.bottom, .spacingM)
        }
        .frame(width: 140)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelectedForComparison ? Color.blue : Color.clear, lineWidth: 2)
        )
    }

    private func scoreColor(_ score: Double) -> Color {
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .orange
    }
}

struct NearbyCardView: View {
    let mountain: Mountain
    let distance: Double?
    let score: Double?
    let conditions: MountainConditions?

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            HStack {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 44
                )

                Spacer()

                if let distance = distance {
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                        Text("\(Int(distance)) mi")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(.cornerRadiusButton)
                }
            }

            Text(mountain.shortName)
                .font(.headline)
                .lineLimit(1)

            HStack {
                if let score = score {
                    Text(String(format: "%.1f", score))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
                }

                Spacer()

                if let conditions = conditions {
                    Text("\(conditions.snowfall24h)\" new")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 160)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

struct FavoriteCardView: View {
    let mountain: Mountain
    let score: Double?
    let conditions: MountainConditions?

    var body: some View {
        HStack(spacing: .spacingM) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 50
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.headline)

                if let conditions = conditions {
                    Text("\(conditions.snowfall24h)\" 24h")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let score = score {
                Text(String(format: "%.1f", score))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
            }
        }
        .padding()
        .frame(width: 200)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusHero)
    }
}

struct RegionCardView: View {
    let region: MountainRegion
    let mountainCount: Int
    let topScore: Double?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: .spacingS) {
                HStack {
                    Image(systemName: region.icon)
                        .font(.title2)
                        .foregroundColor(region.color)

                    Spacer()

                    if let score = topScore {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f", score))
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.yellow)
                    }
                }

                Text(region.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("\(mountainCount) mountains")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(region.color.opacity(0.1))
            .cornerRadius(.cornerRadiusHero)
        }
        .buttonStyle(.plain)
    }
}

struct CompactMountainRowView: View {
    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let conditions: MountainConditions?
    let isFavorite: Bool
    let compareMode: Bool
    let isSelectedForComparison: Bool
    let onFavoriteToggle: () -> Void
    let onCompareToggle: () -> Void

    var body: some View {
        HStack(spacing: .spacingM) {
            if compareMode {
                Button(action: onCompareToggle) {
                    Image(systemName: isSelectedForComparison ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(isSelectedForComparison ? .blue : .secondary)
                }
            }

            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.shortName)
                    .font(.headline)

                HStack(spacing: .spacingS) {
                    Text(mountain.region.capitalized)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let distance = distance {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(Int(distance)) mi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let score = score {
                    Text(String(format: "%.1f", score))
                        .font(.headline)
                        .foregroundColor(score >= 7 ? .green : score >= 5 ? .yellow : .orange)
                }

                if let conditions = conditions, conditions.snowfall24h > 0 {
                    Text("\(conditions.snowfall24h)\"")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            if !compareMode {
                Button(action: onFavoriteToggle) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(isFavorite ? .yellow : .secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelectedForComparison ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

struct SearchResultRowView: View {
    let mountain: Mountain
    let score: Double?
    let distance: Double?
    let searchText: String

    var body: some View {
        HStack(spacing: .spacingM) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 44
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(mountain.name)
                    .font(.headline)

                Text(mountain.region.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let distance = distance {
                Text("\(Int(distance)) mi")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

struct ConditionStatView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
