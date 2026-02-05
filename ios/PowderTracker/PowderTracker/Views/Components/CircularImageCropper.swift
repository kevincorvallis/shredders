//
//  CircularImageCropper.swift
//  PowderTracker
//
//  Premium gesture-based circular image cropper for avatar editing.
//  Features pinch-to-zoom, pan-to-position, rotation, flip, and image adjustments.
//
//  Design principles:
//  - Smooth spring animations (.bouncy, .snappy)
//  - Haptic feedback for all interactions
//  - Glassmorphic overlay styling
//  - Accessibility support
//

import SwiftUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

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
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero

    // Transform state
    @State private var isFlippedHorizontally = false
    @State private var isFlippedVertically = false

    // Image adjustments
    @State private var brightness: Double = 0.0
    @State private var contrast: Double = 1.0
    @State private var saturation: Double = 1.0

    // UI state
    @State private var showGrid = true
    @State private var isDragging = false
    @State private var isZooming = false
    @State private var isRotating = false
    @State private var activeToolbar: ToolbarMode = .transform
    @State private var showingResetConfirmation = false

    // Configuration
    private let cropSize: CGFloat = 280
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 5.0

    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    enum ToolbarMode: String, CaseIterable {
        case transform = "Transform"
        case adjust = "Adjust"
        
        var icon: String {
            switch self {
            case .transform: return "crop.rotate"
            case .adjust: return "slider.horizontal.3"
            }
        }
    }

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
                if showGrid && (isDragging || isZooming || isRotating) {
                    gridOverlay
                }

                // Controls
                VStack(spacing: 0) {
                    // Top bar
                    topBar

                    Spacer()

                    // Zoom/Rotation indicator
                    if isZooming || isRotating {
                        indicatorView
                            .transition(.opacity.combined(with: .scale))
                    }

                    Spacer()

                    // Toolbar mode selector
                    toolbarModeSelector
                        .padding(.bottom, .spacingM)

                    // Active toolbar
                    activeToolbarView
                        .padding(.bottom, .spacingM)

                    // Bottom controls
                    bottomControls
                }
            }
        }
        .statusBarHidden()
        .confirmationDialog("Reset All Changes?", isPresented: $showingResetConfirmation) {
            Button("Reset All", role: .destructive) {
                resetAllTransforms()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Processed Image

    private var processedImage: UIImage {
        guard brightness != 0 || contrast != 1 || saturation != 1 else {
            return image
        }
        
        guard let ciImage = CIImage(image: image) else { return image }
        
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = Float(brightness)
        filter.contrast = Float(contrast)
        filter.saturation = Float(saturation)
        
        guard let outputImage = filter.outputImage else { return image }
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return image
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Image Layer

    private var imageLayer: some View {
        Image(uiImage: processedImage)
            .resizable()
            .scaledToFill()
            .scaleEffect(x: isFlippedHorizontally ? -scale : scale,
                        y: isFlippedVertically ? -scale : scale)
            .rotationEffect(rotation)
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
        SimultaneousGesture(
            SimultaneousGesture(magnificationGesture, dragGesture),
            rotationGesture
        )
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

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                withAnimation(reduceMotion ? .none : .interactiveSpring(response: 0.2)) {
                    isRotating = true
                    rotation = lastRotation + value
                }
            }
            .onEnded { _ in
                lastRotation = rotation
                withAnimation(reduceMotion ? .none : .smooth(duration: 0.2)) {
                    isRotating = false
                }
                HapticFeedback.light.trigger()
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

            Text("Edit Photo")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                showingResetConfirmation = true
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

    // MARK: - Indicator View

    private var indicatorView: some View {
        HStack(spacing: 12) {
            if isZooming {
                Label(String(format: "%.1fx", scale), systemImage: "magnifyingglass")
            }
            if isRotating {
                Label(String(format: "%.0f°", rotation.degrees), systemImage: "rotate.right")
            }
        }
        .font(.system(size: 14, weight: .semibold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
    }

    // MARK: - Toolbar Mode Selector

    private var toolbarModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(ToolbarMode.allCases, id: \.self) { mode in
                Button {
                    HapticFeedback.selection.trigger()
                    withAnimation(.smooth(duration: 0.2)) {
                        activeToolbar = mode
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 14, weight: .medium))
                        Text(mode.rawValue)
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(activeToolbar == mode ? .white : .white.opacity(0.6))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        activeToolbar == mode
                            ? AnyShapeStyle(.ultraThinMaterial)
                            : AnyShapeStyle(Color.clear)
                    )
                    .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(.black.opacity(0.3), in: Capsule())
    }

    // MARK: - Active Toolbar View

    @ViewBuilder
    private var activeToolbarView: some View {
        switch activeToolbar {
        case .transform:
            transformToolbar
        case .adjust:
            adjustToolbar
        }
    }

    // MARK: - Transform Toolbar

    private var transformToolbar: some View {
        HStack(spacing: .spacingXL) {
            // Rotate left 90°
            ToolbarButton(icon: "rotate.left", label: "90°") {
                rotate(by: -90)
            }

            // Rotate right 90°
            ToolbarButton(icon: "rotate.right", label: "90°") {
                rotate(by: 90)
            }

            // Flip horizontal
            ToolbarButton(
                icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                label: "Flip H",
                isActive: isFlippedHorizontally
            ) {
                flipHorizontally()
            }

            // Flip vertical
            ToolbarButton(
                icon: "arrow.up.and.down.righttriangle.up.righttriangle.down",
                label: "Flip V",
                isActive: isFlippedVertically
            ) {
                flipVertically()
            }

            // Grid toggle
            ToolbarButton(icon: showGrid ? "grid" : "grid.circle", label: "Grid", isActive: showGrid) {
                withAnimation(.smooth) {
                    showGrid.toggle()
                }
            }
        }
        .padding(.horizontal, .spacingL)
    }

    // MARK: - Adjust Toolbar

    private var adjustToolbar: some View {
        VStack(spacing: .spacingM) {
            // Brightness slider
            AdjustmentSlider(
                value: $brightness,
                range: -0.5...0.5,
                icon: "sun.max.fill",
                label: "Brightness"
            )

            // Contrast slider
            AdjustmentSlider(
                value: $contrast,
                range: 0.5...1.5,
                icon: "circle.lefthalf.filled",
                label: "Contrast"
            )

            // Saturation slider
            AdjustmentSlider(
                value: $saturation,
                range: 0...2,
                icon: "drop.fill",
                label: "Saturation"
            )
        }
        .padding(.horizontal, .spacingL)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: .spacingXL) {
            // Cancel button
            Button {
                HapticFeedback.light.trigger()
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: Capsule())
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
        }
        .padding(.bottom, .spacingXL)
    }

    // MARK: - Actions

    private func rotate(by degrees: Double) {
        HapticFeedback.medium.trigger()
        withAnimation(reduceMotion ? .none : .bouncy(duration: 0.4)) {
            rotation += .degrees(degrees)
            lastRotation = rotation
        }
    }

    private func flipHorizontally() {
        HapticFeedback.medium.trigger()
        withAnimation(reduceMotion ? .none : .bouncy(duration: 0.3)) {
            isFlippedHorizontally.toggle()
        }
    }

    private func flipVertically() {
        HapticFeedback.medium.trigger()
        withAnimation(reduceMotion ? .none : .bouncy(duration: 0.3)) {
            isFlippedVertically.toggle()
        }
    }

    private func resetTransform() {
        HapticFeedback.medium.trigger()
        withAnimation(reduceMotion ? .none : .bouncy(duration: 0.4)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }

    private func resetAllTransforms() {
        HapticFeedback.medium.trigger()
        withAnimation(reduceMotion ? .none : .bouncy(duration: 0.4)) {
            scale = 1.0
            lastScale = 1.0
            offset = .zero
            lastOffset = .zero
            rotation = .zero
            lastRotation = .zero
            isFlippedHorizontally = false
            isFlippedVertically = false
            brightness = 0.0
            contrast = 1.0
            saturation = 1.0
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
        // First apply all image adjustments and transformations
        let transformedImage = applyAllTransformations()
        
        // Calculate the crop region
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        // The image fills the width, calculate the visible portion
        let imageAspect = transformedImage.size.width / transformedImage.size.height
        let displayWidth = screenWidth * scale
        let displayHeight = displayWidth / imageAspect

        // Center of the crop circle in screen coordinates
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2

        // Image center with offset applied
        let imageCenterX = centerX + offset.width
        let imageCenterY = centerY + offset.height

        // Calculate the crop rectangle in image coordinates
        let scaleToImage = transformedImage.size.width / displayWidth

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
        if let croppedImage = cropToCircle(image: transformedImage, rect: cropRect) {
            onCrop(croppedImage)
        } else {
            onCrop(transformedImage) // Fallback to transformed image
        }
    }

    private func applyAllTransformations() -> UIImage {
        var resultImage = processedImage
        
        // Apply rotation
        if rotation.degrees != 0 {
            resultImage = resultImage.rotated(by: rotation.degrees) ?? resultImage
        }
        
        // Apply flips
        if isFlippedHorizontally {
            resultImage = resultImage.flippedHorizontally() ?? resultImage
        }
        
        if isFlippedVertically {
            resultImage = resultImage.flippedVertically() ?? resultImage
        }
        
        return resultImage
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

// MARK: - Toolbar Button

private struct ToolbarButton: View {
    let icon: String
    let label: String
    var isActive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(isActive ? .white : .white.opacity(0.6))
            .frame(width: 52, height: 52)
            .background(
                isActive
                    ? AnyShapeStyle(.ultraThinMaterial)
                    : AnyShapeStyle(Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Adjustment Slider

private struct AdjustmentSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: .spacingM) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    Spacer()
                    Text(String(format: "%.0f%%", normalizedValue * 100))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .monospacedDigit()
                }

                Slider(value: $value, in: range)
                    .tint(.white)
                    .onChange(of: value) { _, _ in
                        HapticFeedback.light.trigger()
                    }
            }

            Button {
                withAnimation(.smooth(duration: 0.2)) {
                    value = defaultValue
                }
                HapticFeedback.light.trigger()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(value != defaultValue ? 0.8 : 0.3))
            }
            .disabled(value == defaultValue)
        }
    }

    private var normalizedValue: Double {
        let rangeSpan = range.upperBound - range.lowerBound
        return (value - range.lowerBound) / rangeSpan
    }

    private var defaultValue: Double {
        switch label {
        case "Brightness": return 0.0
        case "Contrast": return 1.0
        case "Saturation": return 1.0
        default: return (range.lowerBound + range.upperBound) / 2
        }
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    func rotated(by degrees: Double) -> UIImage? {
        let radians = CGFloat(degrees * .pi / 180)
        
        var newSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let rotatedImage = renderer.image { context in
            // Move origin to middle
            context.cgContext.translateBy(x: newSize.width / 2, y: newSize.height / 2)
            // Rotate around middle
            context.cgContext.rotate(by: radians)
            // Draw the image centered
            draw(in: CGRect(
                x: -size.width / 2,
                y: -size.height / 2,
                width: size.width,
                height: size.height
            ))
        }
        
        return rotatedImage
    }

    func flippedHorizontally() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.translateBy(x: size.width, y: 0)
            context.cgContext.scaleBy(x: -1, y: 1)
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    func flippedVertically() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            context.cgContext.translateBy(x: 0, y: size.height)
            context.cgContext.scaleBy(x: 1, y: -1)
            draw(in: CGRect(origin: .zero, size: size))
        }
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
