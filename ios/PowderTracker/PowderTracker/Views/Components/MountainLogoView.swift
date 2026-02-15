import SwiftUI
import Nuke
import NukeUI

struct MountainLogoView: View {
    @Environment(\.colorScheme) private var colorScheme

    let logoUrl: String?
    let color: String
    let size: CGFloat
    let style: LogoStyle

    enum LogoStyle {
        case circle      // Circular clipped (original behavior)
        case rounded     // Rounded rectangle
        case adaptive    // Smart adaptive container (recommended for dark mode)
    }

    init(logoUrl: String?, color: String, size: CGFloat = 40, style: LogoStyle = .adaptive) {
        self.logoUrl = logoUrl
        self.color = color
        self.size = size
        self.style = style
    }

    private var fullLogoUrl: URL? {
        guard let logoUrl = logoUrl, !logoUrl.isEmpty else { return nil }
        // For now, use production URL directly
        // TODO: Make this configurable via environment
        let baseUrl = "https://shredders-bay.vercel.app"
        return URL(string: "\(baseUrl)\(logoUrl)")
    }

    var body: some View {
        Group {
            if let url = fullLogoUrl {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        logoImageView(image)
                    } else if state.error != nil {
                        fallbackView
                    } else {
                        loadingView
                    }
                }
                .processors([ImageProcessors.Resize(width: size * 2)])
            } else {
                fallbackView
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Logo Display

    @ViewBuilder
    private func logoImageView(_ image: some View) -> some View {
        switch style {
        case .circle:
            circleLogoView(image)
        case .rounded:
            roundedLogoView(image)
        case .adaptive:
            adaptiveLogoView(image)
        }
    }

    // MARK: - Circle Style (Original)

    private func circleLogoView(_ image: some View) -> some View {
        image
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(borderColor, lineWidth: 0.5)
            )
    }

    // MARK: - Rounded Style

    private func roundedLogoView(_ image: some View) -> some View {
        image
            .scaledToFit()
            .padding(size * 0.15)
            .frame(width: size, height: size)
            .background(logoBackground)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.2)
                    .stroke(borderColor, lineWidth: 0.5)
            )
    }

    // MARK: - Adaptive Style (Recommended for Dark Mode)

    private func adaptiveLogoView(_ image: some View) -> some View {
        ZStack {
            // Adaptive background for contrast
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(logoBackground)

            // Logo image with proper padding
            image
                .scaledToFit()
                .padding(size * 0.15)
                .frame(width: size * 0.85, height: size * 0.85)
                // Slight brightness adjustment for dark mode visibility
                .brightness(colorScheme == .dark ? 0.05 : 0)
                .contrast(colorScheme == .dark ? 1.05 : 1.0)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.2)
                .stroke(borderColor, lineWidth: 0.5)
        )
        .shadow(
            color: shadowColor,
            radius: 2,
            x: 0,
            y: 1
        )
    }

    // MARK: - Adaptive Colors

    /// Background color that adapts to color scheme for maximum contrast
    private var logoBackground: Color {
        switch colorScheme {
        case .dark:
            // Light background in dark mode for visibility
            return Color(UIColor.systemGray5)
        case .light:
            // Very light background in light mode
            return Color(UIColor.systemGray6)
        @unknown default:
            return Color(UIColor.systemBackground)
        }
    }

    /// Border color with subtle contrast
    private var borderColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.1)
        case .light:
            return Color.black.opacity(0.05)
        @unknown default:
            return Color.secondary.opacity(0.1)
        }
    }

    /// Shadow color - only visible in light mode
    private var shadowColor: Color {
        colorScheme == .dark
            ? Color.clear
            : Color.black.opacity(0.1)
    }

    // MARK: - Loading State

    private var loadingView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color(UIColor.systemGray5))

            ProgressView()
                .scaleEffect(0.8)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Fallback View

    private var fallbackView: some View {
        ZStack {
            // Colored background using mountain's brand color
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color(hex: color) ?? .blue)

            // Initial letter
            Text(extractInitial())
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.2)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private func extractInitial() -> String {
        if let logoUrl = logoUrl,
           let filename = logoUrl.split(separator: "/").last,
           let initial = filename.split(separator: ".").first?.first {
            return String(initial).uppercased()
        }
        return "M"
    }
}

// MARK: - Previews

#Preview("Adaptive Style - Light & Dark") {
    VStack(spacing: 30) {
        Text("Adaptive Style (Recommended)")
            .font(.headline)

        HStack(spacing: 20) {
            VStack {
                MountainLogoView(
                    logoUrl: "/logos/baker.svg",
                    color: "#4A90E2",
                    size: 80,
                    style: .adaptive
                )
                Text("Large")
                    .font(.caption)
            }

            VStack {
                MountainLogoView(
                    logoUrl: "/logos/crystal.svg",
                    color: "#9B59B6",
                    size: 60,
                    style: .adaptive
                )
                Text("Medium")
                    .font(.caption)
            }

            VStack {
                MountainLogoView(
                    logoUrl: "/logos/stevens.svg",
                    color: "#E74C3C",
                    size: 40,
                    style: .adaptive
                )
                Text("Small")
                    .font(.caption)
            }
        }

        Divider()

        Text("Fallback (No URL)")
            .font(.headline)

        HStack(spacing: 20) {
            MountainLogoView(
                logoUrl: nil,
                color: "#4A90E2",
                size: 60,
                style: .adaptive
            )
            MountainLogoView(
                logoUrl: nil,
                color: "#E74C3C",
                size: 60,
                style: .adaptive
            )
            MountainLogoView(
                logoUrl: nil,
                color: "#9B59B6",
                size: 60,
                style: .adaptive
            )
        }
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}

#Preview("All Styles Comparison") {
    VStack(spacing: 30) {
        VStack {
            Text("Circle Style")
                .font(.headline)
            HStack(spacing: 20) {
                MountainLogoView(
                    logoUrl: "/logos/baker.svg",
                    color: "#4A90E2",
                    size: 60,
                    style: .circle
                )
                MountainLogoView(
                    logoUrl: nil,
                    color: "#E74C3C",
                    size: 60,
                    style: .circle
                )
            }
        }

        VStack {
            Text("Rounded Style")
                .font(.headline)
            HStack(spacing: 20) {
                MountainLogoView(
                    logoUrl: "/logos/crystal.svg",
                    color: "#9B59B6",
                    size: 60,
                    style: .rounded
                )
                MountainLogoView(
                    logoUrl: nil,
                    color: "#4A90E2",
                    size: 60,
                    style: .rounded
                )
            }
        }

        VStack {
            Text("Adaptive Style")
                .font(.headline)
            HStack(spacing: 20) {
                MountainLogoView(
                    logoUrl: "/logos/stevens.svg",
                    color: "#E74C3C",
                    size: 60,
                    style: .adaptive
                )
                MountainLogoView(
                    logoUrl: nil,
                    color: "#9B59B6",
                    size: 60,
                    style: .adaptive
                )
            }
        }
    }
    .padding()
}

#Preview("Dark Mode Test") {
    VStack(spacing: 20) {
        Text("Testing Dark Mode Visibility")
            .font(.headline)

        HStack(spacing: 20) {
            MountainLogoView(
                logoUrl: "/logos/baker.svg",
                color: "#4A90E2",
                size: 70
            )
            MountainLogoView(
                logoUrl: "/logos/crystal.svg",
                color: "#9B59B6",
                size: 70
            )
            MountainLogoView(
                logoUrl: nil,
                color: "#E74C3C",
                size: 70
            )
        }
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
