import SwiftUI

/// Collapsible header with hero webcam and mountain info
/// Animates between full and collapsed states on scroll
struct CollapsibleHeaderView: View {
    let mountain: Mountain
    let webcam: MountainDetail.Webcam?
    let isCollapsed: Bool
    let fullHeight: CGFloat
    let collapsedHeight: CGFloat

    private var currentHeight: CGFloat {
        isCollapsed ? collapsedHeight : fullHeight
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background - webcam image or gradient
            backgroundLayer
                .blur(radius: isCollapsed ? 4 : 0)

            // Gradient overlay for text readability
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content overlay
            if !isCollapsed {
                expandedContent
            }

            // Sticky title that fades in when collapsed
            if isCollapsed {
                collapsedTitle
            }
        }
        .frame(height: currentHeight)
        .clipped()
        .animation(.easeOut(duration: 0.3), value: isCollapsed)
    }

    // MARK: - Collapsed Title

    private var collapsedTitle: some View {
        HStack(spacing: .spacingS) {
            MountainLogoView(
                logoUrl: mountain.logo,
                color: mountain.color,
                size: 28
            )

            Text(mountain.shortName)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            // Open/Closed indicator
            if let status = mountain.status {
                Circle()
                    .fill(status.isOpen ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.vertical, .spacingS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
        .transition(.opacity)
    }

    // MARK: - Background Layer

    @ViewBuilder
    private var backgroundLayer: some View {
        if let webcam = webcam {
            AsyncImage(url: URL(string: webcam.url)) { phase in
                switch phase {
                case .empty:
                    placeholderGradient
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderGradient
                @unknown default:
                    placeholderGradient
                }
            }
        } else {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: mountainGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var mountainGradientColors: [Color] {
        if let color = Color(hex: mountain.color) {
            return [color, color.opacity(0.7)]
        }
        return [.blue, .purple]
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            Spacer()

            // Mountain logo and name
            HStack(spacing: .spacingM) {
                MountainLogoView(
                    logoUrl: mountain.logo,
                    color: mountain.color,
                    size: 48
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(mountain.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(mountain.region.uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Status indicators
            HStack(spacing: .spacingM) {
                // Open/Closed status
                if let status = mountain.status {
                    statusBadge(
                        isOpen: status.isOpen,
                        text: status.isOpen ? "Open" : "Closed"
                    )
                }

                // Elevation
                elevationBadge

                // Webcam live indicator
                if webcam != nil {
                    liveBadge
                }
            }
        }
        .padding(.spacingL)
        .transition(.opacity)
    }

    // MARK: - Status Badges

    private func statusBadge(isOpen: Bool, text: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
    }

    private var elevationBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.up.right")
                .font(.caption)
            Text("\(mountain.elevation.summit.formatted())ft")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
    }

    private var liveBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CollapsibleHeaderView(
            mountain: Mountain.mock,
            webcam: nil,
            isCollapsed: false,
            fullHeight: 200,
            collapsedHeight: 60
        )

        Spacer()

        CollapsibleHeaderView(
            mountain: Mountain.mock,
            webcam: nil,
            isCollapsed: true,
            fullHeight: 200,
            collapsedHeight: 60
        )
    }
}
