import SwiftUI

struct Snowflake: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: Double
    var drift: CGFloat
}

struct IntroView: View {
    @Binding var showIntro: Bool

    @State private var showLogo = false
    @State private var showMountain = false
    @State private var showSnowCap = false
    @State private var showRing = false
    @State private var ringProgress: CGFloat = 0
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showLoadingDots = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var snowflakes: [Snowflake] = []
    @State private var starOpacities: [Double] = Array(repeating: 0.3, count: 20)

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.16),
                    Color(red: 0.06, green: 0.09, blue: 0.16),
                    Color(red: 0.1, green: 0.12, blue: 0.21)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(.white)
                    .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                    .opacity(starOpacities[i])
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...(UIScreen.main.bounds.height * 0.5))
                    )
            }

            // Snowflakes
            ForEach(snowflakes) { flake in
                Text("❄")
                    .font(.system(size: flake.size))
                    .foregroundColor(.white)
                    .opacity(flake.opacity)
                    .position(x: flake.x, y: flake.y)
            }

            // Aurora effect at bottom
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.05),
                            Color.green.opacity(0.08),
                            .clear
                        ],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: UIScreen.main.bounds.width * 1.5, height: 300)
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
                .opacity(pulseScale > 1.1 ? 0.8 : 0.5)

            VStack(spacing: 0) {
                Spacer()

                // Logo Container
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.green.opacity(0.15), .clear],
                                center: .center,
                                startRadius: 80,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(pulseScale)

                    // Main logo
                    ZStack {
                        // Background circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.05, green: 0.29, blue: 0.43),
                                        Color(red: 0.01, green: 0.41, blue: 0.63)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 180, height: 180)
                            .scaleEffect(showLogo ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showLogo)

                        // Back mountain
                        MountainShape(variant: .back)
                            .fill(Color(red: 0.12, green: 0.23, blue: 0.37).opacity(0.6))
                            .frame(width: 140, height: 70)
                            .offset(y: showMountain ? 20 : 70)
                            .opacity(showMountain ? 1 : 0)
                            .animation(.easeOut(duration: 0.6).delay(0.2), value: showMountain)

                        // Main mountain
                        MountainShape(variant: .main)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.12, green: 0.25, blue: 0.69),
                                        Color(red: 0.23, green: 0.51, blue: 0.96)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 160, height: 85)
                            .offset(y: showMountain ? 25 : 90)
                            .opacity(showMountain ? 1 : 0)
                            .animation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.3), value: showMountain)

                        // Snow cap
                        SnowCapShape()
                            .fill(
                                LinearGradient(
                                    colors: [.white, Color(red: 0.88, green: 0.95, blue: 0.99)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 60, height: 35)
                            .offset(y: -12)
                            .scaleEffect(showSnowCap ? 1 : 0.5)
                            .opacity(showSnowCap ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6), value: showSnowCap)

                        // Score ring background
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 3)
                            .frame(width: 170, height: 170)
                            .opacity(showRing ? 1 : 0)

                        // Animated score ring
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                Color.green,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 170, height: 170)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: .green.opacity(0.5), radius: 4)

                        // Ring end dot
                        if ringProgress > 0.2 {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .shadow(color: .green.opacity(0.8), radius: 6)
                                .offset(x: 85 * cos(CGFloat(ringProgress * .pi * 2 - .pi / 2)),
                                       y: 85 * sin(CGFloat(ringProgress * .pi * 2 - .pi / 2)))
                                .opacity(showRing ? 1 : 0)
                        }
                    }

                    // Powder badge
                    HStack(spacing: 4) {
                        Text("9.2")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(Color.green)
                        Text("POWDER")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.green.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .offset(x: 80, y: 0)
                    .scaleEffect(showRing && ringProgress > 0.2 ? 1 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.5), value: ringProgress)
                }

                // Title
                VStack(spacing: 8) {
                    Text("SHREDDERS")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, Color(red: 0.88, green: 0.95, blue: 1.0), .white],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
                        .animation(.easeOut(duration: 0.6).delay(0.8), value: showTitle)

                    Text("AI-POWERED POWDER INTELLIGENCE")
                        .font(.system(size: 12, weight: .medium))
                        .tracking(2)
                        .foregroundColor(Color(red: 0.53, green: 0.75, blue: 0.87).opacity(0.7))
                        .opacity(showSubtitle ? 1 : 0)
                        .animation(.easeOut(duration: 0.5).delay(1.2), value: showSubtitle)
                }
                .padding(.top, 30)

                // Loading dots
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color(red: 0.05, green: 0.65, blue: 0.91))
                            .frame(width: 8, height: 8)
                            .scaleEffect(showLoadingDots ? (i == Int(Date().timeIntervalSince1970 * 2) % 3 ? 1.4 : 1.0) : 0)
                            .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15), value: showLoadingDots)
                    }
                }
                .padding(.top, 40)
                .opacity(showLoadingDots ? 1 : 0)

                Text("Loading conditions...")
                    .font(.system(size: 12))
                    .foregroundColor(Color.gray.opacity(0.6))
                    .padding(.top, 12)
                    .opacity(showLoadingDots ? 1 : 0)

                Spacer()

                // Skip hint
                Text("tap anywhere to skip")
                    .font(.system(size: 11))
                    .foregroundColor(Color.gray.opacity(0.4))
                    .padding(.bottom, 40)
                    .opacity(showLoadingDots ? 1 : 0)
                    .animation(.easeIn(duration: 0.5).delay(2.5), value: showLoadingDots)
            }
        }
        .onTapGesture {
            withAnimation(.easeOut(duration: 0.3)) {
                showIntro = false
            }
        }
        .onAppear {
            startAnimations()
            generateSnowflakes()
        }
        .onReceive(timer) { _ in
            guard showIntro else { return }
            updateSnowflakes()
            updateStars()
        }
    }

    private func startAnimations() {
        // Staggered animations
        withAnimation { showLogo = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            guard showIntro else { return }
            withAnimation { showMountain = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [self] in
            guard showIntro else { return }
            withAnimation { showSnowCap = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
            guard showIntro else { return }
            withAnimation { showRing = true }
            withAnimation(.easeInOut(duration: 1.2)) {
                ringProgress = 0.25
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [self] in
            guard showIntro else { return }
            withAnimation { showTitle = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [self] in
            guard showIntro else { return }
            withAnimation { showSubtitle = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [self] in
            guard showIntro else { return }
            withAnimation { showLoadingDots = true }
        }

        // Pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseScale = 1.2
        }

        // Auto dismiss after 1.0 second (Apple design principle: get out of the way quickly)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
            guard showIntro else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                showIntro = false
            }
        }
    }

    private func generateSnowflakes() {
        let screenWidth = UIScreen.main.bounds.width
        snowflakes = (0..<40).map { _ in
            Snowflake(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -100...0),
                size: CGFloat.random(in: 8...16),
                opacity: Double.random(in: 0.3...0.8),
                speed: Double.random(in: 1...3),
                drift: CGFloat.random(in: -1...1)
            )
        }
    }

    private func updateSnowflakes() {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        for i in snowflakes.indices {
            snowflakes[i].y += CGFloat(snowflakes[i].speed)
            snowflakes[i].x += snowflakes[i].drift + CGFloat(sin(snowflakes[i].y / 50) * 0.5)

            if snowflakes[i].y > screenHeight + 50 {
                snowflakes[i].y = -50
                snowflakes[i].x = CGFloat.random(in: 0...screenWidth)
            }
        }
    }

    private func updateStars() {
        for i in starOpacities.indices {
            if Double.random(in: 0...1) > 0.98 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    starOpacities[i] = Double.random(in: 0.2...0.9)
                }
            }
        }
    }
}

// Mountain shapes
struct MountainShape: Shape {
    enum Variant {
        case main, back
    }
    let variant: Variant

    func path(in rect: CGRect) -> Path {
        var path = Path()

        switch variant {
        case .main:
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.4))
            path.addLine(to: CGPoint(x: rect.width * 0.4, y: rect.height * 0.55))
            path.addLine(to: CGPoint(x: rect.width * 0.5, y: 0))
            path.addLine(to: CGPoint(x: rect.width * 0.6, y: rect.height * 0.55))
            path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.4))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        case .back:
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.width * 0.35, y: rect.height * 0.2))
            path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.5))
            path.addLine(to: CGPoint(x: rect.width * 0.65, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.closeSubpath()
        }

        return path
    }
}

struct SnowCapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.15, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: 0))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.4))
        path.addLine(to: CGPoint(x: rect.width * 0.85, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.7, y: rect.height * 0.8))
        path.addLine(to: CGPoint(x: rect.width * 0.55, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.width * 0.45, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.8))
        path.closeSubpath()
        return path
    }
}

#Preview {
    IntroView(showIntro: .constant(true))
}
