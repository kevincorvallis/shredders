//
//  OnboardingContainerView.swift
//  PowderTracker
//
//  Container view for the onboarding flow with horizontal swiping.
//

import SwiftUI

struct OnboardingContainerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep: OnboardingStep = .welcome
    @State private var profile = OnboardingProfile()
    @State private var isCompleting = false

    let authService: AuthService

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.blue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress indicator (except welcome)
                if currentStep != .welcome {
                    OnboardingProgressView(
                        currentStep: currentStep.rawValue,
                        totalSteps: OnboardingStep.allCases.count - 1 // Exclude welcome
                    )
                    .padding(.top)
                    .padding(.horizontal)
                }

                // Content
                TabView(selection: $currentStep) {
                    OnboardingWelcomeView(onContinue: { goToNext() })
                        .tag(OnboardingStep.welcome)

                    OnboardingProfileSetupView(
                        profile: $profile,
                        authService: authService,
                        onContinue: { goToNext() },
                        onSkip: { skipOnboarding() }
                    )
                    .tag(OnboardingStep.profileSetup)

                    OnboardingAboutYouView(
                        profile: $profile,
                        onContinue: { goToNext() },
                        onSkip: { skipOnboarding() }
                    )
                    .tag(OnboardingStep.aboutYou)

                    OnboardingPreferencesView(
                        profile: $profile,
                        onComplete: { completeOnboarding() },
                        onSkip: { skipOnboarding() }
                    )
                    .tag(OnboardingStep.preferences)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }

            // Loading overlay
            if isCompleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()

                VStack(spacing: .spacingM) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Setting up your profile...")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(.spacingXL)
                .background(.ultraThinMaterial)
                .cornerRadius(.cornerRadiusCard)
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Navigation

    private func goToNext() {
        withAnimation {
            switch currentStep {
            case .welcome:
                currentStep = .profileSetup
            case .profileSetup:
                currentStep = .aboutYou
            case .aboutYou:
                currentStep = .preferences
            case .preferences:
                completeOnboarding()
            }
        }
        HapticFeedback.light.trigger()
    }

    private func completeOnboarding() {
        isCompleting = true

        Task {
            do {
                // Save profile data
                try await authService.updateOnboardingProfile(profile)

                // Mark as complete
                try await authService.completeOnboarding()

                HapticFeedback.success.trigger()

                await MainActor.run {
                    isCompleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                }
                HapticFeedback.error.trigger()
            }
        }
    }

    private func skipOnboarding() {
        isCompleting = true

        Task {
            do {
                // Save any data entered so far
                try await authService.updateOnboardingProfile(profile)

                // Mark as skipped
                try await authService.skipOnboarding()

                await MainActor.run {
                    isCompleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCompleting = false
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    OnboardingContainerView(authService: AuthService.shared)
}
