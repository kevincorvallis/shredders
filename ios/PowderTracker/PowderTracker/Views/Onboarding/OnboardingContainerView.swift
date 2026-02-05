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
    @State private var errorMessage: String?
    @State private var showError = false

    let authService: AuthService

    var body: some View {
        ZStack {
            // PookieBSnow background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.12, green: 0.18, blue: 0.3)
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
                    // Story-driven introduction with Brock
                    BrockStoryOnboardingView(onComplete: { goToNext() })
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
                        authService: authService,
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
                .animation(.spring(response: 0.3, dampingFraction: 0.85), value: currentStep)
            }

            // Loading overlay with Brock
            if isCompleting {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
                    .transition(.opacity)

                BrockLoadingView("Setting up your profile...")
                    .padding(.spacingXL)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: .cornerRadiusCard, style: .continuous))
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.smooth(duration: 0.25), value: isCompleting)
        .interactiveDismissDisabled()
        .alert("Oops!", isPresented: $showError) {
            Button("Try Again") {
                completeOnboarding()
            }
            Button("Skip for Now", role: .cancel) {
                skipOnboarding()
            }
        } message: {
            Text(errorMessage ?? "Something went wrong. Please try again.")
        }
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
                #if DEBUG
                print("📝 Starting onboarding completion...")
                print("   currentUser: \(authService.currentUser != nil ? "exists (\(authService.currentUser!.id))" : "nil")")
                print("   userProfile: \(authService.userProfile != nil ? "exists" : "nil")")
                print("   Profile data: displayName=\(profile.displayName ?? "nil")")
                #endif

                // Save profile data
                try await authService.updateOnboardingProfile(profile)

                #if DEBUG
                print("✅ Profile data saved, marking onboarding complete...")
                #endif

                // Mark as complete
                try await authService.completeOnboarding()

                #if DEBUG
                print("✅ Onboarding marked complete!")
                #endif

                HapticFeedback.success.trigger()

                await MainActor.run {
                    isCompleting = false
                    dismiss()
                }
            } catch {
                #if DEBUG
                print("❌ Onboarding completion failed: \(error)")
                print("   Error type: \(type(of: error))")
                if let nsError = error as NSError? {
                    print("   Domain: \(nsError.domain), Code: \(nsError.code)")
                    print("   User Info: \(nsError.userInfo)")
                }
                #endif

                await MainActor.run {
                    isCompleting = false

                    // Parse error for user-friendly message
                    let errorDesc = error.localizedDescription.lowercased()
                    if errorDesc.contains("network") || errorDesc.contains("connection") || errorDesc.contains("timeout") {
                        errorMessage = "Network connection issue. Please check your internet and try again."
                    } else if errorDesc.contains("no user") || errorDesc.contains("not logged in") {
                        errorMessage = "Session expired. Please sign in again."
                    } else {
                        #if DEBUG
                        errorMessage = "Error: \(error.localizedDescription)"
                        #else
                        errorMessage = "We couldn't save your profile. Please check your connection and try again."
                        #endif
                    }
                    showError = true
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
