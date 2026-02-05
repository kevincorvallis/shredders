//
//  EnhancedRefreshControl.swift
//  PowderTracker
//
//  Enhanced pull-to-refresh with smooth animations and haptic feedback.
//

import SwiftUI

// MARK: - Refresh Control View Modifier

extension View {
    /// Adds enhanced pull-to-refresh with haptic feedback and smooth animations
    func enhancedRefreshable(
        showsIndicator: Bool = true,
        action: @escaping () async -> Void
    ) -> some View {
        self.modifier(EnhancedRefreshModifier(showsIndicator: showsIndicator, action: action))
    }
}

private struct EnhancedRefreshModifier: ViewModifier {
    let showsIndicator: Bool
    let action: () async -> Void
    
    @State private var isRefreshing = false
    
    func body(content: Content) -> some View {
        content
            .refreshable {
                // Trigger haptic on pull
                await MainActor.run {
                    HapticFeedback.medium.trigger()
                    isRefreshing = true
                }
                
                // Perform the refresh action
                await action()
                
                // Trigger haptic on complete
                await MainActor.run {
                    HapticFeedback.success.trigger()
                    isRefreshing = false
                }
            }
    }
}

// MARK: - Custom Refresh Indicator

/// A custom animated refresh indicator with ski theme
struct SkiRefreshIndicator: View {
    let isRefreshing: Bool
    let progress: Double // 0.0 to 1.0 for pull progress
    
    @State private var rotation: Double = 0
    
    private let snowflakeOpacities: [Double] = [0.3, 0.5, 0.7, 0.5, 0.3]
    
    var body: some View {
        ZStack {
            backgroundCircle
            
            if isRefreshing {
                refreshingView
            } else {
                progressView
            }
        }
        .shadow(color: Color.pookieCyan.opacity(isRefreshing ? 0.3 : 0), radius: 10)
    }
    
    private var backgroundCircle: some View {
        Circle()
            .fill(.ultraThinMaterial)
            .frame(width: 50, height: 50)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private var refreshingView: some View {
        Image(systemName: "snowflake")
            .font(.system(size: 24, weight: .medium))
            .foregroundStyle(Color.pookieCyan)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
    
    private var progressView: some View {
        ZStack {
            // Snowflake particles
            ForEach(0..<5, id: \.self) { index in
                snowflakeParticle(at: index)
            }
            
            // Center mountain icon
            Image(systemName: "mountain.2.fill")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .opacity(0.5 + progress * 0.5)
                .scaleEffect(0.8 + CGFloat(progress) * 0.2)
        }
    }
    
    private func snowflakeParticle(at index: Int) -> some View {
        let angle = Double(index) * .pi / 2.5
        let xOffset = CGFloat(cos(angle)) * 18
        let yOffset = CGFloat(sin(angle)) * 18
        
        return Image(systemName: "snowflake")
            .font(.system(size: 8))
            .foregroundStyle(Color.pookieCyan)
            .opacity(snowflakeOpacities[index] * progress)
            .offset(x: xOffset, y: yOffset)
    }
}

// MARK: - Refresh State Banner

/// A banner that shows refresh state with animation
struct RefreshStateBanner: View {
    let state: RefreshState
    
    @State private var isVisible = false
    
    enum RefreshState {
        case idle
        case refreshing
        case success(String)
        case error(String)
    }
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                EmptyView()
                
            case .refreshing:
                HStack(spacing: .spacingS) {
                    ProgressView()
                        .tint(.white)
                    Text("Updating...")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingS)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
            case .success(let message):
                HStack(spacing: .spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingS)
                .background(
                    Capsule()
                        .fill(.green.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )
                
            case .error(let message):
                HStack(spacing: .spacingS) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, .spacingL)
                .padding(.vertical, .spacingS)
                .background(
                    Capsule()
                        .fill(.red.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
        .onChange(of: state.isIdle) { _, isIdle in
            if isIdle {
                withAnimation(.easeOut(duration: 0.2)) {
                    isVisible = false
                }
            }
        }
    }
}

extension RefreshStateBanner.RefreshState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
}

// MARK: - Last Updated Indicator

/// Shows when data was last refreshed with tap-to-refresh
struct LastUpdatedIndicator: View {
    let lastUpdated: Date?
    let isRefreshing: Bool
    let onRefresh: () -> Void
    
    @State private var pulseOpacity: Double = 1.0
    
    private var timeAgoText: String {
        guard let date = lastUpdated else { return "Never" }
        
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        Button(action: onRefresh) {
            HStack(spacing: .spacingXS) {
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                
                Text("Updated \(timeAgoText)")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingXS)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
            )
            .opacity(pulseOpacity)
        }
        .buttonStyle(.plain)
        .disabled(isRefreshing)
        .onChange(of: isRefreshing) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    pulseOpacity = 0.6
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    pulseOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Refresh Indicator") {
    VStack(spacing: 40) {
        SkiRefreshIndicator(isRefreshing: false, progress: 0.5)
        SkiRefreshIndicator(isRefreshing: true, progress: 1.0)
    }
    .padding()
}

#Preview("Refresh Banners") {
    VStack(spacing: 20) {
        RefreshStateBanner(state: .refreshing)
        RefreshStateBanner(state: .success("Updated"))
        RefreshStateBanner(state: .error("Failed to update"))
    }
    .padding()
}

#Preview("Last Updated") {
    VStack(spacing: 20) {
        LastUpdatedIndicator(
            lastUpdated: Date().addingTimeInterval(-120),
            isRefreshing: false,
            onRefresh: {}
        )
        LastUpdatedIndicator(
            lastUpdated: Date().addingTimeInterval(-3600),
            isRefreshing: true,
            onRefresh: {}
        )
    }
    .padding()
}
