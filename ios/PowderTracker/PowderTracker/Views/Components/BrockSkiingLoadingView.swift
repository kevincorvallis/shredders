//
//  BrockSkiingLoadingView.swift
//  PowderTracker
//
//  A beautiful animated loading screen featuring Brock skiing through powder.
//  Reuses the aurora and snowflake effects from PookieBSnowIntroView.
//  Used as the app's launch loading screen while initial data loads.
//

import SwiftUI

// MARK: - Skiing Snowflake Particle

struct SkiingSnowflake: Identifiable {
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

// MARK: - BrockSkiingLoadingView

struct BrockSkiingLoadingView: View {
    /// Binding to actual loading progress (0.0 – 1.0)
    var progress: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation states
    @State private var showBackground = false
    @State private var brockX: CGFloat = -100
    @State private var brockY: CGFloat = 0
    @State private var brockRotation: Double = 0
    @State private var skiTrailOpacity: Double = 0
    @State private var messageIndex = 0
    @State private var messageOpacity: Double = 0

    // Aurora layers
    @State private var auroraWave1: CGFloat = 0
    @State private var auroraWave2: CGFloat = 0
    @State private var auroraOpacity: Double = 0

    // Particles
    @State private var snowflakes: [SkiingSnowflake] = []
    @State private var screenSize: CGSize = .zero

    // 60 FPS timer for smooth particles
    private let particleTimer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()

    // Fun loading messages
    private let loadingMessages = [
        "Brock is sniffing out fresh powder...",
        "Checking the slopes...",
        "Tracking fresh tracks...",
        "Fetching today's conditions...",
        "Almost there! *wags tail*"
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Layer 1: Deep winter night gradient
                backgroundGradient

                // Layer 2: Aurora borealis
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

                // Layer 5: Ski trail
                if !reduceMotion {
                    skiTrailLayer
                }

                // Layer 6: Brock skiing
                brockSkiingLayer

                // Layer 7: Loading message
                loadingMessageLayer
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                screenSize = geometry.size
                if reduceMotion {
                    showAllContentInstantly()
                } else {
                    startAnimations()
                    generateParticles()
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                screenSize = newSize
            }
            .onReceive(particleTimer) { _ in
                guard !reduceMotion else { return }
                updateParticles()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background Gradient

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.08, blue: 0.18),
                Color(red: 0.10, green: 0.14, blue: 0.26),
                Color(red: 0.14, green: 0.20, blue: 0.34),
                Color(red: 0.10, green: 0.16, blue: 0.28)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .opacity(showBackground ? 1 : 0)
    }

    // MARK: - Aurora Layers

    private var auroraLayers: some View {
        ZStack {
            // Purple base aurora
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

            // Pink shimmer
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.4, blue: 0.7).opacity(0.4),
                            Color(red: 0.95, green: 0.55, blue: 0.75).opacity(0.25),
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

            // Cyan accent
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 0.85, blue: 1.0).opacity(0.3),
                            .clear
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 180
                    )
                )
                .frame(width: 350, height: 180)
                .blur(radius: 35)
                .offset(y: 220)
                .opacity(auroraOpacity * 0.8)
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
        Canvas { context, _ in
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

    // MARK: - Ski Trail Layer

    private var skiTrailLayer: some View {
        Path { path in
            let startY = screenSize.height * 0.55
            let midX = screenSize.width * 0.5

            // Wavy ski trail
            path.move(to: CGPoint(x: -50, y: startY + 30))
            path.addCurve(
                to: CGPoint(x: midX, y: startY),
                control1: CGPoint(x: screenSize.width * 0.15, y: startY + 50),
                control2: CGPoint(x: screenSize.width * 0.35, y: startY - 20)
            )
            path.addCurve(
                to: CGPoint(x: screenSize.width + 50, y: startY + 20),
                control1: CGPoint(x: screenSize.width * 0.65, y: startY + 30),
                control2: CGPoint(x: screenSize.width * 0.85, y: startY - 10)
            )
        }
        .stroke(
            LinearGradient(
                colors: [.clear, .white.opacity(0.3), .white.opacity(0.5), .white.opacity(0.3), .clear],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 3, lineCap: .round)
        )
        .opacity(skiTrailOpacity)
    }

    // MARK: - Brock Skiing Layer

    private var brockSkiingLayer: some View {
        ZStack {
            // Snow spray effect
            if !reduceMotion {
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(.white.opacity(0.4))
                        .frame(width: CGFloat.random(in: 4...10), height: CGFloat.random(in: 4...10))
                        .offset(
                            x: brockX - CGFloat(15 + i * 8),
                            y: screenSize.height * 0.55 + CGFloat.random(in: -10...10)
                        )
                        .blur(radius: 2)
                }
            }

            // Brock on skis
            VStack(spacing: -8) {
                Text("🐕")
                    .font(.system(size: 60))

                // Skis
                HStack(spacing: 2) {
                    Text("🎿")
                        .font(.system(size: 20))
                        .rotationEffect(.degrees(-15))
                }
                .offset(y: -20)
            }
            .rotationEffect(.degrees(brockRotation))
            .offset(x: brockX, y: screenSize.height * 0.55 + brockY)
            .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
    }

    // MARK: - Loading Message Layer

    private var loadingMessageLayer: some View {
        VStack {
            Spacer()

            VStack(spacing: 16) {
                // App title
                HStack(spacing: 0) {
                    Text("PookieB")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.55, blue: 0.75),
                                    Color(red: 0.9, green: 0.45, blue: 0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Snow")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.45, green: 0.85, blue: 1.0),
                                    .white
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.purple.opacity(0.3), radius: 15, y: 5)

                // Loading message
                Text(loadingMessages[messageIndex])
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .opacity(messageOpacity)

                // Progress bar
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Track
                            Capsule()
                                .fill(.white.opacity(0.15))
                                .frame(height: 6)

                            // Fill
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.45, green: 0.85, blue: 1.0),
                                            Color(red: 1.0, green: 0.55, blue: 0.75)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, geo.size.width * progress), height: 6)
                                .animation(.smooth(duration: 0.4), value: progress)
                        }
                    }
                    .frame(height: 6)
                    .frame(maxWidth: 220)

                    // Percentage text
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .monospacedDigit()
                        .animation(.smooth(duration: 0.3), value: progress)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 80)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Animation Sequence

    private func startAnimations() {
        // Background fade in
        withAnimation(.smooth(duration: 0.4)) {
            showBackground = true
        }

        // Aurora fade in
        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            auroraOpacity = 1.0
        }

        // Start aurora waves
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            auroraWave1 = 40
        }
        withAnimation(.easeInOut(duration: 6).repeatForever(autoreverses: true)) {
            auroraWave2 = -30
        }

        // Show ski trail
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            skiTrailOpacity = 1.0
        }

        // Animate Brock skiing across screen
        startSkiingAnimation()

        // Loading message
        withAnimation(.easeOut(duration: 0.3).delay(0.3)) {
            messageOpacity = 1.0
        }

        // Cycle loading messages
        startMessageCycle()
    }

    private func startSkiingAnimation() {
        // Position Brock at start
        brockX = -100

        // Ski across screen with slight bobbing
        withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: false)) {
            brockX = screenSize.width + 100
        }

        // Slight rotation for dynamic feel
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            brockRotation = 5
        }

        // Up and down bobbing
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            brockY = -8
        }
    }

    private func startMessageCycle() {
        // Cycle through messages every 2 seconds
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [self] timer in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageOpacity = 0
                }

                try? await Task.sleep(nanoseconds: 300_000_000)
                messageIndex = (messageIndex + 1) % loadingMessages.count
                withAnimation(.easeInOut(duration: 0.3)) {
                    messageOpacity = 1.0
                }
            }
        }
    }

    private func showAllContentInstantly() {
        showBackground = true
        auroraOpacity = 1.0
        skiTrailOpacity = 1.0
        brockX = screenSize.width / 2 - 30
        messageOpacity = 1.0
    }

    // MARK: - Particle System

    private func generateParticles() {
        snowflakes = (0..<25).map { _ in
            SkiingSnowflake(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: -100...screenSize.height),
                size: CGFloat.random(in: 10...18),
                opacity: Double.random(in: 0.3...0.6),
                speed: Double.random(in: 0.6...1.5),
                drift: CGFloat.random(in: -0.2...0.2),
                rotationSpeed: Double.random(in: -1.5...1.5)
            )
        }
    }

    private func updateParticles() {
        for i in snowflakes.indices {
            snowflakes[i].y += CGFloat(snowflakes[i].speed)
            snowflakes[i].x += snowflakes[i].drift + CGFloat(sin(snowflakes[i].y / 80) * 0.2)
            snowflakes[i].rotation += snowflakes[i].rotationSpeed

            if snowflakes[i].y > screenSize.height + 50 {
                snowflakes[i].y = -30
                snowflakes[i].x = CGFloat.random(in: 0...screenSize.width)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BrockSkiingLoadingView(progress: 0.65)
}
