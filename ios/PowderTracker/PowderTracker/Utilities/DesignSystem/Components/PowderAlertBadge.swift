//
//  PowderAlertBadge.swift
//  PowderTracker
//
//  Badge component for powder day alerts with animated gradient
//

import SwiftUI

// MARK: - Powder Alert Badge

/// A badge component for powder day alerts with animated gradient
struct PowderAlertBadge: View {
    @State private var animateGradient = false
    let text: String

    init(_ text: String = "POWDER DAY") {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, .spacingS)
            .padding(.vertical, .spacingXS)
            .background {
                LinearGradient(
                    colors: [
                        Color(red: 0.3, green: 0.7, blue: 1.0),
                        Color(red: 0.5, green: 0.8, blue: 1.0),
                        Color(red: 0.3, green: 0.7, blue: 1.0)
                    ],
                    startPoint: animateGradient ? .leading : .trailing,
                    endPoint: animateGradient ? .trailing : .leading
                )
            }
            .clipShape(Capsule())
            .shadow(color: Color(red: 0.3, green: 0.7, blue: 1.0).opacity(0.5), radius: 4, x: 0, y: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
            }
    }
}
