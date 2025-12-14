import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: PowderEntry

    private var scoreColor: Color {
        switch entry.powderScore {
        case 9...10: return .green
        case 7...8: return .mint
        case 5...6: return .yellow
        case 3...4: return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left side - Score and conditions
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text("🏔️")
                    Text("Mt. Baker")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Spacer()

                // Powder Score
                HStack(spacing: 6) {
                    Text("\(entry.powderScore)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(entry.scoreLabel)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(scoreColor)

                        Text("Powder Score")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Snow Stats
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(entry.snowDepth)\"")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("depth")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text("+\(entry.snowfall24h)\"")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("24hr")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()
                .frame(height: 80)

            // Right side - 3-day forecast
            VStack(alignment: .leading, spacing: 4) {
                Text("3-Day Forecast")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                ForEach(entry.forecast) { day in
                    HStack {
                        Text(day.dayOfWeek)
                            .font(.caption)
                            .frame(width: 30, alignment: .leading)

                        Text(day.icon)
                            .font(.caption)

                        if day.snowfall > 0 {
                            Text("\(day.snowfall)\"")
                                .font(.caption)
                                .foregroundColor(.blue)
                        } else {
                            Text("—")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

#Preview(as: .systemMedium) {
    PowderTrackerWidget()
} timeline: {
    PowderEntry(
        date: Date(),
        snowDepth: 142,
        snowfall24h: 8,
        powderScore: 8,
        scoreLabel: "Great",
        forecast: [
            WidgetForecastDay(dayOfWeek: "Sat", snowfall: 6, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Sun", snowfall: 10, icon: "❄️"),
            WidgetForecastDay(dayOfWeek: "Mon", snowfall: 4, icon: "❄️")
        ]
    )
}
