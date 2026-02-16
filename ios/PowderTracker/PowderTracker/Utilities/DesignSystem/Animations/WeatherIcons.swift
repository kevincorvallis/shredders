//
//  WeatherIcons.swift
//  PowderTracker
//
//  Animated weather symbol views
//

import SwiftUI

// MARK: - Animated Weather Symbols

/// Animated snowflake icon with falling effect
struct AnimatedSnowflakeIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 24
    var color: Color = .blue

    var body: some View {
        Image(systemName: "snowflake")
            .font(.system(size: size))
            .foregroundStyle(color)
            .symbolEffect(.variableColor.iterative, options: .repeating, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Animated wind icon with blowing effect
struct AnimatedWindIcon: View {
    @State private var isAnimating = false
    @State private var offset: CGFloat = 0
    var size: CGFloat = 24
    var color: Color = .gray

    var body: some View {
        if #available(iOS 18.0, *) {
            Image(systemName: "wind")
                .font(.system(size: size))
                .foregroundStyle(color)
                .symbolEffect(.wiggle, options: .repeating.speed(0.5), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }
        } else {
            // Fallback for iOS 17
            Image(systemName: "wind")
                .font(.system(size: size))
                .foregroundStyle(color)
                .offset(x: offset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        offset = 3
                    }
                }
        }
    }
}

/// Animated sun icon with glow effect
struct AnimatedSunIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 24
    var color: Color = .yellow

    var body: some View {
        Image(systemName: "sun.max.fill")
            .font(.system(size: size))
            .foregroundStyle(color)
            .symbolEffect(.pulse.byLayer, options: .repeating.speed(0.5), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Animated cloud icon with drifting effect
struct AnimatedCloudIcon: View {
    @State private var offset: CGFloat = 0
    var size: CGFloat = 24
    var color: Color = .gray

    var body: some View {
        Image(systemName: "cloud.fill")
            .font(.system(size: size))
            .foregroundStyle(color)
            .offset(x: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    offset = 5
                }
            }
    }
}

/// Animated snow cloud icon combining snow and cloud effects
struct AnimatedSnowCloudIcon: View {
    @State private var isAnimating = false
    var size: CGFloat = 24
    var color: Color = .blue

    var body: some View {
        Image(systemName: "cloud.snow.fill")
            .font(.system(size: size))
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(color)
            .symbolEffect(.variableColor.iterative, options: .repeating, value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

/// Weather icon that selects appropriate animated icon based on conditions
struct AnimatedWeatherIcon: View {
    let condition: String
    var size: CGFloat = 24

    var body: some View {
        switch condition.lowercased() {
        case let c where c.contains("snow"):
            AnimatedSnowCloudIcon(size: size)
        case let c where c.contains("wind"):
            AnimatedWindIcon(size: size)
        case let c where c.contains("sun") || c.contains("clear"):
            AnimatedSunIcon(size: size)
        case let c where c.contains("cloud") || c.contains("overcast"):
            AnimatedCloudIcon(size: size)
        default:
            Image(systemName: "cloud.fill")
                .font(.system(size: size))
                .foregroundStyle(.secondary)
        }
    }
}

/// Animated refresh icon that rotates while loading
struct AnimatedRefreshIcon: View {
    let isLoading: Bool
    var size: CGFloat = 20
    var color: Color = .accentColor

    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: "arrow.clockwise")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isLoading) { _, newValue in
                if newValue {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.3)) {
                        rotation = 0
                    }
                }
            }
            .onAppear {
                if isLoading {
                    withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            }
    }
}

/// Refresh button with rotating animation while loading
struct RefreshButton: View {
    let isLoading: Bool
    let action: () -> Void
    var size: CGFloat = 20

    var body: some View {
        Button(action: action) {
            AnimatedRefreshIcon(isLoading: isLoading, size: size)
        }
        .disabled(isLoading)
    }
}
