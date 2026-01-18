import SwiftUI
import MapKit

// MARK: - Mountain Marker

/// Reusable map marker component for displaying mountains on a map
/// Shows powder score with color-coded circle and triangle pointer
struct MountainMarker: View {
    let mountain: Mountain
    let score: Double?
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(scoreColor)
                    .frame(width: isSelected ? 44 : 36, height: isSelected ? 44 : 36)
                    .shadow(color: isSelected ? .white.opacity(0.5) : .clear, radius: 8)

                Text(score != nil ? String(format: "%.0f", score!) : "?")
                    .font(.system(size: isSelected ? 16 : 14, weight: .bold))
                    .foregroundColor(.white)
            }

            // Triangle pointer
            Triangle()
                .fill(scoreColor)
                .frame(width: 12, height: 8)
        }
    }

    var scoreColor: Color {
        guard let score = score else {
            return Color(hex: mountain.color) ?? .gray
        }
        if score >= 7 { return .green }
        if score >= 5 { return .yellow }
        return .red
    }
}

// MARK: - Triangle Shape

/// Triangle shape used as pointer below the mountain marker circle
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#Preview {
    // Preview with mock mountain data
    let mockMountain = Mountain(
        id: "preview",
        name: "Preview Mountain",
        shortName: "Preview",
        location: MountainLocation(lat: 47.5, lng: -121.5),
        elevation: MountainElevation(base: 3000, summit: 5500),
        region: "washington",
        color: "#3b82f6",
        website: "https://example.com",
        hasSnotel: true,
        webcamCount: 3,
        logo: nil as String?,
        status: nil as MountainStatus?,
        passType: PassType.ikon
    )

    VStack(spacing: 20) {
        MountainMarker(mountain: mockMountain, score: 8.5, isSelected: false)
        MountainMarker(mountain: mockMountain, score: 5.2, isSelected: false)
        MountainMarker(mountain: mockMountain, score: 3.1, isSelected: false)
        MountainMarker(mountain: mockMountain, score: 8.5, isSelected: true)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
