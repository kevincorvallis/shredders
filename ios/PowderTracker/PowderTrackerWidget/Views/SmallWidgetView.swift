import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
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
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("🏔️")
                Text(entry.mountainName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            }

            Spacer()

            // Powder Score
            HStack(spacing: 8) {
                Text("\(entry.powderScore)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)

                VStack(alignment: .leading, spacing: 2) {
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
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.snowDepth)\"")
                        .font(.headline)
                    Text("depth")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("+\(entry.snowfall24h)\"")
                        .font(.headline)
                        .foregroundColor(.blue)
                    Text("24hr")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

#Preview(as: .systemSmall) {
    PowderTrackerWidget()
} timeline: {
    PowderEntry(
        date: Date(),
        mountainId: "crystal-mountain",
        mountainName: "Crystal Mountain",
        snowDepth: 142,
        snowfall24h: 8,
        powderScore: 8,
        scoreLabel: "Great",
        forecast: []
    )
}
