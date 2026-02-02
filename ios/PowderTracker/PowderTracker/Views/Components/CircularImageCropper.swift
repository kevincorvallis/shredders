//
//  CircularImageCropper.swift
//  PowderTracker
//
//  Premium gesture-based circular image cropper for avatar editing.
//  Features pinch-to-zoom, pan-to-position, and double-tap-to-reset.
//
//  Design principles:
//  - Smooth spring animations (.bouncy, .snappy)
//  - Haptic feedback for all interactions
//  - Glassmorphic overlay styling
//  - Accessibility support
//

import SwiftUI
import UIKit

// MARK: - Circular Image Cropper

struct CircularImageCropper: View {
    let image: UIImage
    let onCrop: (UIImage) -> Void
    let onCancel: () -> Void

    // Gesture state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    // UI state
    @State private var showGrid = true
    @State private var isDragging = false
    @State private var isZooming = false

    // Configuration
    private let cropSize: CGFloat = 280
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()

                // Image layer
                imageLayer
                    .frame(width: geometry.size.width, height: geometry.size.height)

                // Overlay with circular cutout
                cropOverlay

                // Grid overlay (rule of thirds)
                if showGrid && (isDragging || isZooming) {
                    gridOverlay
                }

                // Controls
                VStack {
                    // Top bar
                    topBar

                    Spacer()

                    // Zoom indicator
                    if isZooming {
                        zoomIndicator
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()

                    // Bottom controls
                    bottomControls
                }
            }
        }
        .statusBarHidden()
    }

    // MARK: - Image Layer

    private var imageLayer: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(combinedGesture)
            .onTapGesture(count: 2) {
                resetTransform()
            }
            .accessibilityLabel("Crop preview")
            .accessibilityHint("Pinch to zoom, drag to reposition, double tap to reset")
    }

    // MARK: - Gestures

    private var combinedGesture: some Gesture {
        SimultaneousGesture(magnificationGesture, dragGesture)
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                withAnimation(reduceMotion ? .none : .interactiveSpring(response: 0.2)) {
                    isZooming = true
                    let newScale = lastScale * value
                    scale = min(max(newScale, minScale), maxScale)
                }
            }
            .onEnded { _ in
                lastScale = scale
                withAnimation(reduceMotion ? .none : .smooth(duration: 0.2)) {
                    isZooming = false
                }
                HapticFeedback.light.trigger()
                constrainOffset()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation(reduceMotion ? .none : .interactiveSpring(response: 0.15)) {
                    isDragging = true
                    offset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
                withAnimation(reduceMotion ? .none : .smooth(duration: 0.2)) {
                    isDragging = false
                }
                constrainOffset()
            }
    }

    // MARK: - Crop Overlay

    private var cropOverlay: some View {
        ZStack {
            // Semi-transparent overlay
            Rectangle()
                .fill(Color.black.opacity(0.6))
                .mask(
                    Canvas { context, size in
                        // Full rectangle
                        context.fill(
                            Path(CGRect(origin: .zero, size: size)),
                            with: .color(.white)
                        )

                        // Circular cutout
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let circleRect = CGRect(
                            x: center.x - cropSize / 2,
                            y: center.y - cropSize / 2,
                            width: cropSize,
                            height: cropSize
                        )
                        context.blendMode = .destinationOut
                        context.fill(
                            Circle().path(in: circleRect),
                            with: .color(.white)
                        )
                    }
                )
                .allowsHitTesting(false)

            // Circle border with glow
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: cropSize, height: cropSize)
                .shadow(color: .white.opacity(0.3), radius: 8)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Grid Overlay

    private var gridOverlay: some View {
        ZStack {
            // Vertical lines
            ForEach(1..<3) { i in
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 0.5)
                    .offset(x: CGFloat(i) * cropSize / 3 - cropSize / 2)
            }

            // Horizontal lines
            ForEach(1..<3) { i in
                Rectangle()
                    .fill(.white.opacity(0.3))
                    .frame(height: 0.5)
                    .offset(y: CGFloat(i) * cropSize / 3 - cropSize / 2)
            }
        }
        .frame(width: cropSize, height: cropSize)
        .clipShape(Circle())
        .allowsHitTesting(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                HapticFeedback.light.trigger()
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            Text("Move and Scale")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                resetTransform()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
        .padding(.horizontal, .spacingL)
        .padding(.top, .spacingM)
    }

    // MARK: - Zoom Indicator

    private var zoomIndicator: some View {
        Text(String(format: "%.1fx", scale))
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: .spacingXL) {
            // Grid toggle
            Button {
                HapticFeedback.selection.trigger()
                withAnimation(.smooth) {
                    showGrid.toggle()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: showGrid ? "grid" : "grid.circle")
                        .font(.system(size: 24))
                    Text("Grid")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(showGrid ? 1.0 : 0.6))
            }

            // Confirm button
            Button {
                HapticFeedback.medium.trigger()
                cropImage()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text("Done")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.5, blue: 0.72),
                            Color(red: 0.5, green: 0.7, blue: 1.0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.4), radius: 12, y: 6)
            }

            // Rotate (placeholder for future)
            Button {
                // Future enhancement: rotate image
                HapticFeedback.selection.trigger()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "rotate.right")
                        .font(.system(size: 24))
                    Text("Rotate")
                        .font(.caption2)
                }
                .foregroundStyle(.white.opacity(0.6))
            }
            .disabled(true)
            .opacity(0.4)
        }
        .padding(.bottom, .spacingXL)
    }

    // MARK: - Actions

    private func resetTransform() {
        HapticFeedback.medium.trigger()
        withAnimation(reduceMotion ? .none : .bouncy(duration: 0.4)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }

    private func constrainOffset() {
        // Calculate the scaled image size
        let imageAspect = image.size.width / image.size.height
        let screenWidth = UIScreen.main.bounds.width
        let scaledWidth = screenWidth * scale
        let scaledHeight = scaledWidth / imageAspect

        // Calculate bounds
        let maxOffsetX = max(0, (scaledWidth - cropSize) / 2)
        let maxOffsetY = max(0, (scaledHeight - cropSize) / 2)

        withAnimation(reduceMotion ? .none : .snappy(duration: 0.25)) {
            offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
            offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)
            lastOffset = offset
        }
    }

    private func cropImage() {
        // Calculate the crop region
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // The image fills the width, calculate the visible portion
        let imageAspect = image.size.width / image.size.height
        let displayWidth = screenWidth * scale
        let displayHeight = displayWidth / imageAspect

        // Center of the crop circle in screen coordinates
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2

        // Image center with offset applied
        let imageCenterX = centerX + offset.width
        let imageCenterY = centerY + offset.height

        // Calculate the crop rectangle in image coordinates
        let scaleToImage = image.size.width / displayWidth

        let cropCenterXInImage = (centerX - imageCenterX + displayWidth / 2) * scaleToImage
        let cropCenterYInImage = (centerY - imageCenterY + displayHeight / 2) * scaleToImage
        let cropSizeInImage = cropSize * scaleToImage

        let cropRect = CGRect(
            x: cropCenterXInImage - cropSizeInImage / 2,
            y: cropCenterYInImage - cropSizeInImage / 2,
            width: cropSizeInImage,
            height: cropSizeInImage
        )

        // Crop and create circular image
        if let croppedImage = cropToCircle(image: image, rect: cropRect) {
            onCrop(croppedImage)
        } else {
            onCrop(image) // Fallback to original
        }
    }

    private func cropToCircle(image: UIImage, rect: CGRect) -> UIImage? {
        // Clamp the rect to image bounds
        let clampedRect = CGRect(
            x: max(0, min(rect.origin.x, image.size.width - rect.width)),
            y: max(0, min(rect.origin.y, image.size.height - rect.height)),
            width: min(rect.width, image.size.width),
            height: min(rect.height, image.size.height)
        )

        // Get the cropped portion
        guard let cgImage = image.cgImage?.cropping(to: clampedRect) else {
            return nil
        }

        let croppedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)

        // Create circular mask
        let outputSize = CGSize(width: 512, height: 512) // Standard avatar size
        let renderer = UIGraphicsImageRenderer(size: outputSize)

        let circularImage = renderer.image { context in
            // Draw circular clipping path
            let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: outputSize))
            circlePath.addClip()

            // Draw the image
            croppedImage.draw(in: CGRect(origin: .zero, size: outputSize))
        }

        return circularImage
    }
}

// MARK: - Preview

#Preview {
    CircularImageCropper(
        image: UIImage(systemName: "photo.artframe")!,
        onCrop: { _ in },
        onCancel: {}
    )
}
