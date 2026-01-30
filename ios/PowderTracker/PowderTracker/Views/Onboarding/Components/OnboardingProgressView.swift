//
//  OnboardingProgressView.swift
//  PowderTracker
//
//  Progress indicator for onboarding steps.
//

import SwiftUI

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: .spacingS) {
            ForEach(1...totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
        .accessibilityLabel("Step \(currentStep) of \(totalSteps)")
    }
}

#Preview {
    VStack(spacing: 20) {
        OnboardingProgressView(currentStep: 1, totalSteps: 3)
        OnboardingProgressView(currentStep: 2, totalSteps: 3)
        OnboardingProgressView(currentStep: 3, totalSteps: 3)
    }
    .padding()
}
