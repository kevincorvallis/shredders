import SwiftUI
import NukeUI
import Nuke

/// Horizontal scroll of webcam thumbnails from favorite mountains
/// Provides quick access to live webcam feeds
struct WebcamStrip: View {
    let webcams: [(mountain: Mountain, webcam: MountainDetail.Webcam)]
    var onWebcamTap: ((Mountain, MountainDetail.Webcam) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS) {
            // Section header
            HStack {
                Text("Live Webcams")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if webcams.count > 3 {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, .spacingL)

            // Horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingM) {
                    ForEach(webcams.indices, id: \.self) { index in
                        let item = webcams[index]
                        WebcamThumbnailCard(
                            mountain: item.mountain,
                            webcam: item.webcam,
                            onTap: {
                                onWebcamTap?(item.mountain, item.webcam)
                            }
                        )
                    }
                }
                .padding(.horizontal, .spacingL)
            }
        }
    }
}

// MARK: - Webcam Thumbnail Card

struct WebcamThumbnailCard: View {
    let mountain: Mountain
    let webcam: MountainDetail.Webcam
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Webcam image
                ZStack {
                    // Placeholder or actual image
                    LazyImage(url: URL(string: webcam.url)) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else if state.error != nil {
                            webcamErrorPlaceholder
                        } else {
                            webcamPlaceholder
                        }
                    }
                    .processors([ImageProcessors.Resize(width: 160)])
                    .priority(.high)
                    .frame(width: 160, height: 100)
                    .clipped()

                    // Live indicator
                    VStack {
                        HStack {
                            Spacer()
                            liveIndicator
                                .padding(6)
                        }
                        Spacer()
                    }
                }
                .frame(width: 160, height: 100)
                .cornerRadius(.cornerRadiusCard, corners: [.topLeft, .topRight])

                // Info bar
                HStack(spacing: .spacingXS) {
                    MountainLogoView(
                        logoUrl: mountain.logo,
                        color: mountain.color,
                        size: 20
                    )

                    VStack(alignment: .leading, spacing: 1) {
                        Text(webcam.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(mountain.shortName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .padding(.horizontal, .spacingS)
                .padding(.vertical, .spacingXS)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(.cornerRadiusCard, corners: [.bottomLeft, .bottomRight])
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(.cornerRadiusCard)
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private var webcamPlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            VStack(spacing: 8) {
                ProgressView()
                Text("Loading...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var webcamErrorPlaceholder: some View {
        ZStack {
            Color(.systemGray5)
            VStack(spacing: 8) {
                Image(systemName: "video.slash.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Unavailable")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var liveIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)

            Text("LIVE")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
        )
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            WebcamStrip(
                webcams: [
                    (
                        mountain: Mountain.mock,
                        webcam: MountainDetail.Webcam(
                            id: "1",
                            name: "Base Lodge",
                            url: "https://example.com/webcam1.jpg",
                            refreshUrl: nil
                        )
                    ),
                    (
                        mountain: Mountain.mock,
                        webcam: MountainDetail.Webcam(
                            id: "2",
                            name: "Summit",
                            url: "https://example.com/webcam2.jpg",
                            refreshUrl: nil
                        )
                    ),
                    (
                        mountain: Mountain.mockMountains[1],
                        webcam: MountainDetail.Webcam(
                            id: "3",
                            name: "Mid Mountain",
                            url: "https://example.com/webcam3.jpg",
                            refreshUrl: nil
                        )
                    )
                ]
            )
        }
        .padding(.vertical)
    }
    .background(Color(.systemGroupedBackground))
}
