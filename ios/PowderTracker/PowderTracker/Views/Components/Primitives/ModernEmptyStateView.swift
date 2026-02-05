//
//  ModernEmptyStateView.swift
//  PowderTracker
//
//  Modern empty state component with illustrations and glass design.
//

import SwiftUI

/// Modern illustrated empty state with glassmorphic design
struct ModernEmptyStateView<Action: View>: View {
    let style: EmptyStateStyle
    let title: String
    let message: String
    @ViewBuilder let action: () -> Action
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isAnimating = false
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    
    init(
        style: EmptyStateStyle,
        title: String,
        message: String,
        @ViewBuilder action: @escaping () -> Action = { EmptyView() }
    ) {
        self.style = style
        self.title = title
        self.message = message
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: .spacingXL) {
            // Animated illustration
            illustrationView
                .scaleEffect(iconScale)
                .opacity(iconOpacity)
            
            // Text content
            VStack(spacing: .spacingS) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(contentOpacity)
            
            // Action button
            action()
                .opacity(contentOpacity)
        }
        .padding(.spacingXL)
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                contentOpacity = 1.0
            }
            
            // Start continuous animation for certain styles
            if style.hasIdleAnimation {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    @ViewBuilder
    private var illustrationView: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [style.primaryColor.opacity(0.3), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .blur(radius: 20)
                .offset(y: isAnimating ? -5 : 5)
            
            // Glass circle background
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 120, height: 120)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            // Icon with style-specific design
            style.iconView
                .offset(y: isAnimating ? -3 : 3)
        }
    }
}

// MARK: - Empty State Styles

enum EmptyStateStyle {
    case noFavorites
    case noEvents
    case noResults
    case noMountains
    case noPhotos
    case noNotifications
    case offline
    case error
    case brockHappy
    case brockSleepy
    case brockExcited
    case custom(icon: String, color: Color, secondaryIcon: String?)
    
    var primaryColor: Color {
        switch self {
        case .noFavorites: return .yellow
        case .noEvents: return .pookiePurple
        case .noResults: return .gray
        case .noMountains: return .pookieCyan
        case .noPhotos: return .orange
        case .noNotifications: return .red
        case .offline: return .gray
        case .error: return .red
        case .brockHappy, .brockSleepy, .brockExcited: return .brockGold
        case .custom(_, let color, _): return color
        }
    }
    
    var hasIdleAnimation: Bool {
        switch self {
        case .offline, .error: return false
        case .brockHappy, .brockSleepy, .brockExcited: return true
        default: return true
        }
    }
    
    @ViewBuilder
    var iconView: some View {
        switch self {
        case .noFavorites:
            ZStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .offset(x: 20, y: -20)
                    .background(
                        Circle()
                            .fill(Color.pookieCyan)
                            .frame(width: 24, height: 24)
                    )
            }
            
        case .noEvents:
            ZStack {
                Image(systemName: "calendar")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pookieCyan, .pookiePurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Image(systemName: "snowflake")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .offset(y: 4)
            }
            
        case .noResults:
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            
        case .noMountains:
            ZStack {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.pookieCyan, .blue],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                // Snow cap effect
                Image(systemName: "cloud.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(y: -20)
            }
            
        case .noPhotos:
            ZStack {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
        case .noNotifications:
            ZStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
                Image(systemName: "zzz")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.secondary)
                    .offset(x: 20, y: -18)
            }
            
        case .offline:
            ZStack {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 44))
                    .foregroundStyle(.secondary)
            }
            
        case .error:
            ZStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
        case .custom(let icon, let color, let secondaryIcon):
            ZStack {
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                if let secondary = secondaryIcon {
                    Image(systemName: secondary)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: 20, y: -18)
                }
            }

        case .brockHappy:
            ZStack {
                // Golden glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brockGold.opacity(0.4), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                Text("🐕")
                    .font(.system(size: 50))
                Text("✨")
                    .font(.system(size: 18))
                    .offset(x: 28, y: -22)
            }

        case .brockSleepy:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brockGold.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                Text("🐕")
                    .font(.system(size: 50))
                Text("💤")
                    .font(.system(size: 18))
                    .offset(x: 28, y: -22)
            }

        case .brockExcited:
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.brockGold.opacity(0.5), .clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                Text("🐕")
                    .font(.system(size: 50))
                Text("❄️")
                    .font(.system(size: 18))
                    .offset(x: 28, y: -22)
                // Paw prints
                PawPrintIcon(size: 12, color: .brockGold.opacity(0.5))
                    .offset(x: -35, y: 25)
                PawPrintIcon(size: 10, color: .brockGold.opacity(0.4))
                    .offset(x: -25, y: 35)
            }
        }
    }
}

// MARK: - Modern Empty State Button

struct ModernEmptyStateButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingS) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, .spacingL)
            .padding(.vertical, .spacingM)
            .background(
                LinearGradient(
                    colors: [.pookieCyan, .pookiePurple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusButton))
            .shadow(color: .pookieCyan.opacity(0.3), radius: 10, y: 5)
        }
    }
}

// MARK: - Preview

#Preview("No Favorites") {
    ModernEmptyStateView(
        style: .noFavorites,
        title: "No Favorites Yet",
        message: "Add your favorite mountains to quickly track conditions and snowfall forecasts."
    ) {
        ModernEmptyStateButton(title: "Browse Mountains", icon: "mountain.2.fill") {}
    }
}

#Preview("No Events") {
    ModernEmptyStateView(
        style: .noEvents,
        title: "No Upcoming Events",
        message: "Create or join ski trips with friends to coordinate your powder days."
    ) {
        ModernEmptyStateButton(title: "Create Event", icon: "plus") {}
    }
}

#Preview("No Results") {
    ModernEmptyStateView(
        style: .noResults,
        title: "No Results Found",
        message: "Try adjusting your search or filters to find what you're looking for."
    )
}

#Preview("Offline") {
    ModernEmptyStateView(
        style: .offline,
        title: "You're Offline",
        message: "Connect to the internet to see the latest conditions and forecasts."
    ) {
        ModernEmptyStateButton(title: "Retry", icon: "arrow.clockwise") {}
    }
}
