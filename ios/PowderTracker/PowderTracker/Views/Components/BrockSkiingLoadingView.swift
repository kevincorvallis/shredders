//
//  BrockSkiingLoadingView.swift
//  PowderTracker
//
//  Refined loading screen with mountain silhouette, SF Symbol skier,
//  and gentle snowfall. Progress drives the skier across the ridge.
//

import SwiftUI

// MARK: - Snowflake Particle

struct SkiingSnowflake: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var drift: CGFloat
}

// MARK: - BrockSkiingLoadingView

struct BrockSkiingLoadingView: View {
    /// Target progress from data loading (0.0 – 1.0)
    var progress: Double = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Smooth progress
    @State private var displayedProgress: Double = 0

    // Animation states
    @State private var contentOpacity: Double = 0
    @State private var skierBob: CGFloat = 0
    @State private var messageIndex = 0
    @State private var messageOpacity: Double = 0

    // Particles
    @State private var snowflakes: [SkiingSnowflake] = []
    @State private var screenSize: CGSize = .zero

    // 60 FPS timer
    private let frameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    // Tips — alternate between flavor and useful hints
    private let tips = [
        "Loading your mountains...",
        "Star your favorites for quick access",
        "Pull down on any tab to refresh",
        "Checking conditions...",
        "Compare resorts on the Map tab",
        "Tap a pin to preview conditions",
        "Create events to rally your crew",
        "Fetching snow data...",
        "Scores combine snow, lifts, and weather",
        "Set alerts for powder day notifications",
        "Today tab shows your top pick each morning",
        "Almost ready..."
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundGradient
                mountainScene
                if !reduceMotion { snowLayer }
                skierLayer
                contentLayer
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                screenSize = geometry.size
                if reduceMotion {
                    contentOpacity = 1
                    displayedProgress = progress
                } else {
                    generateSnowflakes()
                    startAnimations()
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                screenSize = newSize
            }
            .onReceive(frameTimer) { _ in
                advanceProgress()
                guard !reduceMotion else { return }
                updateSnowflakes()
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.06, blue: 0.14),
                Color(red: 0.08, green: 0.10, blue: 0.22),
                Color(red: 0.12, green: 0.16, blue: 0.30)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay {
            // Subtle ambient glow in upper area
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.35, green: 0.15, blue: 0.55).opacity(0.25),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 400)
                .offset(y: -screenSize.height * 0.2)
                .blur(radius: 40)
        }
        .opacity(contentOpacity)
    }

    // MARK: - Mountain Silhouette

    private var mountainScene: some View {
        ZStack {
            // Far range (lighter, more distant)
            mountainPath(
                peaks: [0.18, 0.30, 0.22, 0.35, 0.25, 0.20],
                baseY: 0.58,
                color: Color(red: 0.10, green: 0.12, blue: 0.24)
            )

            // Near range (darker, foreground)
            mountainPath(
                peaks: [0.12, 0.28, 0.15, 0.32, 0.18, 0.10],
                baseY: 0.65,
                color: Color(red: 0.07, green: 0.08, blue: 0.18)
            )

            // Snow line on near range
            mountainSnowCaps
        }
        .opacity(contentOpacity)
    }

    private func mountainPath(peaks: [CGFloat], baseY: CGFloat, color: Color) -> some View {
        Path { path in
            let w = screenSize.width
            let h = screenSize.height
            let base = h * baseY
            let segmentWidth = w / CGFloat(peaks.count - 1)

            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: CGPoint(x: 0, y: base))

            for i in 0..<peaks.count {
                let x = segmentWidth * CGFloat(i)
                let peakY = base - (h * peaks[i])
                if i == 0 {
                    path.addLine(to: CGPoint(x: x, y: peakY))
                } else {
                    let prevX = segmentWidth * CGFloat(i - 1)
                    let midX = (prevX + x) / 2
                    path.addQuadCurve(
                        to: CGPoint(x: x, y: peakY),
                        control: CGPoint(x: midX, y: peakY + h * 0.04)
                    )
                }
            }

            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
        }
        .fill(color)
    }

    private var mountainSnowCaps: some View {
        Canvas { context, size in
            // Subtle snow highlights on peaks
            let peaks: [(x: CGFloat, y: CGFloat, width: CGFloat)] = [
                (0.20, 0.39, 30), (0.40, 0.37, 25), (0.60, 0.36, 35), (0.80, 0.40, 20)
            ]
            for peak in peaks {
                let rect = CGRect(
                    x: size.width * peak.x - peak.width / 2,
                    y: size.height * peak.y,
                    width: peak.width,
                    height: 4
                )
                context.fill(
                    Capsule().path(in: rect),
                    with: .color(.white.opacity(0.15))
                )
            }
        }
    }

    // MARK: - Snow Layer

    private var snowLayer: some View {
        Canvas { context, _ in
            for flake in snowflakes {
                let rect = CGRect(
                    x: flake.x - flake.size / 2,
                    y: flake.y - flake.size / 2,
                    width: flake.size,
                    height: flake.size
                )
                context.fill(
                    Circle().path(in: rect),
                    with: .color(.white.opacity(flake.opacity))
                )
            }
        }
    }

    // MARK: - Skier

    /// Ridge Y position at a given normalized X (0–1)
    private func ridgeY(at t: CGFloat) -> CGFloat {
        let baseY = screenSize.height * 0.58
        // Gentle wave matching the far mountain range
        let wave = sin(t * .pi * 2.5) * screenSize.height * 0.025
        return baseY - wave
    }

    /// Skier X position in absolute coordinates
    private var skierScreenX: CGFloat {
        let margin: CGFloat = 30
        return margin + (screenSize.width - margin * 2) * displayedProgress
    }

    private var skierLayer: some View {
        let x = skierScreenX
        let y = ridgeY(at: displayedProgress) - 24

        return Image(systemName: "figure.skiing.downhill")
            .font(.system(size: 32, weight: .medium))
            .foregroundStyle(.white)
            .shadow(color: Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.5), radius: 10, y: 0)
            .shadow(color: .black.opacity(0.4), radius: 4, y: 3)
            .offset(y: skierBob)
            .position(x: x, y: y)
            .opacity(contentOpacity)
    }

    // MARK: - Content Layer

    private var contentLayer: some View {
        VStack(spacing: 0) {
            Spacer()

            // App title
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    Text("PookieB")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.55, blue: 0.75),
                                    Color(red: 0.85, green: 0.45, blue: 0.80)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Snow")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.5, green: 0.85, blue: 1.0),
                                    .white
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .font(.system(size: 34, weight: .bold, design: .rounded))
            }

            // Tip
            Text(tips[messageIndex])
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .opacity(messageOpacity)
                .padding(.top, 14)
                .frame(height: 36)

            // Progress
            progressBar
                .padding(.top, 20)

            Spacer()
                .frame(height: 64)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(contentOpacity)
    }

    private var progressBar: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.08))
                    .frame(height: 3)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.5, green: 0.85, blue: 1.0),
                                Color(red: 1.0, green: 0.55, blue: 0.75)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, 200 * displayedProgress), height: 3)
            }
            .frame(width: 200)

            Text("\(Int(displayedProgress * 100))%")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .monospacedDigit()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6)) {
            contentOpacity = 1.0
        }

        // Skier bob
        if !reduceMotion {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                skierBob = -4
            }
        }

        // First tip
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            messageOpacity = 1.0
        }

        // Cycle tips
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.25)) {
                    messageOpacity = 0
                }
                try? await Task.sleep(nanoseconds: 280_000_000)
                messageIndex = (messageIndex + 1) % tips.count
                withAnimation(.easeInOut(duration: 0.25)) {
                    messageOpacity = 1.0
                }
            }
        }
    }

    // MARK: - Smooth Progress

    private func advanceProgress() {
        let target = progress
        let current = displayedProgress
        if current < target - 0.0005 {
            let delta = (target - current) * 0.025
            displayedProgress = current + max(delta, 0.0008)
        } else if current != target {
            displayedProgress = target
        }
    }

    // MARK: - Particles

    private func generateSnowflakes() {
        snowflakes = (0..<15).map { _ in
            SkiingSnowflake(
                x: CGFloat.random(in: 0...screenSize.width),
                y: CGFloat.random(in: -50...screenSize.height),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.15...0.4),
                speed: Double.random(in: 0.3...0.8),
                drift: CGFloat.random(in: -0.15...0.15)
            )
        }
    }

    private func updateSnowflakes() {
        for i in snowflakes.indices {
            snowflakes[i].y += CGFloat(snowflakes[i].speed)
            snowflakes[i].x += snowflakes[i].drift + CGFloat(sin(snowflakes[i].y / 120) * 0.15)

            if snowflakes[i].y > screenSize.height + 20 {
                snowflakes[i].y = -10
                snowflakes[i].x = CGFloat.random(in: 0...screenSize.width)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BrockSkiingLoadingView(progress: 0.65)
}
