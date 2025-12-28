import SwiftUI

/// Base skeleton view with shimmer animation
struct SkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(.systemGray5),
                            Color(.systemGray6),
                            Color(.systemGray5)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white, location: 0.5),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: isAnimating ? .trailing : .leading,
                                endPoint: isAnimating ? UnitPoint(x: 2, y: 0) : UnitPoint(x: 0.5, y: 0)
                            )
                        )
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }
}

/// Rounded skeleton shape (for cards, buttons, etc.)
struct SkeletonRoundedRect: View {
    var cornerRadius: CGFloat = 8
    var height: CGFloat? = nil

    var body: some View {
        Group {
            if let height = height {
                SkeletonView()
                    .frame(height: height)
            } else {
                SkeletonView()
            }
        }
        .cornerRadius(cornerRadius)
    }
}

/// Circle skeleton (for icons, avatars)
struct SkeletonCircle: View {
    var size: CGFloat

    var body: some View {
        SkeletonView()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}

/// Text skeleton with automatic sizing
struct SkeletonText: View {
    var width: CGFloat = 100
    var height: CGFloat = 14

    var body: some View {
        SkeletonRoundedRect(cornerRadius: 4, height: height)
            .frame(width: width)
    }
}

#Preview("Skeleton Shapes") {
    VStack(spacing: 20) {
        SkeletonRoundedRect(height: 60)

        HStack {
            SkeletonCircle(size: 40)
            VStack(alignment: .leading, spacing: 8) {
                SkeletonText(width: 150, height: 16)
                SkeletonText(width: 100, height: 12)
            }
        }

        SkeletonText(width: 200)
    }
    .padding()
}
