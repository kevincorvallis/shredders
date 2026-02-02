//
//  PookieBSnowIntroView.swift
//  PowderTracker
//
//  Production-level welcome experience for first-time users of PookieBSnow.
//  Named after Pookie (Beryl) and their mini golden doodle Brock - the stinky little boy who loves snow!
//
//  Design principles:
//  - Accessibility-first (respects reduce motion)
//  - 60 FPS particle animations
//  - Modern .bouncy/.smooth animation presets
//  - Multi-layered aurora for luxury depth
//  - Haptic feedback for emotional connection
//  - Compressed timeline for snappy interactivity
//

import SwiftUI
import UIKit

// MARK: - Particle Types

struct PookieBSnowflake: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var drift: CGFloat
    var rotationSpeed: Double
    var rotation: Double = 0
}

struct FloatingHeart: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var floatOffset: CGFloat = 0
}

// MARK: - PookieBSnow Intro View

struct PookieBSnowIntroView: View {
    @Binding var showIntro: Bool

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var showBackground = false
    @State private var showBrock = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showMadeWith = false
    @State private var showTapHint = false
    @State private var tapHintPulse = false

    // Brock micro-animations
    @State private var brockBreath: CGFloat = 1.0
    @State private var brockBounce: CGFloat = 0
    @State private var brockTilt: Double = 0
    @State private var brockBlink = false
    @State private var scarfWave = false
    @State private var showSpeechBubble = false

    // Aurora layers
    @State private var auroraWave1: CGFloat = 0
    @State private var auroraWave2: CGFloat = 0
    @State private var auroraWave3: CGFloat = 0
    @State private var auroraOpacity: Double = 0

    // Particles
    @State private var snowflakes: [PookieBSnowflake] = []
    @State private var hearts: [FloatingHeart] = []
    @State private var screenSize: CGSize = UIScreen.main.bounds.size

    // Timer reference for cleanup (prevents memory leak)
    @State private var heartTimer: Timer?

    // 60 FPS timer for smooth particles
    private let particleTimer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Deep winter night gradient
                backgroundGradient

                // Layer 2: Multi-layered aurora borealis
                if !reduceMotion {
                    auroraLayers
                }

                // Layer 3: Twinkling stars
                if !reduceMotion {
                    starsLayer
                }

                // Layer 4: Falling snowflakes
                if !reduceMotion {
                    snowflakesLayer
                }

                // Layer 5: Floating hearts
                if !reduceMotion {
                    heartsLayer
                }

                // Layer 6: Main content
                mainContent
            }
            .onAppear {
                screenSize = geometry.size
                if reduceMotion {
                    showAllContentInstantly()
                } else {
                    startAnimationSequence()
                    generateParticles()
                }
            }
            .onReceive(particleTimer) { _ in
                guard showIntro && !reduceMotion else { return }
                updateParticles()
            }
        }
        .ignoresSafeArea()
        .onTapGesture {
            dismissWithHaptic()
        }
        .onDisappear {
            // Clean up timer to prevent memory leak
            heartTimer?.invalidate()
            heartTimer = nil
        }
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.08, blue: 0.18),   // Deep space
                Color(red: 0.10, green: 0.14, blue: 0.26),   // Midnight
                Color(red: 0.14, green: 0.20, blue: 0.34),   // Twilight
                Color(red: 0.10, green: 0.16, blue: 0.28)    // Deep purple hint
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(showBackground ? 1 : 0)
    }

    // MARK: - Aurora Layers (Luxury Multi-Layer Effect)

    private var auroraLayers: some View {
        ZStack {
            // Layer 1: Deep purple base aurora
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.5, green: 0.2, blue: 0.8).opacity(0.35),
                            Color(red: 0.3, green: 0.1, blue: 0.6).opacity(0.2),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 220
                    )
                )
                .frame(width: 500, height: 280)
                .blur(radius: 60)
                .offset(x: auroraWave1, y: -180)
                .opacity(auroraOpacity)

            // Layer 2: Pink shimmer (PookieB signature)
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.4),
                            Color(red: 0.95, green: 0.55, blue: 0.75).opacity(0.25),
                            Color(red: 0.9, green: 0.6, blue: 0.8).opacity(0.15),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 420, height: 200)
                .blur(radius: 45)
                .offset(x: -auroraWave2 * 0.7, y: -120)
                .opacity(auroraOpacity * 0.9)

            // Layer 3: Cyan accent glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 0.85, blue: 1.0).opacity(0.3),
                            Color(red: 0.4, green: 0.75, blue: 0.95).opacity(0.15),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 180)
                .blur(radius: 35)
                .offset(x: auroraWave3 * 0.5, y: 220)
                .opacity(auroraOpacity * 0.8)

            // Layer 4: Rose gold metallic shimmer overlay
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.78, blue: 0.69).opacity(0.12),
                            Color(red: 0.95, green: 0.65, blue: 0.55).opacity(0.08),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 600, height: 300)
                .blur(radius: 50)
                .blendMode(.overlay)
                .offset(y: -100)
                .opacity(auroraOpacity * 0.6)
        }
    }

    // MARK: - Stars Layer

    private var starsLayer: some View {
        Canvas { context, size in
            for i in 0..<40 {
                let x = CGFloat((i * 67 + 13) % Int(size.width))
                let y = CGFloat((i * 43 + 7) % Int(size.height * 0.5))
                let starSize = CGFloat((i % 4) + 1)
                let opacity = Double((i % 6) + 2) / 10.0

                let rect = CGRect(x: x, y: y, width: starSize, height: starSize)
                context.fill(Circle().path(in: rect), with: .color(.white.opacity(opacity)))
            }
        }
        .opacity(showBackground ? 1 : 0)
    }

    // MARK: - Snowflakes Layer

    private var snowflakesLayer: some View {
        Canvas { context, size in
            for flake in snowflakes {
                let symbol = context.resolveSymbol(id: "snowflake")!
                context.opacity = flake.opacity
                context.translateBy(x: flake.x, y: flake.y)
                context.rotate(by: .degrees(flake.rotation))
                context.scaleBy(x: flake.size / 20, y: flake.size / 20)
                context.draw(symbol, at: .zero)
                context.transform = .identity
            }
        } symbols: {
            Image(systemName: "snowflake")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.white)
                .tag("snowflake")
        }
    }

    // MARK: - Hearts Layer

    private var heartsLayer: some View {
        ForEach(hearts) { heart in
            Image(systemName: "heart.fill")
                .font(.system(size: heart.size))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.pink, .red.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .opacity(heart.opacity)
                .offset(y: heart.floatOffset)
                .position(x: heart.x, y: heart.y)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            // Brock the Golden Doodle
            brockSection

            // Title section
            titleSection

            Spacer(minLength: 40)

            // Made with love
            madeWithLoveSection
                .frame(maxWidth: .infinity)

            // Tap hint
            tapHintSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Brock Section

    private var brockSection: some View {
        ZStack {
            // Warm golden glow behind Brock
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.55).opacity(0.35),
                            Color(red: 1.0, green: 0.75, blue: 0.4).opacity(0.2),
                            Color.orange.opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 130
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(brockBreath)

            // Brock with winter gear
            VStack(spacing: -18) {
                // The good boy himself
                Text("🐕")
                    .font(.system(size: 110))
                    .scaleEffect(x: brockBlink ? 1.0 : 1.0, y: brockBlink ? 0.85 : 1.0)
                    .scaleEffect(brockBreath)
                    .rotationEffect(.degrees(brockTilt))
                    .offset(y: brockBounce)

                // Cozy scarf
                Text("🧣")
                    .font(.system(size: 32))
                    .offset(y: -95)
                    .rotationEffect(.degrees(scarfWave ? -4 : 4))
            }
            .scaleEffect(showBrock ? 1.0 : 0.2)
            .opacity(showBrock ? 1.0 : 0)

            // Speech bubble
            if showSpeechBubble {
                speechBubble
                    .offset(x: 80, y: -70)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
    }

    private var speechBubble: some View {
        HStack(spacing: 4) {
            Text("Woof!")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text("🐾")
                .font(.system(size: 12))
        }
        .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .overlay(
            // Speech bubble tail
            SpeechBubbleTriangle()
                .fill(.white)
                .frame(width: 12, height: 10)
                .rotationEffect(.degrees(180))
                .offset(x: -30, y: 18),
            alignment: .bottom
        )
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            // "Hi, I'm Brock!" intro
            Text("Hi, I'm Brock!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .opacity(showTitle ? 1.0 : 0)
                .offset(y: showTitle ? 0 : 15)

            // Main app title with luxe gradient
            HStack(spacing: 0) {
                Text("PookieB")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.75),
                                Color(red: 0.9, green: 0.45, blue: 0.85),
                                Color(red: 0.75, green: 0.4, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Snow")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.45, green: 0.85, blue: 1.0),
                                Color(red: 0.7, green: 0.92, blue: 1.0),
                                .white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: Color.purple.opacity(0.4), radius: 20, y: 8)
            .shadow(color: Color.cyan.opacity(0.3), radius: 30, y: 12)
            .opacity(showTitle ? 1.0 : 0)
            .offset(y: showTitle ? 0 : 20)

            // Tagline
            Text("Your powder pup's guide to fresh tracks")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 4)
                .opacity(showSubtitle ? 1.0 : 0)
                .offset(y: showSubtitle ? 0 : 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    // MARK: - Made With Love Section

    private var madeWithLoveSection: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Text("Made with")
                    .font(.caption)
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundStyle(.pink)
                Text("by Kevin & Beryl")
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.45))

            Text("(and lots of belly rubs for Brock)")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.35))
                .italic()
        }
        .opacity(showMadeWith ? 1.0 : 0)
        .padding(.bottom, 16)
    }

    // MARK: - Tap Hint Section

    private var tapHintSection: some View {
        Text("tap anywhere to continue")
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(tapHintPulse ? 0.5 : 0.3))
            .padding(.bottom, 50)
            .opacity(showTapHint ? 1.0 : 0)
    }

    // MARK: - Animation Sequence (Production-Level Choreography)

    private func startAnimationSequence() {
        // Haptic: Light tap on entry
        HapticFeedback.light.trigger()

        // Phase 1: Background (instant, smooth)
        withAnimation(.smooth(duration: 0.6)) {
            showBackground = true
        }

        // Phase 1b: Aurora fades in
        withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
            auroraOpacity = 1.0
        }

        // Start continuous aurora waves
        startAuroraAnimations()

        // Phase 2: Brock entrance (bouncy for playfulness)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            HapticFeedback.medium.trigger()
            withAnimation(.bouncy(duration: 0.8, extraBounce: 0.2)) {
                showBrock = true
            }
        }

        // Phase 2b: Start Brock micro-animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            startBrockMicroAnimations()
        }

        // Phase 3: Title appears (smooth, elegant)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.smooth(duration: 0.6)) {
                showTitle = true
            }
        }

        // Phase 3b: Speech bubble pops in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            HapticFeedback.light.trigger()
            withAnimation(.bouncy(duration: 0.5, extraBounce: 0.15)) {
                showSpeechBubble = true
            }
        }

        // Phase 4: Subtitle
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.smooth(duration: 0.5)) {
                showSubtitle = true
            }
        }

        // Phase 5: Made with love (subtle)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.easeOut(duration: 0.4)) {
                showMadeWith = true
            }
        }

        // Phase 6: Tap hint with pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.3)) {
                showTapHint = true
            }
            // Pulse animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                tapHintPulse = true
            }
        }

        // Auto-dismiss after 4.5 seconds (gives time to enjoy)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            guard showIntro else { return }
            dismissWithHaptic()
        }
    }

    private func startAuroraAnimations() {
        // Wave 1: Slow drift
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            auroraWave1 = 40
        }
        // Wave 2: Medium speed, opposite direction
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            auroraWave2 = -30
        }
        // Wave 3: Faster, subtle
        withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            auroraWave3 = 25
        }
    }

    private func startBrockMicroAnimations() {
        // Breathing: Subtle scale
        withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
            brockBreath = 1.04
        }

        // Gentle bounce
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            brockBounce = -6
        }

        // Playful tilt
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            brockTilt = 3
        }

        // Scarf wave
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            scarfWave = true
        }

        // Random blinking
        startBlinkingAnimation()
    }

    private func startBlinkingAnimation() {
        // Blink every 3-5 seconds
        let blinkDelay = Double.random(in: 3...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + blinkDelay) {
            guard showIntro else { return }

            // Blink down
            withAnimation(.linear(duration: 0.08)) {
                brockBlink = true
            }

            // Blink up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.linear(duration: 0.08)) {
                    brockBlink = false
                }
            }

            // Schedule next blink
            startBlinkingAnimation()
        }
    }

    // MARK: - Reduce Motion: Show All Content Instantly

    private func showAllContentInstantly() {
        showBackground = true
        auroraOpacity = 1.0
        showBrock = true
        showTitle = true
        showSpeechBubble = true
        showSubtitle = true
        showMadeWith = true
        showTapHint = true

        // Still auto-dismiss after viewing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            guard showIntro else { return }
            showIntro = false
        }
    }

    // MARK: - Particle System (60 FPS)

    private func generateParticles() {
        // Snowflakes
        snowflakes = (0..<30).map { _ in
            PookieBSnowflake(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: -100...screenSize.height),
                size: CGFloat.random(in: 12...22),
                opacity: Double.random(in: 0.3...0.7),
                speed: Double.random(in: 0.8...2.0),
                drift: CGFloat.random(in: -0.3...0.3),
                rotationSpeed: Double.random(in: -2...2)
            )
        }

        // Initial hearts
        generateHeart()

        // Generate new hearts periodically (store reference for cleanup)
        heartTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
            guard showIntro else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                generateHeart()
                HapticFeedback.light.trigger()
            }
        }
    }

    private func generateHeart() {
        let centerX = screenSize.width / 2
        let brockY = screenSize.height * 0.35

        let heart = FloatingHeart(
            x: centerX + CGFloat.random(in: -60...60),
            y: brockY + CGFloat.random(in: -20...20),
            size: CGFloat.random(in: 12...18),
            opacity: 0.9
        )
        hearts.append(heart)

        // Animate and remove after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            hearts.removeAll { $0.id == heart.id }
        }
    }

    private func updateParticles() {
        // Update snowflakes (60 FPS smooth)
        for i in snowflakes.indices {
            snowflakes[i].y += CGFloat(snowflakes[i].speed)
            snowflakes[i].x += snowflakes[i].drift + CGFloat(sin(snowflakes[i].y / 80) * 0.3)
            snowflakes[i].rotation += snowflakes[i].rotationSpeed

            // Reset when off screen
            if snowflakes[i].y > screenSize.height + 50 {
                snowflakes[i].y = -30
                snowflakes[i].x = CGFloat.random(in: 0...screenSize.width)
            }
        }

        // Update hearts (float up and fade)
        for i in hearts.indices {
            hearts[i].floatOffset -= 0.5
            hearts[i].opacity = max(0, hearts[i].opacity - 0.005)
        }
    }

    // MARK: - Dismiss

    private func dismissWithHaptic() {
        // Clean up timer before dismissing
        heartTimer?.invalidate()
        heartTimer = nil

        HapticFeedback.selection.trigger()
        withAnimation(.smooth(duration: 0.35)) {
            showIntro = false
        }
    }
}

// MARK: - Speech Bubble Triangle Shape

private struct SpeechBubbleTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    PookieBSnowIntroView(showIntro: .constant(true))
}
