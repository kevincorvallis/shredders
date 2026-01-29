//
//  ChartInteractionHint.swift
//  PowderTracker
//
//  First-time user hint overlay for interactive charts
//

import SwiftUI

/// Overlay hint to indicate chart is interactive
/// Shows on first view and disappears after interaction or timeout
struct ChartInteractionHint: View {
    @Binding var isVisible: Bool
    var onDismiss: (() -> Void)? = nil

    @State private var isPulsing = false
    @State private var fingerOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 8) {
            // Animated finger swipe gesture
            HStack(spacing: 4) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .offset(x: fingerOffset)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: fingerOffset
                    )

                Text("Swipe to explore")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.9))
                    .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(isPulsing ? 1.02 : 1.0)
            .animation(
                .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                value: isPulsing
            )
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
        .onAppear {
            isPulsing = true
            fingerOffset = 15

            // Auto-dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                dismiss()
            }
        }
    }

    private func dismiss() {
        guard isVisible else { return }
        withAnimation(.easeOut(duration: 0.3)) {
            isVisible = false
        }
        onDismiss?()
    }
}

/// Vertical scrub line that follows finger during chart interaction
struct ChartScrubLine: View {
    let xPosition: CGFloat
    let height: CGFloat
    let showGradientFade: Bool

    var body: some View {
        Rectangle()
            .fill(
                showGradientFade
                    ? AnyShapeStyle(LinearGradient(
                        colors: [
                            Color.blue.opacity(0),
                            Color.blue.opacity(0.6),
                            Color.blue.opacity(0.6),
                            Color.blue.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    : AnyShapeStyle(Color.blue.opacity(0.6))
            )
            .frame(width: 2, height: height)
            .position(x: xPosition, y: height / 2)
    }
}

/// A dot indicator that pulses to draw attention
struct PulsingIndicator: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0

    var color: Color = .blue
    var size: CGFloat = 12

    var body: some View {
        ZStack {
            // Outer pulsing ring
            Circle()
                .stroke(color.opacity(opacity * 0.5), lineWidth: 2)
                .frame(width: size * scale, height: size * scale)

            // Inner solid dot
            Circle()
                .fill(color)
                .frame(width: size * 0.6, height: size * 0.6)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                scale = 1.8
                opacity = 0.3
            }
        }
    }
}

/// Wrapper view that manages first-time hint display
struct ChartWithInteractionHint<Content: View>: View {
    @AppStorage("hasSeenForecastChartHint") private var hasSeenHint = false
    @State private var showHint = false
    @State private var hasInteracted = false

    let content: Content
    var hintPosition: HintPosition = .bottom

    enum HintPosition {
        case top
        case center
        case bottom
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    init(hintPosition: HintPosition, @ViewBuilder content: () -> Content) {
        self.hintPosition = hintPosition
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: hintAlignment) {
            content
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !hasInteracted {
                                hasInteracted = true
                                dismissHint()
                            }
                        }
                )

            if showHint {
                ChartInteractionHint(isVisible: $showHint) {
                    hasSeenHint = true
                }
                .padding(hintPadding)
            }
        }
        .onAppear {
            if !hasSeenHint && !hasInteracted {
                // Delay showing hint slightly for smoother appearance
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        showHint = true
                    }
                }
            }
        }
    }

    private var hintAlignment: Alignment {
        switch hintPosition {
        case .top: return .top
        case .center: return .center
        case .bottom: return .bottom
        }
    }

    private var hintPadding: EdgeInsets {
        switch hintPosition {
        case .top: return EdgeInsets(top: 12, leading: 0, bottom: 0, trailing: 0)
        case .center: return EdgeInsets()
        case .bottom: return EdgeInsets(top: 0, leading: 0, bottom: 12, trailing: 0)
        }
    }

    private func dismissHint() {
        withAnimation(.easeOut(duration: 0.3)) {
            showHint = false
        }
        hasSeenHint = true
    }
}

// Note: chartTooltip animation is defined in ChartStyles.swift

// MARK: - Preview

#Preview("Interaction Hint") {
    VStack(spacing: 40) {
        // Standalone hint
        ChartInteractionHint(isVisible: .constant(true))

        // Pulsing indicator
        PulsingIndicator()

        // Scrub line
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)

            ChartScrubLine(xPosition: 100, height: 150, showGradientFade: true)
        }
        .frame(width: 200)
    }
    .padding()
}

#Preview("Chart with Hint Wrapper") {
    ChartWithInteractionHint {
        Rectangle()
            .fill(Color.blue.opacity(0.2))
            .frame(height: 200)
            .overlay {
                Text("Chart Content")
                    .foregroundStyle(.secondary)
            }
    }
    .padding()
}
