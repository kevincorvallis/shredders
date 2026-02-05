//
//  BrockStoryOnboardingView.swift
//  PowderTracker
//
//  A production-level onboarding experience following Apple Human Interface Guidelines.
//  Features Brock as a subtle mascot while maintaining Apple's design language.
//
//  Design principles:
//  - Apple HIG compliant (brief, skippable, action-focused)
//  - Liquid Glass materials and system colors
//  - SF Symbols with hierarchical rendering
//  - Spring animations with proper timing
//  - Full accessibility support
//

import SwiftUI

// MARK: - Onboarding Feature Model

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let description: String
}

// MARK: - Main Onboarding View

struct BrockStoryOnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentPage = 0
    @State private var hasAppeared = false

    private let features: [OnboardingFeature] = [
        OnboardingFeature(
            icon: "snowflake",
            color: .cyan,
            title: "Real-Time Conditions",
            description: "Track powder depth, weather, and lift status at mountains across the region."
        ),
        OnboardingFeature(
            icon: "person.2.fill",
            color: .purple,
            title: "Plan Together",
            description: "Coordinate ski days with friends, organize carpools, and share the stoke."
        ),
        OnboardingFeature(
            icon: "bell.badge.fill",
            color: .orange,
            title: "Powder Alerts",
            description: "Get notified when fresh snow hits your favorite mountains."
        )
    ]

    // Total pages: Welcome + Features + Final
    private var totalPages: Int { features.count + 2 }

    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Content pages
                TabView(selection: $currentPage) {
                    // Welcome page
                    WelcomePageView()
                        .tag(0)

                    // Feature pages
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        FeaturePageView(feature: feature, isVisible: currentPage == index + 1)
                            .tag(index + 1)
                    }

                    // Final page with Brock
                    FinalPageView()
                        .tag(totalPages - 1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.85), value: currentPage)

                // Bottom section
                bottomSection
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                hasAppeared = true
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color(white: 0.08), Color(white: 0.12)]
                : [Color(white: 0.96), Color(white: 0.92)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 20) {
            // Page indicator
            pageIndicator

            // Action button
            actionButton
                .padding(.horizontal, 24)

            // Skip option (hide on last page with opacity to prevent layout shift)
            Button {
                HapticFeedback.light.trigger()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    currentPage = totalPages - 1
                }
            } label: {
                Text("Skip")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .opacity(currentPage < totalPages - 1 ? 1 : 0)
            .allowsHitTesting(currentPage < totalPages - 1)
            .padding(.bottom, 8)
            .animation(.smooth(duration: 0.2), value: currentPage)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(reduceMotion ? .none : .spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
    }

    // MARK: - Action Button

    private var actionButton: some View {
        let isLastPage = currentPage == totalPages - 1

        return Button {
            HapticFeedback.medium.trigger()

            if isLastPage {
                onComplete()
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    currentPage += 1
                }
            }
        } label: {
            Text(isLastPage ? "Get Started" : "Continue")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(isLastPage ? AnyShapeStyle(.orange.gradient) : AnyShapeStyle(.blue.gradient))
                )
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }
}

// MARK: - Welcome Page

private struct WelcomePageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @State private var brockScale: CGFloat = 0.8
    @State private var brockRotation: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App icon with Brock
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.2),
                                Color.orange.opacity(0.05),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Brock mascot
                Text("🐕")
                    .font(.system(size: 80))
                    .scaleEffect(brockScale)
                    .rotationEffect(.degrees(brockRotation))
            }
            .padding(.bottom, 32)

            // Welcome text
            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("PookieBSnow")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Your powder day companion")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
            .multilineTextAlignment(.center)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                brockScale = 1.0
                return
            }

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                hasAppeared = true
                brockScale = 1.0
            }

            // Subtle idle animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                brockRotation = 3
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome to PookieBSnow. Your powder day companion.")
    }
}

// MARK: - Feature Page

private struct FeaturePageView: View {
    let feature: OnboardingFeature
    let isVisible: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon with glass background
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 120, height: 120)
                    .shadow(color: .black.opacity(0.1), radius: 20, y: 8)

                Image(systemName: feature.icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(feature.color.gradient)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .opacity(hasAppeared ? 1 : 0)
            .padding(.bottom, 32)

            // Title
            Text(feature.title)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .multilineTextAlignment(.center)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)
                .padding(.bottom, 12)

            // Description
            Text(feature.description)
                .font(.body)
                .foregroundStyle(contrast == .increased ? .primary : .secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 10)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
        .onChange(of: isVisible) { _, visible in
            if visible {
                animateIn()
            } else {
                hasAppeared = false
            }
        }
        .onAppear {
            if isVisible {
                animateIn()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(feature.title). \(feature.description)")
    }

    private func animateIn() {
        guard !reduceMotion else {
            hasAppeared = true
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            hasAppeared = true
        }
    }
}

// MARK: - Final Page

private struct FinalPageView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @State private var brockBounce: CGFloat = 0
    @State private var pawPrintsVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Brock with celebration
            ZStack {
                // Paw prints scattered
                ForEach(0..<5, id: \.self) { index in
                    PawPrintIcon(size: 16, color: .orange.opacity(0.3 + Double(index) * 0.1))
                        .offset(
                            x: pawPrintOffset(for: index).x,
                            y: pawPrintOffset(for: index).y
                        )
                        .opacity(pawPrintsVisible ? 1 : 0)
                        .scaleEffect(pawPrintsVisible ? 1 : 0.5)
                        .animation(
                            reduceMotion ? .none : .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.1),
                            value: pawPrintsVisible
                        )
                }

                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.orange.opacity(0.25),
                                Color.orange.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)

                // Brock excited
                VStack(spacing: -15) {
                    Text("🐕")
                        .font(.system(size: 90))
                        .offset(y: brockBounce)

                    // Scarf
                    Text("🧣")
                        .font(.system(size: 30))
                        .offset(y: -75)
                }
            }
            .padding(.bottom, 24)

            // Title
            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(.title, design: .rounded).weight(.bold))

                Text("Brock is ready to help you find\nthe best powder days.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)

            Spacer()

            // Feature summary chips
            featureSummary
                .padding(.horizontal, 24)
                .opacity(hasAppeared ? 1 : 0)

            Spacer()
        }
        .padding(.horizontal, 32)
        .onAppear {
            guard !reduceMotion else {
                hasAppeared = true
                pawPrintsVisible = true
                return
            }

            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                hasAppeared = true
                pawPrintsVisible = true
            }

            // Brock bounce animation (gentle)
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                brockBounce = -6
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("You're all set! Brock is ready to help you find the best powder days.")
    }

    private func pawPrintOffset(for index: Int) -> CGPoint {
        let offsets: [CGPoint] = [
            CGPoint(x: -80, y: -40),
            CGPoint(x: 75, y: -50),
            CGPoint(x: -60, y: 50),
            CGPoint(x: 85, y: 35),
            CGPoint(x: -90, y: 10)
        ]
        return offsets[index % offsets.count]
    }

    private var featureSummary: some View {
        HStack(spacing: 12) {
            FeatureChip(icon: "snowflake", label: "Conditions", color: .cyan)
            FeatureChip(icon: "person.2.fill", label: "Friends", color: .purple)
            FeatureChip(icon: "bell.fill", label: "Alerts", color: .orange)
        }
    }
}

// MARK: - Feature Chip

private struct FeatureChip: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// Uses PawPrintIcon from BrockThemedElements.swift

// MARK: - Preview

#Preview("Full Onboarding") {
    BrockStoryOnboardingView(onComplete: {})
}

#Preview("Welcome Page") {
    WelcomePageView()
        .background(Color(white: 0.08))
}

#Preview("Feature Page") {
    FeaturePageView(
        feature: OnboardingFeature(
            icon: "snowflake",
            color: .cyan,
            title: "Real-Time Conditions",
            description: "Track powder depth, weather, and lift status at mountains across the region."
        ),
        isVisible: true
    )
    .background(Color(white: 0.08))
}

#Preview("Final Page") {
    FinalPageView()
        .background(Color(white: 0.08))
}
