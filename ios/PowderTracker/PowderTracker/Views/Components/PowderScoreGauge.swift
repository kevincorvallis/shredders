import SwiftUI

struct PowderScoreGauge: View {
    let score: Int
    let maxScore: Int
    let label: String
    var factors: [MountainPowderScore.ScoreFactor]? = nil

    @State private var showFactors = false

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

            // Show "Tap for details" hint if factors are available
            if factors != nil && !showFactors {
                Text("Tap for breakdown")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if factors != nil {
                HapticFeedback.light.trigger()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showFactors.toggle()
                }
            }
        }
        .popover(isPresented: $showFactors) {
            scoreFactorsPopover
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Powder Score: \(score) out of \(maxScore), \(label)")
        .accessibilityValue("\(score)")
        .accessibilityHint(factors != nil ? "Double tap to see score breakdown" : "")
    }

    @ViewBuilder
    private var scoreFactorsPopover: some View {
        if let factors = factors {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Score Breakdown")
                        .font(.headline)
                    Spacer()
                    Button {
                        showFactors = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                ForEach(factors, id: \.name) { factor in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(factor.name)
                                .font(.subheadline.weight(.medium))
                            if !factor.description.isEmpty {
                                Text(factor.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        // Factor contribution bar
                        HStack(spacing: 4) {
                            ProgressView(value: factor.contribution / 10.0)
                                .frame(width: 50)
                                .tint(scoreColor)
                            Text(String(format: "+%.1f", factor.contribution))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .frame(minWidth: 280)
            .presentationCompactAdaptation(.popover)
        }
    }
}

#Preview {
    PowderScoreGauge(score: 8, maxScore: 10, label: "Great")
        .padding()
}
