//
//  BrockThemedElements.swift
//  PowderTracker
//
//  Golden doodle themed UI elements featuring Brock, the app's mascot.
//  Brock is Kevin & Beryl's mini golden doodle who loves snow!
//
//  Design philosophy:
//  - Playful but not childish
//  - Warm golden tones balanced with snow/ski blues
//  - Subtle animations that respect reduce motion
//  - Accessible with proper VoiceOver labels
//

import SwiftUI

// MARK: - Brock Expressions

/// Different expressions/moods for Brock
enum BrockExpression: String, CaseIterable {
    case happy = "Happy"
    case excited = "Excited"
    case sleepy = "Sleepy"
    case curious = "Curious"
    case proud = "Proud"
    case chilly = "Chilly"
    case powderDay = "Powder Day"

    var emoji: String {
        switch self {
        case .happy: return "🐕"
        case .excited: return "🐕"
        case .sleepy: return "🐕"
        case .curious: return "🐕"
        case .proud: return "🐕"
        case .chilly: return "🐕"
        case .powderDay: return "🐕"
        }
    }

    var accessory: String? {
        switch self {
        case .happy: return nil
        case .excited: return "✨"
        case .sleepy: return "💤"
        case .curious: return "❓"
        case .proud: return "⭐️"
        case .chilly: return "🧣"
        case .powderDay: return "❄️"
        }
    }

    var message: String {
        switch self {
        case .happy: return "Woof!"
        case .excited: return "Let's shred!"
        case .sleepy: return "*yawn*"
        case .curious: return "Sniff sniff..."
        case .proud: return "Good boy!"
        case .chilly: return "Brrr!"
        case .powderDay: return "POWDER!!!"
        }
    }
}

/// Animated Brock expression view
struct BrockExpressionView: View {
    let expression: BrockExpression
    var size: CGFloat = 60
    var showMessage: Bool = true

    @State private var bounce: CGFloat = 0
    @State private var wiggle: Double = 0
    @State private var showAccessory = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Golden glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brockGold.opacity(0.3), .clear],
                            center: .center,
                            startRadius: size * 0.2,
                            endRadius: size * 0.8
                        )
                    )
                    .frame(width: size * 1.5, height: size * 1.5)

                // Brock
                Text(expression.emoji)
                    .font(.system(size: size))
                    .offset(y: bounce)
                    .rotationEffect(.degrees(wiggle))

                // Accessory
                if let accessory = expression.accessory, showAccessory {
                    Text(accessory)
                        .font(.system(size: size * 0.35))
                        .offset(x: size * 0.4, y: -size * 0.3)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Message bubble
            if showMessage {
                Text(expression.message)
                    .font(.caption)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                    )
            }
        }
        .accessibilityLabel("Brock the golden doodle, \(expression.rawValue)")
        .onAppear {
            guard !reduceMotion else {
                showAccessory = true
                return
            }

            // Bounce animation
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                bounce = expression == .excited ? -8 : -4
            }

            // Wiggle for excited
            if expression == .excited {
                withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                    wiggle = 5
                }
            }

            // Show accessory with delay
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.3)) {
                showAccessory = true
            }
        }
    }
}

// MARK: - Paw Print Elements

/// A single paw print shape
struct PawPrintShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let padSize = rect.width * 0.45
        let toeSize = rect.width * 0.2

        // Main pad (larger oval at bottom)
        path.addEllipse(in: CGRect(
            x: rect.midX - padSize / 2,
            y: rect.maxY - padSize * 0.8,
            width: padSize,
            height: padSize * 0.7
        ))

        // Toe beans (4 smaller circles at top)
        let toeY = rect.maxY - padSize - toeSize * 0.3
        let toeSpacing = rect.width * 0.22

        // Left outer toe
        path.addEllipse(in: CGRect(
            x: rect.midX - toeSpacing * 1.5 - toeSize / 2,
            y: toeY - toeSize * 0.3,
            width: toeSize * 0.9,
            height: toeSize
        ))

        // Left inner toe
        path.addEllipse(in: CGRect(
            x: rect.midX - toeSpacing * 0.5 - toeSize / 2,
            y: toeY - toeSize * 0.5,
            width: toeSize,
            height: toeSize * 1.1
        ))

        // Right inner toe
        path.addEllipse(in: CGRect(
            x: rect.midX + toeSpacing * 0.5 - toeSize / 2,
            y: toeY - toeSize * 0.5,
            width: toeSize,
            height: toeSize * 1.1
        ))

        // Right outer toe
        path.addEllipse(in: CGRect(
            x: rect.midX + toeSpacing * 1.5 - toeSize / 2,
            y: toeY - toeSize * 0.3,
            width: toeSize * 0.9,
            height: toeSize
        ))

        return path
    }
}

/// Paw print icon view
struct PawPrintIcon: View {
    var size: CGFloat = 24
    var color: Color = .brockGold

    var body: some View {
        PawPrintShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// Decorative paw print trail
struct PawPrintTrail: View {
    var count: Int = 5
    var spacing: CGFloat = 30
    var size: CGFloat = 16
    var color: Color = .brockGold.opacity(0.3)

    @State private var visiblePaws: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<count, id: \.self) { index in
                PawPrintIcon(size: size, color: color)
                    .rotationEffect(.degrees(Double(index % 2 == 0 ? -15 : 15)))
                    .opacity(reduceMotion ? 1 : (index < visiblePaws ? 1 : 0))
                    .scaleEffect(reduceMotion ? 1 : (index < visiblePaws ? 1 : 0.5))
            }
        }
        .onAppear {
            guard !reduceMotion else {
                visiblePaws = count
                return
            }

            for i in 0..<count {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(i) * 0.15)) {
                    visiblePaws = i + 1
                }
            }
        }
    }
}

/// Paw print section divider
struct PawPrintDivider: View {
    var color: Color = .brockGold.opacity(0.2)

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(color)
                .frame(height: 1)

            PawPrintIcon(size: 12, color: color)

            Rectangle()
                .fill(color)
                .frame(height: 1)
        }
        .padding(.horizontal, .spacingL)
    }
}

// MARK: - Bone Shaped Elements

/// Bone shape for badges and decorations
struct BoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let knobRadius = rect.height * 0.35
        let shaftWidth = rect.width - (knobRadius * 4)
        let shaftHeight = rect.height * 0.35

        // Left knobs
        path.addEllipse(in: CGRect(
            x: 0,
            y: 0,
            width: knobRadius * 2,
            height: knobRadius * 2
        ))
        path.addEllipse(in: CGRect(
            x: 0,
            y: rect.height - knobRadius * 2,
            width: knobRadius * 2,
            height: knobRadius * 2
        ))

        // Right knobs
        path.addEllipse(in: CGRect(
            x: rect.width - knobRadius * 2,
            y: 0,
            width: knobRadius * 2,
            height: knobRadius * 2
        ))
        path.addEllipse(in: CGRect(
            x: rect.width - knobRadius * 2,
            y: rect.height - knobRadius * 2,
            width: knobRadius * 2,
            height: knobRadius * 2
        ))

        // Middle shaft
        path.addRect(CGRect(
            x: knobRadius,
            y: rect.midY - shaftHeight / 2,
            width: shaftWidth + knobRadius * 2,
            height: shaftHeight
        ))

        return path
    }
}

/// Bone-shaped badge for achievements
struct BoneBadge: View {
    let text: String
    var color: Color = .brockGold

    var body: some View {
        ZStack {
            BoneShape()
                .fill(color)
                .frame(width: 80, height: 32)

            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .shadow(color: color.opacity(0.3), radius: 4, y: 2)
    }
}

// MARK: - Brock Tip Tooltip

/// A tooltip with Brock giving helpful tips
struct BrockTip: View {
    let tip: String
    var expression: BrockExpression = .happy

    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Mini Brock
            ZStack {
                Circle()
                    .fill(LinearGradient.brockGolden)
                    .frame(width: 40, height: 40)

                Text(expression.emoji)
                    .font(.system(size: 24))
            }

            // Tip content
            VStack(alignment: .leading, spacing: 4) {
                Text("Brock says:")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)

                Text(tip)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brockGold.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.brockGold.opacity(0.2), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tip from Brock: \(tip)")
    }
}

// MARK: - Brock Empty State

/// Empty state featuring Brock
struct BrockEmptyState: View {
    let title: String
    let message: String
    var expression: BrockExpression = .curious
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: .spacingL) {
            BrockExpressionView(expression: expression, size: 80)

            VStack(spacing: .spacingS) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack(spacing: 8) {
                        PawPrintIcon(size: 16, color: .white)
                        Text(actionTitle)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingM)
                    .background(LinearGradient.brockGolden)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.spacingXL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Fetch Animation (Pull to Refresh)

/// Brock fetching animation for pull-to-refresh
struct BrockFetchAnimation: View {
    let progress: Double // 0 to 1
    let isRefreshing: Bool

    @State private var throwAngle: Double = 0
    @State private var brockX: CGFloat = 0
    @State private var ballX: CGFloat = 0
    @State private var ballY: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Ball (snowball)
            if isRefreshing {
                Text("❄️")
                    .font(.system(size: 20))
                    .offset(x: ballX, y: ballY)
            } else {
                Text("❄️")
                    .font(.system(size: 20))
                    .opacity(progress)
                    .scaleEffect(progress)
                    .offset(y: -20 * progress)
            }

            // Brock running
            HStack(spacing: 0) {
                Text("🐕")
                    .font(.system(size: 32))
                    .scaleEffect(x: isRefreshing ? -1 : 1, y: 1)
                    .offset(x: brockX)
            }
        }
        .frame(height: 60)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue && !reduceMotion {
                startFetchAnimation()
            } else {
                resetAnimation()
            }
        }
    }

    private func startFetchAnimation() {
        // Throw ball
        withAnimation(.easeOut(duration: 0.5)) {
            ballX = 60
            ballY = -30
        }

        // Ball arc down
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            ballY = 0
        }

        // Brock chases
        withAnimation(.easeInOut(duration: 1).delay(0.3).repeatForever(autoreverses: true)) {
            brockX = 50
        }

        // Ball bounces
        withAnimation(.easeInOut(duration: 0.8).delay(1).repeatForever(autoreverses: true)) {
            ballX = 80
        }
    }

    private func resetAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            brockX = 0
            ballX = 0
            ballY = 0
        }
    }
}

// MARK: - Tail Wag Animation

/// Animated tail wag for positive feedback
struct TailWagAnimation: View {
    @State private var wagAngle: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: -8) {
            // Tail
            Text("〰️")
                .font(.system(size: 24))
                .rotationEffect(.degrees(wagAngle), anchor: .leading)
                .offset(x: -10)

            // Brock butt
            Text("🐕")
                .font(.system(size: 32))
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.2).repeatForever(autoreverses: true)) {
                wagAngle = 20
            }
        }
    }
}

// MARK: - Brock Achievement Celebration

/// Celebration animation when user achieves something
struct BrockCelebration: View {
    @Binding var isShowing: Bool
    let achievement: String

    @State private var confettiOpacity: Double = 0
    @State private var brockScale: CGFloat = 0.5
    @State private var messageOpacity: Double = 0

    var body: some View {
        if isShowing {
            ZStack {
                // Dim background
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissCelebration()
                    }

                VStack(spacing: .spacingL) {
                    // Confetti
                    ZStack {
                        ForEach(0..<12, id: \.self) { i in
                            Text(["🐾", "⭐️", "❄️", "✨"][i % 4])
                                .font(.system(size: 24))
                                .offset(
                                    x: CGFloat.random(in: -100...100),
                                    y: CGFloat.random(in: -100...50)
                                )
                                .opacity(confettiOpacity)
                        }
                    }

                    // Excited Brock
                    BrockExpressionView(expression: .proud, size: 100)
                        .scaleEffect(brockScale)

                    // Achievement text
                    VStack(spacing: 8) {
                        Text("Good Boy Moment!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)

                        Text(achievement)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)

                        BoneBadge(text: "EARNED")
                            .padding(.top, 8)
                    }
                    .opacity(messageOpacity)
                }
                .padding(.spacingXL)
            }
            .onAppear {
                HapticFeedback.success.trigger()
                animateIn()
            }
        }
    }

    private func animateIn() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            brockScale = 1.0
        }

        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            confettiOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            messageOpacity = 1.0
        }

        // Auto dismiss after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismissCelebration()
        }
    }

    private func dismissCelebration() {
        withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
        }
    }
}

// MARK: - Golden Doodle Fur Pattern

/// Subtle fur-like texture pattern
struct GoldenDoodleFurPattern: View {
    var opacity: Double = 0.05

    var body: some View {
        Canvas { context, size in
            for _ in 0..<200 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let length = CGFloat.random(in: 8...20)
                let angle = Double.random(in: -0.5...0.5)

                var path = Path()
                path.move(to: CGPoint(x: x, y: y))
                path.addQuadCurve(
                    to: CGPoint(x: x + length * CGFloat(cos(angle)), y: y + length * CGFloat(sin(angle))),
                    control: CGPoint(x: x + length/2, y: y - 5)
                )

                context.stroke(
                    path,
                    with: .color(Color.brockGold.opacity(opacity)),
                    lineWidth: 1
                )
            }
        }
    }
}

// MARK: - Brock Avatar

/// User avatar with optional Brock overlay
struct BrockAvatar: View {
    var size: CGFloat = 40
    var showBrockOverlay: Bool = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Main avatar circle
            Circle()
                .fill(LinearGradient.brockGolden)
                .frame(width: size, height: size)
                .overlay(
                    Text("🐕")
                        .font(.system(size: size * 0.5))
                )

            // Paw badge
            if showBrockOverlay {
                Circle()
                    .fill(Color.pookieCyan)
                    .frame(width: size * 0.35, height: size * 0.35)
                    .overlay(
                        PawPrintIcon(size: size * 0.2, color: .white)
                    )
                    .offset(x: size * 0.1, y: size * 0.1)
            }
        }
    }
}

// MARK: - Brock Reaction Picker

/// Picker for selecting reactions (uses paw prints instead of thumbs up)
struct BrockReactionPicker: View {
    @Binding var selectedReaction: BrockReaction?

    var body: some View {
        HStack(spacing: 16) {
            ForEach(BrockReaction.allCases, id: \.self) { reaction in
                Button {
                    HapticFeedback.selection.trigger()
                    if selectedReaction == reaction {
                        selectedReaction = nil
                    } else {
                        selectedReaction = reaction
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(reaction.emoji)
                            .font(.title2)

                        Text(reaction.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedReaction == reaction ? Color.brockGold.opacity(0.2) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

enum BrockReaction: String, CaseIterable {
    case pawsUp = "pawsUp"
    case excited = "excited"
    case snowy = "snowy"
    case love = "love"

    var emoji: String {
        switch self {
        case .pawsUp: return "🐾"
        case .excited: return "🐕"
        case .snowy: return "❄️"
        case .love: return "💛"
        }
    }

    var label: String {
        switch self {
        case .pawsUp: return "Paws up!"
        case .excited: return "Stoked!"
        case .snowy: return "Powder!"
        case .love: return "Love it!"
        }
    }
}

// MARK: - Brock Onboarding Mascot

/// Larger Brock view for onboarding screens
struct BrockOnboardingMascot: View {
    let text: String
    var expression: BrockExpression = .happy

    @State private var brockBreath: CGFloat = 1.0
    @State private var showBubble = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Warm glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.brockGold.opacity(0.4),
                                Color.brockGold.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 150
                        )
                    )
                    .frame(width: 250, height: 250)
                    .scaleEffect(brockBreath)

                // Brock with accessories
                VStack(spacing: -20) {
                    Text(expression.emoji)
                        .font(.system(size: 120))
                        .scaleEffect(brockBreath)

                    // Scarf
                    Text("🧣")
                        .font(.system(size: 40))
                        .offset(y: -105)
                }

                // Speech bubble
                if showBubble {
                    speechBubble
                        .offset(x: 90, y: -80)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            // Paw print trail below
            PawPrintTrail(count: 3, spacing: 20, size: 14)
        }
        .onAppear {
            guard !reduceMotion else {
                showBubble = true
                return
            }

            // Breathing animation
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                brockBreath = 1.05
            }

            // Show bubble
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.5)) {
                showBubble = true
            }
        }
    }

    private var speechBubble: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(text)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.15))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                )

            // Bubble tail
            BrockBubbleTail()
                .fill(.white)
                .frame(width: 16, height: 12)
                .rotationEffect(.degrees(180))
                .offset(x: 20, y: -1)
        }
    }
}

/// Simple triangle shape for Brock's speech bubbles
private struct BrockBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - View Modifiers

extension View {
    /// Adds a subtle paw print watermark
    func brockWatermark(opacity: Double = 0.03) -> some View {
        self.overlay(alignment: .bottomTrailing) {
            PawPrintIcon(size: 60, color: Color.brockGold.opacity(opacity))
                .padding(20)
        }
    }

    /// Adds golden doodle fur texture background
    func brockFurBackground(opacity: Double = 0.05) -> some View {
        self.background(GoldenDoodleFurPattern(opacity: opacity))
    }
}

// MARK: - Preview

#Preview("Brock Expressions") {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
            ForEach(BrockExpression.allCases, id: \.self) { expression in
                BrockExpressionView(expression: expression, size: 50)
            }
        }
        .padding()
    }
}

#Preview("Paw Elements") {
    VStack(spacing: 30) {
        PawPrintIcon(size: 40)
        PawPrintTrail()
        PawPrintDivider()
        BoneBadge(text: "GOOD BOY")
    }
    .padding()
}

#Preview("Brock Tip") {
    VStack(spacing: 20) {
        BrockTip(tip: "Check the powder score before planning your trip!")
        BrockTip(tip: "Add mountains to your favorites for quick access.", expression: .excited)
    }
    .padding()
}

#Preview("Brock Empty State") {
    BrockEmptyState(
        title: "No Favorites Yet",
        message: "Brock wants to help you track your favorite mountains!",
        expression: .curious,
        actionTitle: "Find Mountains",
        action: {}
    )
}

#Preview("Brock Avatar") {
    HStack(spacing: 20) {
        BrockAvatar(size: 40)
        BrockAvatar(size: 60)
        BrockAvatar(size: 80, showBrockOverlay: false)
    }
}

#Preview("Brock Reactions") {
    BrockReactionPicker(selectedReaction: .constant(.pawsUp))
        .padding()
}

#Preview("Brock Onboarding") {
    BrockOnboardingMascot(text: "Let's find some powder!", expression: .powderDay)
}
