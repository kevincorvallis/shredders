import SwiftUI

struct PowderDayCard: View {
    let powderDayPlan: PowderDayPlanResponse?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(.purple)
                Text("Powder Day Planner")
                    .font(.headline)
                Spacer()
            }

            if let plan = powderDayPlan, !plan.days.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(plan.days) { day in
                            PowderDayRow(day: day)
                        }
                    }
                }
            } else if powderDayPlan != nil {
                Text("No forecast data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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

struct PowderDayRow: View {
    let day: PowderDay

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Day header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isToday ? "Today" : day.dayOfWeek)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VerdictBadge(verdict: day.verdict)
            }

            // Powder score
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", day.predictedPowderScore))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(scoreColor)
                Text("/10")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Confidence
            Text("\(Int(day.confidence * 100))% confidence")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Divider()

            // Forecast snapshot
            VStack(alignment: .leading, spacing: 4) {
                if day.forecastSnapshot.snowfall > 0 {
                    Label("\(day.forecastSnapshot.snowfall)\" snow", systemImage: "snowflake")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }

                Label("\(day.forecastSnapshot.high)°/\(day.forecastSnapshot.low)°", systemImage: "thermometer")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("\(day.forecastSnapshot.windSpeed) mph", systemImage: "wind")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Best window
            if !day.bestWindow.isEmpty {
                Text(day.bestWindow)
                    .font(.caption2)
                    .foregroundStyle(.green)
                    .padding(.top, 4)
            }

            // Crowd risk
            HStack(spacing: 4) {
                Text("Crowds:")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(day.crowdRisk.displayName)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(crowdColor)
            }
        }
        .padding(12)
        .frame(width: 140)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var isToday: Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        return day.date == today
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: day.date) else { return day.date }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d"
        return displayFormatter.string(from: date)
    }

    private var scoreColor: Color {
        if day.predictedPowderScore >= 7 {
            return .green
        } else if day.predictedPowderScore >= 5 {
            return .yellow
        } else {
            return .red
        }
    }

    private var crowdColor: Color {
        switch day.crowdRisk {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}

struct VerdictBadge: View {
    let verdict: PowderVerdict

    var body: some View {
        HStack(spacing: 2) {
            Text(verdict.emoji)
                .font(.caption2)
            Text(verdict.displayName)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(verdictColor.opacity(0.2))
        .foregroundStyle(verdictColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var verdictColor: Color {
        switch verdict {
        case .send: return .green
        case .maybe: return .orange
        case .wait: return .gray
        }
    }
}

#Preview {
    VStack {
        PowderDayCard(powderDayPlan: .mock)
        PowderDayCard(powderDayPlan: nil)
    }
    .padding()
}
