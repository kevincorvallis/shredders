//
//  BrockLoadingView.swift
//  PowderTracker
//
//  A delightful loading view featuring Brock the golden doodle.
//  Use throughout the app for a consistent, playful loading experience.
//

import SwiftUI

/// Loading view featuring Brock the golden doodle
/// - Parameter message: The loading message to display (defaults to "Brock is fetching conditions...")
struct BrockLoadingView: View {
    let message: String

    @State private var rotation: Double = 0
    @State private var bounce: CGFloat = 0
    @State private var snowflakeScale: CGFloat = 1.0

    init(_ message: String = "Brock is fetching conditions...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: .spacingL) {
            ZStack {
                // Spinning snowflake background
                Image(systemName: "snowflake")
                    .font(.system(size: 70, weight: .light))
                    .foregroundStyle(Color.pookieCyan.opacity(0.25))
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(snowflakeScale)

                // Brock in the center
                Text("🐕")
                    .font(.system(size: 44))
                    .offset(y: bounce)
                    .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            }

            // Loading message
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingL)
        }
        .onAppear {
            // Snowflake rotation
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                rotation = 360
            }

            // Snowflake pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                snowflakeScale = 1.1
            }

            // Brock bounce
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                bounce = -6
            }
        }
    }
}

/// Compact loading indicator with just Brock's face
struct BrockLoadingIndicator: View {
    @State private var wiggle: Double = 0

    var body: some View {
        Text("🐕")
            .font(.system(size: 24))
            .rotationEffect(.degrees(wiggle))
            .onAppear {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    wiggle = 8
                }
            }
    }
}

/// Full-screen loading overlay with Brock
struct BrockLoadingOverlay: View {
    let message: String
    let isLoading: Bool

    init(_ message: String = "Loading...", isLoading: Bool) {
        self.message = message
        self.isLoading = isLoading
    }

    var body: some View {
        if isLoading {
            ZStack {
                // Dim background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                // Loading card
                VStack(spacing: .spacingL) {
                    BrockLoadingView(message)
                }
                .padding(.spacingXL)
                .background(.ultraThinMaterial)
                .cornerRadius(.cornerRadiusCard)
                .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            }
            .transition(.opacity)
        }
    }
}

/// View modifier for adding Brock loading overlay
struct BrockLoadingModifier: ViewModifier {
    let isLoading: Bool
    let message: String

    func body(content: Content) -> some View {
        content
            .overlay {
                BrockLoadingOverlay(message, isLoading: isLoading)
                    .animation(.easeInOut(duration: 0.3), value: isLoading)
            }
    }
}

extension View {
    /// Adds a Brock loading overlay when isLoading is true
    func brockLoading(_ isLoading: Bool, message: String = "Brock is fetching data...") -> some View {
        modifier(BrockLoadingModifier(isLoading: isLoading, message: message))
    }
}

// MARK: - Fun Loading Messages

extension String {
    /// Collection of fun Brock-themed loading messages
    static let brockLoadingMessages = [
        "Brock is sniffing out fresh powder...",
        "Fetching conditions... *wags tail*",
        "Digging through the snow data...",
        "Brock found something! Loading...",
        "Tracking fresh tracks...",
        "Sniffing the forecast...",
        "*excited barking* Loading!",
        "Brock is on the scent..."
    ]

    /// Returns a random Brock loading message
    static var randomBrockMessage: String {
        brockLoadingMessages.randomElement() ?? "Loading..."
    }
}

// MARK: - Previews

#Preview("Standard Loading") {
    BrockLoadingView()
}

#Preview("Custom Message") {
    BrockLoadingView("Sniffing out powder days...")
}

#Preview("Compact Indicator") {
    BrockLoadingIndicator()
}

#Preview("Full Overlay") {
    VStack {
        Text("Content underneath")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
    .brockLoading(true, message: "Brock is searching for mountains...")
}
