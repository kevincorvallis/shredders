//
//  OnboardingView.swift
//  PowderTracker
//
//  Onboarding flow for new users with branded design
//

import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var snowflakes: [Snowflake] = []

    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "mountain.2.fill",
            iconColor: Color(red: 0.145, green: 0.388, blue: 0.925),
            title: "Welcome to Shredders",
            description: "Your all-in-one powder tracking companion. Get real-time conditions, forecasts, and alerts for your favorite mountains.",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.118, green: 0.251, blue: 0.686),
                    Color(red: 0.145, green: 0.388, blue: 0.925)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            icon: "cloud.snow.fill",
            iconColor: Color(red: 0.0, green: 0.62, blue: 0.94),
            title: "Track Conditions",
            description: "Monitor snow depth, powder scores, lift status, and weather forecasts across 26+ mountains in the Pacific Northwest.",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.55, blue: 0.85),
                    Color(red: 0.2, green: 0.7, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            icon: "bell.badge.fill",
            iconColor: Color(red: 0.98, green: 0.71, blue: 0.0),
            title: "Get Smart Alerts",
            description: "Receive notifications when fresh powder hits your favorite mountains. Never miss an epic powder day again.",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.64, blue: 0.0),
                    Color(red: 1.0, green: 0.78, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        ),
        OnboardingPage(
            icon: "person.3.fill",
            iconColor: Color(red: 0.2, green: 0.78, blue: 0.35),
            title: "Join the Crew",
            description: "Connect with other riders, share conditions, check in at mountains, and find your next adventure buddy.",
            gradient: LinearGradient(
                colors: [
                    Color(red: 0.13, green: 0.7, blue: 0.29),
                    Color(red: 0.3, green: 0.85, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    ]

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

            // Animated snowflakes
            ForEach(snowflakes) { flake in
                Text("❄")
                    .font(.system(size: flake.size))
                    .foregroundColor(.white)
                    .opacity(flake.opacity)
                    .position(x: flake.x, y: flake.y)
            }

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        withAnimation(.easeOut(duration: 0.3)) {
                            isPresented = false
                        }
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 16)
                }

                Spacer()

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: index == currentPage ? 32 : 8, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)

                Spacer()

                // Navigation buttons
                HStack(spacing: 16) {
                    // Back button
                    if currentPage > 0 {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentPage -= 1
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.body.weight(.semibold))
                                Text("Back")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(.cornerRadiusButton)
                        }
                    }

                    Spacer()

                    // Next/Get Started button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.easeOut(duration: 0.3)) {
                                isPresented = false
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                                .fontWeight(.semibold)
                            Image(systemName: currentPage == pages.count - 1 ? "checkmark" : "chevron.right")
                                .font(.body.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.118, green: 0.251, blue: 0.686),
                                    Color(red: 0.145, green: 0.388, blue: 0.925)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(.cornerRadiusButton)
                        .shadow(color: Color(red: 0.145, green: 0.388, blue: 0.925).opacity(0.5), radius: 12, y: 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            generateSnowflakes()
        }
        .onReceive(timer) { _ in
            updateSnowflakes()
        }
    }

    private func generateSnowflakes() {
        let screenWidth = UIScreen.main.bounds.width
        snowflakes = (0..<30).map { _ in
            Snowflake(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: -100...0),
                size: CGFloat.random(in: 8...16),
                opacity: Double.random(in: 0.2...0.6),
                speed: Double.random(in: 1...2.5),
                drift: CGFloat.random(in: -0.8...0.8)
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
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = -10
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    var body: some View {
        VStack(spacing: 32) {
            // Icon with gradient background
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.iconColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                // Icon container
                Circle()
                    .fill(page.gradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: page.iconColor.opacity(0.5), radius: 20, y: 10)

                Image(systemName: page.icon)
                    .font(.system(size: 54))
                    .foregroundStyle(.white)
            }
            .scaleEffect(iconScale)
            .rotationEffect(.degrees(iconRotation))

            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .padding(.horizontal, 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconRotation = 0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let gradient: LinearGradient
}

// MARK: - Preview

#Preview {
    OnboardingView(isPresented: .constant(true))
}
