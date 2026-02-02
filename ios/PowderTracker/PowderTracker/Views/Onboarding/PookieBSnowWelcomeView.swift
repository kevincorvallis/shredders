//
//  PookieBSnowWelcomeView.swift
//  PowderTracker
//
//  Production-level welcome screen for the PookieBSnow onboarding flow.
//  Features Brock the golden doodle as your guide with premium animations and polish.
//
//  Design principles:
//  - Accessibility-first (respects reduce motion)
//  - Modern .bouncy/.smooth animations
//  - Staggered reveal for visual delight
//  - Haptic feedback for emotional connection
//

import SwiftUI
import UIKit

struct PookieBSnowWelcomeView: View {
    let onContinue: () -> Void

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var showBrock = false
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showButton = false
    @State private var buttonPulse = false

    // Brock micro-animations
    @State private var brockBreath: CGFloat = 1.0
    @State private var brockTilt: Double = 0
    @State private var scarfWave = false
    @State private var glowPulse: CGFloat = 1.0

    // Feature row stagger
    @State private var featureReveal: [Bool] = [false, false, false, false]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: .spacingXL)

                    // Brock greeting section
                    brockSection
                        .padding(.bottom, .spacingL)

                    // Welcome text
                    titleSection
                        .padding(.bottom, .spacingXL)

                    // Feature highlights
                    featureSection
                        .padding(.horizontal, .spacingL)
                        .padding(.bottom, .spacingXL)

                    Spacer(minLength: .spacingL)

                    // Continue button
                    continueButton
                        .padding(.horizontal, .spacingL)
                        .padding(.bottom, .spacingXL)
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        .onAppear {
            if reduceMotion {
                showAllInstantly()
            } else {
                startAnimationSequence()
            }
        }
    }

    // MARK: - Brock Section

    private var brockSection: some View {
        ZStack {
            // Warm golden glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.3),
                            Color(red: 1.0, green: 0.75, blue: 0.4).opacity(0.15),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 100
                    )
                )
                .frame(width: 180, height: 180)
                .scaleEffect(glowPulse)

            // Brock with winter gear
            VStack(spacing: -14) {
                Text("🐕")
                    .font(.system(size: 90))
                    .scaleEffect(brockBreath)
                    .rotationEffect(.degrees(brockTilt))

                Text("🧣")
                    .font(.system(size: 28))
                    .offset(y: -78)
                    .rotationEffect(.degrees(scarfWave ? -4 : 4))
            }
            .scaleEffect(showBrock ? 1.0 : 0.3)
            .opacity(showBrock ? 1.0 : 0)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 12) {
            Text("Woof! I'm Brock")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))

            Text("Your PookieBSnow Guide")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.55, blue: 0.75),
                            Color(red: 0.85, green: 0.45, blue: 0.88),
                            Color(red: 0.5, green: 0.8, blue: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .multilineTextAlignment(.center)
                .shadow(color: .purple.opacity(0.3), radius: 12, y: 4)

            Text("Let's sniff out the best powder together!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
        }
        .padding(.horizontal, 24)
        .opacity(showTitle ? 1.0 : 0)
        .offset(y: showTitle ? 0 : 20)
    }

    // MARK: - Feature Section

    private var featureSection: some View {
        VStack(spacing: 16) {
            PookieBFeatureRow(
                icon: "snowflake",
                iconColor: .cyan,
                title: "Fresh Tracks Alert",
                description: "I'll bark when powder days hit!",
                isVisible: featureReveal[0]
            )

            PookieBFeatureRow(
                icon: "pawprint.fill",
                iconColor: .orange,
                title: "Pack Adventures",
                description: "Plan trips with your crew",
                isVisible: featureReveal[1]
            )

            PookieBFeatureRow(
                icon: "mountain.2.fill",
                iconColor: .blue,
                title: "Mountain Intel",
                description: "Real-time conditions & forecasts",
                isVisible: featureReveal[2]
            )

            PookieBFeatureRow(
                icon: "figure.skiing.downhill",
                iconColor: .purple,
                title: "Shred Ready",
                description: "Know before you go!",
                isVisible: featureReveal[3]
            )
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            HapticFeedback.medium.trigger()
            onContinue()
        } label: {
            HStack(spacing: 10) {
                Text("Let's Go Shred!")
                    .font(.system(size: 18, weight: .bold, design: .rounded))

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .scaleEffect(buttonPulse ? 1.1 : 1.0)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.5, blue: 0.72),
                        Color(red: 0.8, green: 0.42, blue: 0.88),
                        Color(red: 0.5, green: 0.7, blue: 1.0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.purple.opacity(0.45), radius: 16, y: 8)
            .shadow(color: Color.cyan.opacity(0.25), radius: 24, y: 12)
        }
        .scaleEffect(showButton ? 1.0 : 0.9)
        .opacity(showButton ? 1.0 : 0)
    }

    // MARK: - Animation Sequence

    private func startAnimationSequence() {
        // Haptic on entry
        HapticFeedback.light.trigger()

        // Phase 1: Brock bounces in
        withAnimation(.bouncy(duration: 0.7, extraBounce: 0.15)) {
            showBrock = true
        }

        // Start Brock micro-animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            startBrockAnimations()
        }

        // Phase 2: Title appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.smooth(duration: 0.5)) {
                showTitle = true
            }
        }

        // Phase 3: Features stagger in
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 + Double(i) * 0.1) {
                withAnimation(.bouncy(duration: 0.5, extraBounce: 0.1)) {
                    featureReveal[i] = true
                }
            }
        }

        // Phase 4: Button appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.bouncy(duration: 0.6, extraBounce: 0.12)) {
                showButton = true
            }

            // Button pulse
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true).delay(0.3)) {
                buttonPulse = true
            }
        }
    }

    private func startBrockAnimations() {
        // Breathing
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            brockBreath = 1.05
        }

        // Gentle tilt
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            brockTilt = 4
        }

        // Scarf wave
        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
            scarfWave = true
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            glowPulse = 1.15
        }
    }

    private func showAllInstantly() {
        showBrock = true
        showTitle = true
        showButton = true
        featureReveal = [true, true, true, true]
    }
}

// MARK: - Feature Row Component

private struct PookieBFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let isVisible: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Icon with glassmorphic background
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
            }
            .shadow(color: iconColor.opacity(0.3), radius: 8, y: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                Text(description)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Check indicator
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green.opacity(0.8))
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(x: isVisible ? 0 : -30)
    }
}

// MARK: - Preview

#Preview {
    PookieBSnowWelcomeView(onContinue: {})
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.22),
                    Color(red: 0.14, green: 0.20, blue: 0.34)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
}
