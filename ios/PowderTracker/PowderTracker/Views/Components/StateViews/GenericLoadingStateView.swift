import SwiftUI

/// Loading state with spinner and optional skeleton placeholder
struct LoadingStateView: View {
    let message: String
    var showSkeleton: Bool = true

    var body: some View {
        VStack(spacing: .spacingL) {
            Spacer()

            // Spinner
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())

            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Skeleton placeholder
            if showSkeleton {
                skeletonPlaceholder
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var skeletonPlaceholder: some View {
        VStack(spacing: .spacingM) {
            SkeletonRect(width: nil, height: 16)
            SkeletonRect(width: 200, height: 16)
        }
        .padding(.horizontal, .spacingXL)
    }
}

/// Inline loading indicator (smaller, for cards)
struct InlineLoadingView: View {
    let message: String?

    var body: some View {
        HStack(spacing: .spacingS) {
            ProgressView()
                .scaleEffect(0.8)

            if let message = message {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Card loading state
struct CardLoadingView: View {
    let title: String?

    var body: some View {
        VStack(spacing: .spacingM) {
            if let title = title {
                Text(title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .padding(.vertical, .spacingL)
        }
        .padding(.spacingM)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(.cornerRadiusCard)
    }
}

/// Full screen loading overlay
struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String

    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                VStack(spacing: .spacingM) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))

                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.spacingXL)
                .background(Color(.systemGray))
                .cornerRadius(.cornerRadiusCard)
            }
        }
    }
}

// MARK: - Skeleton Helpers

struct SkeletonRect: View {
    let width: CGFloat?
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color(.systemGray5))
            .frame(width: width, height: height)
            .cornerRadius(.cornerRadiusTiny)
            .shimmer()
    }
}

// MARK: - Shimmer Effect

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.3),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        LoadingStateView(message: "Loading conditions...")

        InlineLoadingView(message: "Refreshing...")

        CardLoadingView(title: "Forecast")

        ZStack {
            Text("Background content")
            LoadingOverlay(isLoading: true, message: "Saving...")
        }
        .frame(height: 200)
    }
}
