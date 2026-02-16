//
//  ActionAnimations.swift
//  PowderTracker
//
//  Action completion animations and mini sparkline components
//

import SwiftUI

// MARK: - Action Completion Animations

/// Checkmark animation for successful action completion
struct ActionCompletedCheckmark: View {
    @State private var isAnimating = false

    var body: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.title)
            .foregroundStyle(.green)
            .scaleEffect(isAnimating ? 1.0 : 0.5)
            .opacity(isAnimating ? 1.0 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    isAnimating = true
                }
            }
    }
}

/// Toast notification for action completion
struct ActionToast: View {
    let message: String
    let icon: String
    var color: Color = .green

    @State private var isVisible = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isVisible = true
            }
        }
    }
}

/// View modifier to show action completion animation
struct ActionCompletionModifier: ViewModifier {
    @Binding var showCompletion: Bool
    let message: String
    let icon: String
    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if showCompletion {
                    ActionToast(message: message, icon: icon)
                        .padding(.top, 20)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showCompletion = false
                                }
                            }
                        }
                }
            }
            .animation(.spring(response: 0.3), value: showCompletion)
    }
}

extension View {
    /// Shows a completion toast when action completes
    func actionCompletion(
        isPresented: Binding<Bool>,
        message: String,
        icon: String = "checkmark.circle.fill",
        duration: Double = 2.0
    ) -> some View {
        modifier(ActionCompletionModifier(
            showCompletion: isPresented,
            message: message,
            icon: icon,
            duration: duration
        ))
    }
}

// MARK: - Mini Sparkline

/// Compact sparkline chart for showing trends
struct MiniSparkline: View {
    let data: [Double]
    var color: Color = .blue
    var lineWidth: CGFloat = 2
    var showDots: Bool = false

    var body: some View {
        GeometryReader { geo in
            if data.count > 1 {
                let maxValue = data.max() ?? 1
                let minValue = data.min() ?? 0
                let range = maxValue - minValue > 0 ? maxValue - minValue : 1

                Path { path in
                    for (index, value) in data.enumerated() {
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minValue) / range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                // Optional dots at data points
                if showDots {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                        let x = geo.size.width * CGFloat(index) / CGFloat(data.count - 1)
                        let y = geo.size.height * (1 - CGFloat((value - minValue) / range))

                        Circle()
                            .fill(color)
                            .frame(width: lineWidth * 2, height: lineWidth * 2)
                            .position(x: x, y: y)
                    }
                }
            }
        }
    }
}

/// Sparkline with trend indicator
struct SparklineWithTrend: View {
    let data: [Double]
    let label: String
    var color: Color = .blue

    private var trend: TrendDirection {
        guard data.count >= 2 else { return .stable }
        let recent = data.suffix(3).reduce(0, +) / Double(min(3, data.count))
        let older = data.prefix(3).reduce(0, +) / Double(min(3, data.count))
        if recent > older * 1.1 { return .up }
        if recent < older * 0.9 { return .down }
        return .stable
    }

    enum TrendDirection {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .secondary
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Image(systemName: trend.icon)
                    .font(.caption2)
                    .foregroundColor(trend.color)
            }

            MiniSparkline(data: data, color: color, lineWidth: 1.5)
                .frame(height: 20)
        }
    }
}

/// Score history sparkline specifically for powder scores
struct PowderScoreSparkline: View {
    let scores: [Double] // Last 7 days of scores

    var body: some View {
        SparklineWithTrend(
            data: scores,
            label: "7-day trend",
            color: .forPowderScore(scores.last ?? 5)
        )
    }
}
