//
//  PowderAlertFAB.swift
//  PowderTracker
//
//  Floating action button that appears on powder days to quickly create events
//

import SwiftUI

struct PowderAlertFAB: View {
    let mountainName: String
    let snowfall24h: Int
    let onTap: () -> Void

    @State private var isVisible = false
    @State private var isPulsing = false
    @State private var showTooltip = false

    // Check if tooltip has been shown before
    @AppStorage("powderFABTooltipShown") private var tooltipShown = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            // Tooltip
            if showTooltip {
                tooltipView
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // FAB Button
            Button(action: {
                HapticFeedback.medium.trigger()
                onTap()
            }) {
                ZStack {
                    // Background with gradient
                    Circle()
                        .fill(LinearGradient.powderBlue)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.blue.opacity(0.4), radius: isPulsing ? 12 : 8, x: 0, y: 4)

                    // Snowflake icon
                    Image(systemName: "snowflake")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(.white)
                        .symbolEffect(.pulse, options: .repeating, value: isPulsing)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isVisible ? 1.0 : 0.0)
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isVisible = true
            }

            // Start pulsing after appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPulsing = true
            }

            // Show tooltip on first appearance
            if !tooltipShown {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showTooltip = true
                    }

                    // Auto-dismiss tooltip
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showTooltip = false
                        }
                        tooltipShown = true
                    }
                }
            }
        }
        .accessibilityLabel("Create powder day event at \(mountainName)")
        .accessibilityHint("Double tap to create an event with smart defaults")
    }

    private var tooltipView: some View {
        HStack(spacing: 6) {
            Image(systemName: "sparkles")
                .font(.caption)

            Text("\(snowfall24h)\" fresh! Tap to create event")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
        )
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        VStack {
            Spacer()
            HStack {
                Spacer()
                PowderAlertFAB(
                    mountainName: "Stevens Pass",
                    snowfall24h: 12,
                    onTap: { print("Tapped!") }
                )
                .padding()
            }
        }
    }
}
