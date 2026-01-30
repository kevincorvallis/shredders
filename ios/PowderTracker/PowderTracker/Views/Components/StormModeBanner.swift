//
//  StormModeBanner.swift
//  PowderTracker
//
//  Animated banner showing active winter storm information
//

import SwiftUI

struct StormModeBanner: View {
    let stormInfo: StormInfo
    let mountainName: String?

    @State private var isPulsing = false
    @State private var snowflakeOffset: CGFloat = 0

    private var intensity: StormIntensity {
        stormInfo.intensity
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with animated icon
            HStack(spacing: 12) {
                // Pulsing storm icon
                ZStack {
                    Circle()
                        .fill(intensity.accentColor.opacity(0.3))
                        .frame(width: 44, height: 44)
                        .scaleEffect(isPulsing ? 1.2 : 1.0)
                        .opacity(isPulsing ? 0.5 : 1.0)

                    Image(systemName: intensity.iconName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(intensity.accentColor)
                        .symbolEffect(.bounce, options: .repeating.speed(0.5), value: isPulsing)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(stormInfo.eventType ?? "Winter Storm")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    if let mountainName = mountainName {
                        Text(mountainName)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                Spacer()

                // Severity badge
                if let severity = stormInfo.severity {
                    Text(severity.uppercased())
                        .font(.caption2)
                        .fontWeight(.black)
                        .foregroundStyle(intensity.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white)
                        .clipShape(Capsule())
                }
            }

            // Storm details
            HStack(spacing: 20) {
                // Expected snowfall
                if let snowfall = stormInfo.expectedSnowfall, snowfall > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "snowflake")
                            .font(.caption)
                        Text("\(snowfall)\" expected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                }

                // Time remaining
                if let hours = stormInfo.hoursRemaining, hours > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(formatHoursRemaining(hours))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                // Score boost indicator
                if let boost = stormInfo.scoreBoost, boost > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.caption)
                        Text("+\(String(format: "%.1f", boost))")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                }
            }

            // Intensity indicator bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.3))
                        .frame(height: 6)

                    // Fill based on intensity
                    RoundedRectangle(cornerRadius: 3)
                        .fill(intensity.accentColor)
                        .frame(width: intensityWidth(for: geometry.size.width), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: intensity.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: intensity.color.opacity(0.4), radius: 8, y: 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }

    private func formatHoursRemaining(_ hours: Int) -> String {
        if hours >= 24 {
            let days = hours / 24
            return "\(days)d remaining"
        } else if hours > 1 {
            return "\(hours)h remaining"
        } else {
            return "< 1h remaining"
        }
    }

    private func intensityWidth(for totalWidth: CGFloat) -> CGFloat {
        let percentage: CGFloat
        switch intensity {
        case .light: percentage = 0.25
        case .moderate: percentage = 0.5
        case .heavy: percentage = 0.75
        case .extreme: percentage = 1.0
        }
        return totalWidth * percentage
    }
}

// MARK: - Compact Storm Badge (for inline use)

struct StormBadge: View {
    let stormInfo: StormInfo

    private var intensity: StormIntensity {
        stormInfo.intensity
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: intensity.iconName)
                .font(.caption)
                .symbolEffect(.pulse, options: .repeating)

            if let snowfall = stormInfo.expectedSnowfall, snowfall > 0 {
                Text("\(snowfall)\"")
                    .font(.caption)
                    .fontWeight(.bold)
            } else {
                Text(intensity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            LinearGradient(
                colors: intensity.gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: - Preview

#Preview("Storm Banner - Heavy") {
    VStack(spacing: 20) {
        StormModeBanner(
            stormInfo: StormInfo(
                isActive: true,
                isPowderBoost: true,
                eventType: "Winter Storm Warning",
                hoursRemaining: 18,
                expectedSnowfall: 18,
                severity: "Severe",
                scoreBoost: 1.5
            ),
            mountainName: "Mt. Baker"
        )

        StormModeBanner(
            stormInfo: StormInfo(
                isActive: true,
                isPowderBoost: true,
                eventType: "Blizzard Warning",
                hoursRemaining: 6,
                expectedSnowfall: 30,
                severity: "Extreme",
                scoreBoost: 1.5
            ),
            mountainName: "Crystal Mountain"
        )

        HStack {
            StormBadge(stormInfo: StormInfo(
                isActive: true,
                isPowderBoost: true,
                eventType: "Winter Weather Advisory",
                hoursRemaining: 12,
                expectedSnowfall: 6,
                severity: "Moderate",
                scoreBoost: 0.5
            ))

            StormBadge(stormInfo: StormInfo(
                isActive: true,
                isPowderBoost: true,
                eventType: "Heavy Snow Warning",
                hoursRemaining: 8,
                expectedSnowfall: 14,
                severity: "Severe",
                scoreBoost: 1.2
            ))
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
