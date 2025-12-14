import SwiftUI

struct PowderScoreGauge: View {
    let score: Int
    let maxScore: Int
    let label: String

    private var progress: Double {
        Double(score) / Double(maxScore)
    }

    private var scoreColor: Color {
        switch score {
        case 9...10: return .green
        case 7...8: return .mint
        case 5...6: return .yellow
        case 3...4: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundColor(scoreColor)

                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 120, height: 120)

            Text("Powder Score")
                .font(.headline)
        }
    }
}

#Preview {
    PowderScoreGauge(score: 8, maxScore: 10, label: "Great")
        .padding()
}
