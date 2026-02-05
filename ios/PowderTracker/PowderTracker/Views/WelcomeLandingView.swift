//
//  WelcomeLandingView.swift
//  PowderTracker
//
//  Welcome landing page shown after logout. Offers users the choice to
//  sign back in or continue browsing as a guest.
//

import SwiftUI

struct WelcomeLandingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showSignIn = false
    @State private var animateContent = false
    @State private var snowflakes: [WelcomeSnowflake] = []

    let onContinueBrowsing: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient

                // Animated snowflakes (respects reduce motion)
                if !reduceMotion {
                    snowflakeLayer(in: geometry.size)
                }

                // Main content
                VStack(spacing: 0) {
                    Spacer()

                    // Hero section
                    heroSection

                    Spacer()

                    // Value propositions
                    valuePropositions

                    Spacer()

                    // CTAs
                    ctaSection

                    Spacer()
                        .frame(height: geometry.safeAreaInsets.bottom + 40)
                }
                .padding(.horizontal, .spacingXL)
                .opacity(animateContent ? 1 : 0)
                .offset(y: animateContent ? 0 : 24)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateSnowflakes()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showSignIn) {
            UnifiedAuthView()
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.12, blue: 0.25),
                Color(red: 0.12, green: 0.18, blue: 0.35),
                Color(red: 0.15, green: 0.22, blue: 0.42)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            // Subtle radial gradient for depth
            RadialGradient(
                colors: [
                    Color.pookieCyan.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
        }
    }

    // MARK: - Snowflake Layer

    private func snowflakeLayer(in size: CGSize) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, canvasSize in
                let snowflakeImage = context.resolve(Image(systemName: "snowflake"))

                for snowflake in snowflakes {
                    // Calculate current position based on time
                    let elapsed = timeline.date.timeIntervalSinceReferenceDate
                    let yOffset = (elapsed * snowflake.speed).truncatingRemainder(dividingBy: Double(canvasSize.height + 50))
                    let xDrift = sin(elapsed * snowflake.driftSpeed + snowflake.driftPhase) * snowflake.driftAmount

                    let x = snowflake.x + xDrift
                    let y = (snowflake.y + yOffset).truncatingRemainder(dividingBy: canvasSize.height + 50) - 50

                    var innerContext = context
                    innerContext.opacity = snowflake.opacity

                    innerContext.draw(
                        snowflakeImage,
                        at: CGPoint(x: x, y: y)
                    )
                }
            }
        }
    }

    private func generateSnowflakes() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        snowflakes = (0..<25).map { _ in
            WelcomeSnowflake(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight),
                size: CGFloat.random(in: 8...16),
                opacity: Double.random(in: 0.2...0.5),
                speed: Double.random(in: 15...40),
                driftAmount: CGFloat.random(in: 10...30),
                driftSpeed: Double.random(in: 0.3...0.8),
                driftPhase: Double.random(in: 0...Double.pi * 2)
            )
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: .spacingL) {
            // Animated app icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.pookieCyan.opacity(0.4), Color.clear],
                            center: .center,
                            startRadius: 70,
                            endRadius: 140
                        )
                    )
                    .frame(width: 280, height: 280)

                // Icon background
                RoundedRectangle(cornerRadius: 44, style: .continuous)
                    .fill(LinearGradient.pookieBSnow)
                    .frame(width: 180, height: 180)
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 16)

                // Snowflake icon
                Image(systemName: "snowflake")
                    .font(.system(size: 90, weight: .medium))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5))
            }

            VStack(spacing: .spacingS) {
                Text("PowderTracker")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("You've been signed out")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Value Propositions

    private var valuePropositions: some View {
        VStack(spacing: .spacingM) {
            valueRow(icon: "gauge.with.dots.needle.67percent", text: "Real-time PowderScore for every resort")
            valueRow(icon: "bell.badge.fill", text: "Alerts when your mountains get fresh snow")
            valueRow(icon: "person.3.fill", text: "Plan trips and coordinate with friends")
        }
        .padding(.spacingL)
        .background {
            RoundedRectangle(cornerRadius: .cornerRadiusHero, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
        }
    }

    private func valueRow(icon: String, text: String) -> some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LinearGradient.pookieBSnow)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))

            Spacer()
        }
    }

    // MARK: - CTA Section

    private var ctaSection: some View {
        VStack(spacing: .spacingM) {
            // Primary CTA - Sign In
            Button {
                HapticFeedback.medium.trigger()
                showSignIn = true
            } label: {
                HStack(spacing: .spacingS) {
                    Image(systemName: "person.fill")
                    Text("Sign In")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingM)
                .background(LinearGradient.pookieBSnow)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
            }
            .accessibilityIdentifier("welcome_sign_in_button")

            // Secondary CTA - Browse as Guest
            Button {
                HapticFeedback.light.trigger()
                onContinueBrowsing()
            } label: {
                HStack(spacing: .spacingS) {
                    Image(systemName: "mountain.2.fill")
                    Text("Browse Conditions")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, .spacingM)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: .cornerRadiusButton, style: .continuous)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                }
            }
            .accessibilityIdentifier("welcome_browse_button")

            // Subtle hint
            Text("You can explore mountains and conditions without an account")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.top, .spacingS)
        }
    }
}

// MARK: - Snowflake Model

private struct WelcomeSnowflake: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double
    let driftAmount: CGFloat
    let driftSpeed: Double
    let driftPhase: Double
}

// MARK: - Preview

#Preview("Welcome Landing") {
    WelcomeLandingView(
        onContinueBrowsing: { print("Continue browsing") },
        onSignIn: { print("Sign in") }
    )
}

#Preview("Welcome Landing - Light") {
    WelcomeLandingView(
        onContinueBrowsing: {},
        onSignIn: {}
    )
    .preferredColorScheme(.light)
}
