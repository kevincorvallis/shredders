import SwiftUI

// MARK: - Snow Particle Effect

/// A subtle snow particle animation overlay for powder day emphasis
struct SnowParticleEffect: View {
    let particleCount: Int
    let intensity: Double

    @State private var particles: [ChartSnowParticle] = []

    init(particleCount: Int = 12, intensity: Double = 0.5) {
        self.particleCount = particleCount
        self.intensity = min(1.0, max(0.0, intensity))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    snowflakeView(particle: particle, containerSize: geometry.size)
                }
            }
            .onAppear {
                initializeParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func initializeParticles(in size: CGSize) {
        guard size.width > 0 && size.height > 0 else { return }
        particles = (0..<particleCount).map { index in
            ChartSnowParticle(
                id: index,
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -20...size.height),
                size: CGFloat.random(in: 3...6),
                opacity: Double.random(in: 0.3...0.7) * intensity,
                speed: Double.random(in: 15...30),
                wobbleAmount: CGFloat.random(in: 5...15),
                wobbleSpeed: Double.random(in: 1...3),
                delay: Double.random(in: 0...2)
            )
        }
    }

    @ViewBuilder
    private func snowflakeView(particle: ChartSnowParticle, containerSize: CGSize) -> some View {
        ChartSnowflakeAnimatedView(particle: particle, containerSize: containerSize)
    }
}

private struct ChartSnowParticle: Identifiable {
    let id: Int
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
    let speed: Double
    let wobbleAmount: CGFloat
    let wobbleSpeed: Double
    let delay: Double
}

private struct ChartSnowflakeAnimatedView: View {
    let particle: ChartSnowParticle
    let containerSize: CGSize

    @State private var yOffset: CGFloat = 0
    @State private var wobbleOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: particle.size, weight: .ultraLight))
            .foregroundStyle(.white.opacity(particle.opacity))
            .shadow(color: .cyan.opacity(0.3), radius: 2)
            .position(x: particle.x + wobbleOffset, y: particle.y + yOffset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                let fallDuration = (Double(containerSize.height) + 40) / particle.speed
                withAnimation(.linear(duration: fallDuration).delay(particle.delay).repeatForever(autoreverses: false)) {
                    yOffset = containerSize.height + 20 - particle.y
                }
                withAnimation(.easeInOut(duration: particle.wobbleSpeed).delay(particle.delay).repeatForever(autoreverses: true)) {
                    wobbleOffset = particle.wobbleAmount
                }
                withAnimation(.linear(duration: 8).delay(particle.delay).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
