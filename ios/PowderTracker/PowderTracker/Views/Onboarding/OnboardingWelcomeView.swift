//
//  OnboardingWelcomeView.swift
//  PowderTracker
//
//  Welcome screen for the onboarding flow.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: .spacingXL) {
            Spacer()

            // App icon/logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: .blue.opacity(0.4), radius: 20, y: 10)

                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white)
                    .symbolEffect(.pulse, options: .repeating, value: isAnimating)
            }
            .scaleEffect(isAnimating ? 1.0 : 0.8)
            .opacity(isAnimating ? 1.0 : 0)

            // Welcome text
            VStack(spacing: .spacingM) {
                Text("Welcome to")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text("Shredders")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                Text("Your ski trip planning companion")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(isAnimating ? 1.0 : 0)
            .offset(y: isAnimating ? 0 : 20)

            Spacer()

            // Feature highlights
            VStack(spacing: .spacingL) {
                OnboardingFeatureRow(
                    icon: "snow",
                    title: "Real-time Conditions",
                    description: "Powder alerts & mountain updates"
                )

                OnboardingFeatureRow(
                    icon: "person.3.fill",
                    title: "Plan with Friends",
                    description: "Coordinate trips & carpools"
                )

                OnboardingFeatureRow(
                    icon: "map.fill",
                    title: "Discover Mountains",
                    description: "Find your next adventure"
                )
            }
            .padding(.horizontal, .spacingL)
            .opacity(isAnimating ? 1.0 : 0)
            .offset(y: isAnimating ? 0 : 30)

            Spacer()

            // Get started button
            Button {
                onContinue()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(.cornerRadiusButton)
            }
            .padding(.horizontal, .spacingL)
            .padding(.bottom, .spacingXL)
            .opacity(isAnimating ? 1.0 : 0)
            .offset(y: isAnimating ? 0 : 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Feature Row

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(.cornerRadiusSmall)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
}
